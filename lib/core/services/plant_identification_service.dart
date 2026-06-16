import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:planticula/core/data/species/plant_species.dart';
import 'package:planticula/core/services/ai_provider_config.dart';
import 'package:planticula/core/services/species_service.dart';

/// Etapas del proceso de identificación para mostrar progreso al usuario
enum IdentificationStage {
  /// Preparando imagen (compresión/optimización)
  preparing('Preparando imagen...', 0.1),

  /// Subiendo imagen al servicio de IA
  uploading('Subiendo imagen...', 0.3),

  /// La IA está analizando la imagen
  analyzing('La IA está analizando tu planta...', 0.6),

  /// Procesando resultados de la IA
  processing('Procesando resultados...', 0.9),

  /// Identificación completada
  completed('¡Identificación completada!', 1.0);

  final String message;
  final double progress;

  const IdentificationStage(this.message, this.progress);
}

/// Callback para reportar progreso de identificación
/// [stage]: Etapa actual del proceso
/// [message]: Mensaje descriptivo para mostrar al usuario
/// [progress]: Valor entre 0.0 y 1.0 representando el progreso total
typedef ProgressCallback = void Function(
  IdentificationStage stage,
  String message,
  double progress,
);

/// Resultado de identificación de planta desde imagen
/// Incluye los datos sugeridos y nivel de confianza para cada campo
class PlantIdentificationResult {
  /// Especie identificada (puede ser null si no se pudo identificar con confianza)
  final PlantSpecies? species;

  /// Confianza en la identificación de la especie (0.0 - 1.0)
  final double speciesConfidence;

  /// Entorno sugerido (interior/exterior)
  final PlantEnvironment? suggestedEnvironment;
  final double environmentConfidence;

  /// Etapa de crecimiento sugerida
  final GrowthStage? suggestedGrowthStage;
  final double growthStageConfidence;

  /// Tamaño de maceta sugerido
  final PotSize? suggestedPotSize;
  final double potSizeConfidence;

  /// Si la identificación fue exitosa en general
  final bool isSuccessful;

  /// Mensaje de error si falló
  final String? errorMessage;

  /// URL de la imagen procesada (si se subió a algún servicio)
  final String? processedImageUrl;

  const PlantIdentificationResult({
    this.species,
    this.speciesConfidence = 0.0,
    this.suggestedEnvironment,
    this.environmentConfidence = 0.0,
    this.suggestedGrowthStage,
    this.growthStageConfidence = 0.0,
    this.suggestedPotSize,
    this.potSizeConfidence = 0.0,
    this.isSuccessful = false,
    this.errorMessage,
    this.processedImageUrl,
  });

  /// Verifica si un campo específico tiene confianza suficiente
  bool hasHighConfidence(String field) {
    switch (field) {
      case 'species':
        return speciesConfidence >= 0.7;
      case 'environment':
        return environmentConfidence >= 0.6;
      case 'growthStage':
        return growthStageConfidence >= 0.6;
      case 'potSize':
        return potSizeConfidence >= 0.6;
      default:
        return false;
    }
  }

  /// Obtiene lista de campos identificados con baja confianza (para mostrar al usuario)
  List<String> get lowConfidenceFields {
    final fields = <String>[];
    if (species != null && speciesConfidence < 0.7) fields.add('species');
    if (suggestedEnvironment != null && environmentConfidence < 0.6) {
      fields.add('environment');
    }
    if (suggestedGrowthStage != null && growthStageConfidence < 0.6) {
      fields.add('growthStage');
    }
    if (suggestedPotSize != null && potSizeConfidence < 0.6) {
      fields.add('potSize');
    }
    return fields;
  }

  PlantIdentificationResult copyWith({
    PlantSpecies? species,
    double? speciesConfidence,
    PlantEnvironment? suggestedEnvironment,
    double? environmentConfidence,
    GrowthStage? suggestedGrowthStage,
    double? growthStageConfidence,
    PotSize? suggestedPotSize,
    double? potSizeConfidence,
    bool? isSuccessful,
    String? errorMessage,
    String? processedImageUrl,
  }) {
    return PlantIdentificationResult(
      species: species ?? this.species,
      speciesConfidence: speciesConfidence ?? this.speciesConfidence,
      suggestedEnvironment: suggestedEnvironment ?? this.suggestedEnvironment,
      environmentConfidence: environmentConfidence ?? this.environmentConfidence,
      suggestedGrowthStage: suggestedGrowthStage ?? this.suggestedGrowthStage,
      growthStageConfidence: growthStageConfidence ?? this.growthStageConfidence,
      suggestedPotSize: suggestedPotSize ?? this.suggestedPotSize,
      potSizeConfidence: potSizeConfidence ?? this.potSizeConfidence,
      isSuccessful: isSuccessful ?? this.isSuccessful,
      errorMessage: errorMessage ?? this.errorMessage,
      processedImageUrl: processedImageUrl ?? this.processedImageUrl,
    );
  }
}

/// Servicio para identificar plantas desde imágenes usando OpenRouter AI
///
/// El modelo se puede configurar via OPENROUTER_MODEL en el archivo .env
/// Modelos recomendados:
/// - qwen/qwen3-vl-8b-instruct (económico, por defecto)
/// - anthropic/claude-3-haiku (más preciso)
/// - google/gemini-flash-1.5 (buen balance)
class PlantIdentificationService {
  final SpeciesService _speciesService;
  final AiProviderConfig _cfg;

  PlantIdentificationService(this._speciesService, this._cfg);

  /// Identifica una planta desde una imagen usando OpenRouter
  ///
  /// [imageFile] - Archivo de imagen de la planta
  /// [location] - Ubicación opcional para contexto (interior/exterior)
  /// [onProgress] - Callback opcional para recibir actualizaciones de progreso
  ///
  /// Retorna un [PlantIdentificationResult] con los datos sugeridos
  Future<PlantIdentificationResult> identifyFromImage(
    File imageFile, {
    PlantEnvironment? location,
    ProgressCallback? onProgress,
  }) async {
    try {
      // Fallback a simulación si la configuración está incompleta
      if (!_cfg.isFullyConfigured) {
        return await _simulateIdentification(imageFile, location, onProgress);
      }

      // Procesar con el proveedor de IA configurado
      return await _identifyWithOpenRouter(
        imageFile,
        location,
        onProgress,
      );
    } catch (e) {
      return PlantIdentificationResult(
        isSuccessful: false,
        errorMessage: 'Error al procesar la imagen: $e',
      );
    }
  }

  /// Identificación real usando OpenRouter API
  Future<PlantIdentificationResult> _identifyWithOpenRouter(
    File imageFile,
    PlantEnvironment? location,
    ProgressCallback? onProgress,
  ) async {
    // Etapa 1: Preparando imagen (compresión ligera)
    onProgress?.call(
      IdentificationStage.preparing,
      IdentificationStage.preparing.message,
      IdentificationStage.preparing.progress,
    );

    // Leer y comprimir la imagen
    final optimizedImageBytes = await _optimizeImage(imageFile);
    final mimeType = _getMimeType(imageFile.path);

    // Codificar a base64
    final base64Image = base64Encode(optimizedImageBytes);

    debugPrint('📸 Imagen optimizada: ${optimizedImageBytes.length ~/ 1024}KB '
        '(base64: ${base64Image.length ~/ 1024}KB)');

    // Etapa 2: Subiendo imagen
    onProgress?.call(
      IdentificationStage.uploading,
      IdentificationStage.uploading.message,
      IdentificationStage.uploading.progress,
    );

    // Construir el prompt
    final prompt = _buildIdentificationPrompt(location);

    // Crear cliente HTTP con timeout
    final client = http.Client();
    try {
      // Crear la petición
      // isFullyConfigured checked before this point — non-null guaranteed
      final cfg = _cfg;
      final request = http.Request(
        'POST',
        Uri.parse(cfg.chatCompletionsUrl!),
      );
      request.headers.addAll({
        'Authorization': 'Bearer ${cfg.apiKey!}',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://planticula.app',
        'X-Title': 'Planticula Plant Identification',
      });
      request.body = jsonEncode({
        'model': cfg.model!,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'text',
                'text': prompt,
              },
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:$mimeType;base64,$base64Image',
                },
              },
            ],
          },
        ],
        'max_tokens': 1000,
        'temperature': 0.3,
      });

      // Enviar petición con timeout de 60 segundos (la IA puede tardar en analizar)
      // Usar un heartbeat para actualizar progreso mientras esperamos
      final startTime = DateTime.now();
      const analysisProgressStart = 0.35; // 35%
      const analysisProgressEnd = 0.55;   // 55%

      // Crear el futuro de la petición HTTP
      final requestFuture = request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Tiempo de espera agotado. La IA está tardando demasiado.');
        },
      );

      // Heartbeat: actualiza progreso cada 500ms mientras esperamos
      Timer? heartbeatTimer;
      if (onProgress != null) {
        heartbeatTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
          final elapsed = DateTime.now().difference(startTime).inMilliseconds;
          // Simular progreso suave del 35% al 55% durante los primeros 15 segundos
          final maxElapsed = 15000; // 15 segundos
          final progressRatio = (elapsed / maxElapsed).clamp(0.0, 1.0);
          final currentProgress = analysisProgressStart +
              (analysisProgressEnd - analysisProgressStart) * progressRatio;

          onProgress(
            IdentificationStage.analyzing,
            'La IA está analizando tu planta${'.' * ((elapsed ~/ 1000) % 4)}',
            currentProgress,
          );
        });
      }

      final streamedResponse = await requestFuture;
      heartbeatTimer?.cancel();

      // Leer la respuesta completa
      final response = await http.Response.fromStream(streamedResponse);

      // Etapa 3: Procesando resultados
      onProgress?.call(
        IdentificationStage.processing,
        IdentificationStage.processing.message,
        IdentificationStage.processing.progress,
      );

      if (response.statusCode != 200) {
        throw Exception('AI API error: ${response.statusCode} - ${response.body}');
      }

      final jsonResponse = jsonDecode(response.body);
      final content = jsonResponse['choices']?[0]?['message']?['content'] as String?;

      if (content == null || content.isEmpty) {
        throw Exception('Empty response from OpenRouter');
      }

      // Etapa 4: Completado
      onProgress?.call(
        IdentificationStage.completed,
        IdentificationStage.completed.message,
        IdentificationStage.completed.progress,
      );

      // Parsear la respuesta JSON
      return _parseOpenRouterResponse(content, location);
    } finally {
      client.close();
    }
  }

  /// Optimiza la imagen para envío - compresión ligera que preserva calidad
  ///
  /// Estrategia:
  /// - Redimensiona a max 1536px (menor que 1920 para reducir tamaño)
  /// - Aplica compresión JPEG 88% (ligera reducción, imperceptible)
  /// - Mantiene calidad suficiente para identificación de plantas
  Future<Uint8List> _optimizeImage(File imageFile) async {
    try {
      // Leer imagen original
      final originalBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(originalBytes);

      if (originalImage == null) {
        // Si no se puede decodificar, usar bytes originales
        return originalBytes;
      }

      // Calcular nuevas dimensiones (max 1536px en el lado más largo)
      const maxDimension = 1536;
      int newWidth = originalImage.width;
      int newHeight = originalImage.height;

      if (newWidth > maxDimension || newHeight > maxDimension) {
        if (newWidth > newHeight) {
          newHeight = (newHeight * maxDimension ~/ newWidth);
          newWidth = maxDimension;
        } else {
          newWidth = (newWidth * maxDimension ~/ newHeight);
          newHeight = maxDimension;
        }
      }

      // Solo redimensionar si cambió el tamaño
      img.Image processedImage;
      if (newWidth != originalImage.width || newHeight != originalImage.height) {
        processedImage = img.copyResize(
          originalImage,
          width: newWidth,
          height: newHeight,
          interpolation: img.Interpolation.linear, // Buen balance calidad/velocidad
        );
      } else {
        processedImage = originalImage;
      }

      // Codificar con compresión ligera (88% = casi imperceptible)
      // Usamos JPEG para máxima compatibilidad
      final optimizedBytes = img.encodeJpg(processedImage, quality: 88);

      debugPrint('📸 Optimización: ${originalBytes.length ~/ 1024}KB → '
          '${optimizedBytes.length ~/ 1024}KB '
          '(${((optimizedBytes.length / originalBytes.length) * 100).toStringAsFixed(0)}%)');

      return Uint8List.fromList(optimizedBytes);
    } catch (e) {
      // Si falla la optimización, devolver bytes originales
      debugPrint('⚠️ Error optimizando imagen, usando original: $e');
      return await imageFile.readAsBytes();
    }
  }

  /// Construye el prompt para identificación de plantas
  /// Usa el nuevo sistema de 5 etapas de crecimiento
  String _buildIdentificationPrompt(PlantEnvironment? knownLocation) {
    return '''
Analiza esta imagen de planta y proporciona la siguiente información en formato JSON:

{
  "commonName": "Nombre común en español (ej: Helecho, Tomate, Monstera)",
  "scientificName": "Nombre científico (ej: Monstera deliciosa)",
  "environment": "indoor|outdoor",
  "growthStage": "germination|seedling|development|mature|flowering",
  "potSize": "extra_small|small|medium|large|extra_large",
  "speciesConfidence": 0.85,
  "environmentConfidence": 0.75,
  "growthStageConfidence": 0.80,
  "potSizeConfidence": 0.65,
  "reasoning": "Breve explicación de por qué identificaste esta planta así"
}

Instrucciones detalladas:
- commonName: El nombre más común en español para esta planta
- scientificName: Nombre científico/Latín si puedes identificarlo, o null si no estás seguro
- environment: "indoor" si parece planta de interior/casa, "outdoor" si parece de exterior/jardín
${knownLocation != null ? '- El usuario indica que está en ${knownLocation == PlantEnvironment.indoor ? "interior" : "exterior"}, usa esto como contexto pero verifica visualmente' : ''}

- growthStage (NUEVO SISTEMA DE 5 ETAPAS):
  "germination": Recién germinada, cotiledones visibles, sistema radicular incipiente
  "seedling": Plántula establecida, 2-6 hojas verdaderas, aún pequeña y vulnerable
  "development": Crecimiento vegetativo activo, aumentando tamaño constantemente, momento ideal para técnicas como LST/topping
  "mature": Planta alcanzó tamaño final, crecimiento lateral mínimo, estable
  "flowering": Fase reproductiva con flores o frutos visibles, o claramente en fase de floración

- potSize: Estima el tamaño de maceta basándote en la proporción planta/maceta
  - extra_small: ~5cm (semillas/plántulas)
  - small: ~10-12cm
  - medium: ~15-20cm
  - large: ~25-30cm
  - extra_large: 35cm+

- Las confianzas deben ser valores entre 0.0 y 1.0

Responde SOLO con el JSON válido, sin texto adicional.
'''.trim();
  }

  /// Parsea la respuesta de OpenRouter y busca la especie en la base de datos
  Future<PlantIdentificationResult> _parseOpenRouterResponse(
    String content,
    PlantEnvironment? location,
  ) async {
    try {
      // Extraer JSON de la respuesta (puede venir con markdown code blocks)
      final jsonStr = _extractJson(content);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      // Buscar la especie en nuestra base de datos
      final commonName = data['commonName'] as String?;
      final scientificName = data['scientificName'] as String?;

      PlantSpecies? matchedSpecies;
      double speciesConfidence = 0.0;

      // Intentar buscar por nombre común primero
      if (commonName != null && commonName.isNotEmpty) {
        final searchResults = await _speciesService.searchSpecies(commonName);

        if (searchResults.isNotEmpty) {
          matchedSpecies = searchResults.first;
          speciesConfidence = (data['speciesConfidence'] as num?)?.toDouble() ?? 0.7;
        }
      }

      // Si no encontró por nombre común, intentar por nombre científico
      if (matchedSpecies == null && scientificName != null && scientificName.isNotEmpty) {
        final searchResults = await _speciesService.searchSpecies(scientificName);

        if (searchResults.isNotEmpty) {
          matchedSpecies = searchResults.first;
          speciesConfidence = (data['speciesConfidence'] as num?)?.toDouble() ?? 0.6;
        }
      }

      // Parsear entorno
      final environmentStr = data['environment'] as String?;
      final PlantEnvironment? suggestedEnvironment =
          environmentStr != null ? _parseEnvironment(environmentStr) : location;
      final environmentConfidence =
          (data['environmentConfidence'] as num?)?.toDouble() ??
          (suggestedEnvironment != null ? 0.7 : 0.0);

      // Parsear etapa de crecimiento
      final growthStageStr = data['growthStage'] as String?;
      final GrowthStage? suggestedGrowthStage =
          growthStageStr != null ? _parseGrowthStage(growthStageStr) : null;
      final growthStageConfidence =
          (data['growthStageConfidence'] as num?)?.toDouble() ?? 0.6;

      // Parsear tamaño de maceta
      final potSizeStr = data['potSize'] as String?;
      final PotSize? suggestedPotSize =
          potSizeStr != null ? _parsePotSize(potSizeStr) : null;
      final potSizeConfidence =
          (data['potSizeConfidence'] as num?)?.toDouble() ?? 0.5;

      return PlantIdentificationResult(
        species: matchedSpecies,
        speciesConfidence: speciesConfidence,
        suggestedEnvironment: suggestedEnvironment,
        environmentConfidence: environmentConfidence,
        suggestedGrowthStage: suggestedGrowthStage ?? GrowthStage.development,
        growthStageConfidence: growthStageConfidence,
        suggestedPotSize: suggestedPotSize ?? PotSize.medium,
        potSizeConfidence: potSizeConfidence,
        isSuccessful: matchedSpecies != null,
        errorMessage:
            matchedSpecies == null ? 'No se encontró la especie "$commonName" en la base de datos' : null,
      );
    } catch (e) {
      return PlantIdentificationResult(
        isSuccessful: false,
        errorMessage: 'Error al parsear respuesta: $e',
      );
    }
  }

  /// Extrae JSON de texto (maneja markdown code blocks)
  String _extractJson(String text) {
    // Buscar JSON dentro de markdown code blocks
    final codeBlockRegex = RegExp(r'```(?:json)?\s*\n?([\s\S]*?)\n?```');
    final match = codeBlockRegex.firstMatch(text);

    if (match != null) {
      return match.group(1)?.trim() ?? text.trim();
    }

    // Si no hay code block, buscar JSON puro
    final jsonStart = text.indexOf('{');
    final jsonEnd = text.lastIndexOf('}');

    if (jsonStart >= 0 && jsonEnd > jsonStart) {
      return text.substring(jsonStart, jsonEnd + 1);
    }

    return text.trim();
  }

  /// Parsea el entorno desde string
  PlantEnvironment? _parseEnvironment(String value) {
    switch (value.toLowerCase().trim()) {
      case 'indoor':
      case 'interior':
      case 'inside':
        return PlantEnvironment.indoor;
      case 'outdoor':
      case 'exterior':
      case 'outside':
        return PlantEnvironment.outdoor;
      default:
        return null;
    }
  }

  /// Parsea la etapa de crecimiento desde string
  /// Soporta el nuevo sistema de 5 etapas + mapeo legacy
  GrowthStage? _parseGrowthStage(String value) {
    return GrowthStage.fromString(value);
  }

  /// Parsea el tamaño de maceta desde string
  PotSize? _parsePotSize(String value) {
    switch (value.toLowerCase().trim().replaceAll('_', '')) {
      case 'extrasmall':
      case 'extra_small':
      case 'xs':
        return PotSize.extraSmall;
      case 'small':
      case 's':
        return PotSize.small;
      case 'medium':
      case 'm':
        return PotSize.medium;
      case 'large':
      case 'l':
        return PotSize.large;
      case 'extralarge':
      case 'extra_large':
      case 'xl':
        return PotSize.extraLarge;
      default:
        return null;
    }
  }

  /// Determina el MIME type basado en la extensión del archivo
  String _getMimeType(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  // ==========================================================================
  // MÉTODO DE SIMULACIÓN (Fallback cuando no hay API key o para testing)
  // ==========================================================================

  /// Simula identificación para desarrollo/testing
  Future<PlantIdentificationResult> _simulateIdentification(
    File imageFile,
    PlantEnvironment? location,
    ProgressCallback? onProgress,
  ) async {
    // Simular etapas de progreso (para testing UI)
    onProgress?.call(
      IdentificationStage.preparing,
      IdentificationStage.preparing.message,
      IdentificationStage.preparing.progress,
    );
    await Future.delayed(const Duration(milliseconds: 300));

    onProgress?.call(
      IdentificationStage.uploading,
      IdentificationStage.uploading.message,
      IdentificationStage.uploading.progress,
    );
    await Future.delayed(const Duration(milliseconds: 500));

    onProgress?.call(
      IdentificationStage.analyzing,
      IdentificationStage.analyzing.message,
      IdentificationStage.analyzing.progress,
    );
    await Future.delayed(const Duration(milliseconds: 1500));

    // Obtener todas las especies disponibles
    final allSpecies = await _speciesService.searchSpecies('');

    if (allSpecies.isEmpty) {
      return const PlantIdentificationResult(
        isSuccessful: false,
        errorMessage: 'No se pudieron cargar las especies disponibles',
      );
    }

    // Simular identificación semi-aleatoria pero determinista
    final random = Random(imageFile.path.hashCode.abs());

    // Seleccionar especie aleatoria
    final speciesIndex = random.nextInt(allSpecies.length);
    final species = allSpecies[speciesIndex];

    // Simular confianza en especie (70-95%)
    final speciesConfidence = 0.7 + (random.nextDouble() * 0.25);

    // Inferir entorno basado en el parámetro o aleatorio
    final suggestedEnvironment = location ??
        (random.nextBool() ? PlantEnvironment.indoor : PlantEnvironment.outdoor);
    final environmentConfidence = 0.6 + (random.nextDouble() * 0.3);

    // Inferir etapa de crecimiento (nuevo sistema de 5 etapas)
    final growthStageProbabilities = {
      GrowthStage.germination: 0.05,   // Menos común en fotos
      GrowthStage.seedling: 0.15,       // Plántulas pequeñas
      GrowthStage.development: 0.35,    // Fase más común (ex-juvenil)
      GrowthStage.mature: 0.35,         // Plantas establecidas (ex-adulta)
      GrowthStage.flowering: 0.10,      // En floración/fructificación
    };
    final suggestedGrowthStage = _weightedRandomChoice(
      growthStageProbabilities,
      random,
    );
    final growthStageConfidence = 0.5 + (random.nextDouble() * 0.4);

    // Inferir tamaño de maceta
    final potSizeProbabilities = {
      PotSize.extraSmall: 0.1,
      PotSize.small: 0.25,
      PotSize.medium: 0.4,
      PotSize.large: 0.2,
      PotSize.extraLarge: 0.05,
    };
    final suggestedPotSize = _weightedRandomChoice(potSizeProbabilities, random);
    final potSizeConfidence = 0.55 + (random.nextDouble() * 0.35);

    onProgress?.call(
      IdentificationStage.processing,
      IdentificationStage.processing.message,
      IdentificationStage.processing.progress,
    );
    await Future.delayed(const Duration(milliseconds: 200));

    onProgress?.call(
      IdentificationStage.completed,
      IdentificationStage.completed.message,
      IdentificationStage.completed.progress,
    );

    return PlantIdentificationResult(
      species: species,
      speciesConfidence: speciesConfidence,
      suggestedEnvironment: suggestedEnvironment,
      environmentConfidence: environmentConfidence,
      suggestedGrowthStage: suggestedGrowthStage,
      growthStageConfidence: growthStageConfidence,
      suggestedPotSize: suggestedPotSize,
      potSizeConfidence: potSizeConfidence,
      isSuccessful: true,
    );
  }

  T _weightedRandomChoice<T>(Map<T, double> probabilities, Random random) {
    final total = probabilities.values.reduce((a, b) => a + b);
    var cumulative = 0.0;
    final target = random.nextDouble() * total;

    for (final entry in probabilities.entries) {
      cumulative += entry.value;
      if (cumulative >= target) return entry.key;
    }

    return probabilities.keys.first;
  }
}
