import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:planticula/core/services/ai_provider_config.dart';

/// Stages of the plant identification process for UI progress feedback.
enum PlantIdStage {
  preparing('Preparando imagen...', 0.1),
  uploading('Enviando a análisis...', 0.3),
  analyzing('La IA está identificando la planta...', 0.6),
  processing('Procesando resultados...', 0.9),
  completed('¡Identificación completada!', 1.0);

  final String message;
  final double progress;

  const PlantIdStage(this.message, this.progress);
}

typedef PlantIdProgressCallback = void Function(
  PlantIdStage stage,
  String message,
  double progress,
);

/// Result returned by [PlantIdentificationStandaloneAIService.analyzeFromBytes].
class PlantIdAIResult {
  final bool isSuccessful;
  final String? errorMessage;

  final String? commonName;
  final String? scientificName;
  final String? family;
  final PlantIdCareLevel? careLevel;
  final PlantIdWateringFrequency? wateringFrequency;
  final PlantIdLightRequirement? lightRequirement;
  final PlantIdHumidityRequirement? humidityRequirement;
  final bool? toxicToPets;
  final bool? toxicToHumans;
  final double? confidenceScore;
  final String? description;
  final List<String> characteristics;
  final List<String> careTips;
  final String? analysisNotes;

  const PlantIdAIResult({
    required this.isSuccessful,
    this.errorMessage,
    this.commonName,
    this.scientificName,
    this.family,
    this.careLevel,
    this.wateringFrequency,
    this.lightRequirement,
    this.humidityRequirement,
    this.toxicToPets,
    this.toxicToHumans,
    this.confidenceScore,
    this.description,
    this.characteristics = const [],
    this.careTips = const [],
    this.analysisNotes,
  });

  const PlantIdAIResult.failure(String message)
      : isSuccessful = false,
        errorMessage = message,
        commonName = null,
        scientificName = null,
        family = null,
        careLevel = null,
        wateringFrequency = null,
        lightRequirement = null,
        humidityRequirement = null,
        toxicToPets = null,
        toxicToHumans = null,
        confidenceScore = null,
        description = null,
        characteristics = const [],
        careTips = const [],
        analysisNotes = null;
}

/// Identifies plants from photos using a configurable AI vision model.
///
/// Provider and model resolved via [AiProviderConfig.plantIdentificationV2]:
///   PLANT_ID_V2_API_KEY / PLANT_ID_V2_BASE_URL / PLANT_ID_V2_MODEL
/// Fallback to shared OPENROUTER_* keys if per-function keys are absent.
class PlantIdentificationStandaloneAIService {
  final AiProviderConfig _cfg;

  const PlantIdentificationStandaloneAIService(this._cfg);

  Future<PlantIdAIResult> analyzeFromBytes(
    Uint8List imageBytes, {
    PlantIdProgressCallback? onProgress,
  }) async {
    try {
      if (!_cfg.isFullyConfigured) {
        return _stubResult();
      }
      return await _analyzeWithOpenRouter(imageBytes, onProgress);
    } catch (e) {
      return PlantIdAIResult.failure('Error al analizar la imagen: ${e.toString()}');
    }
  }

  // ---------------------------------------------------------------------------
  // OpenRouter call
  // ---------------------------------------------------------------------------

  Future<PlantIdAIResult> _analyzeWithOpenRouter(
    Uint8List imageBytes,
    PlantIdProgressCallback? onProgress,
  ) async {
    _emit(onProgress, PlantIdStage.preparing);

    final optimized = await _optimizeImage(imageBytes);
    final base64Image = base64Encode(optimized);

    _emit(onProgress, PlantIdStage.uploading);

    final client = http.Client();
    try {
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
              {'type': 'text', 'text': _buildPrompt()},
              {
                'type': 'image_url',
                'image_url': {'url': 'data:image/jpeg;base64,$base64Image'},
              },
            ],
          },
        ],
        'max_tokens': 1000,
        'temperature': 0.2,
      });

      final startTime = DateTime.now();
      final requestFuture = request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () =>
            throw Exception('Tiempo de espera agotado. La IA está tardando demasiado.'),
      );

      Timer? heartbeat;
      if (onProgress != null) {
        heartbeat = Timer.periodic(const Duration(milliseconds: 500), (_) {
          final elapsed = DateTime.now().difference(startTime).inMilliseconds;
          final ratio = (elapsed / 15000).clamp(0.0, 1.0);
          final p = 0.35 + 0.20 * ratio;
          onProgress(
            PlantIdStage.analyzing,
            'La IA está identificando la planta${'.' * ((elapsed ~/ 1000) % 4)}',
            p,
          );
        });
      }

      final streamed = await requestFuture;
      heartbeat?.cancel();

      _emit(onProgress, PlantIdStage.processing);

      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        throw Exception('AI API error ${response.statusCode}: ${response.body}');
      }

      final json = jsonDecode(response.body);
      final content = json['choices']?[0]?['message']?['content'] as String?;
      if (content == null || content.isEmpty) {
        throw Exception('Respuesta vacía de OpenRouter');
      }

      _emit(onProgress, PlantIdStage.completed);
      return _parseResponse(content);
    } finally {
      client.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Prompt
  // ---------------------------------------------------------------------------

  String _buildPrompt() => '''
Identifica la planta de esta imagen y responde SOLO con JSON válido:

{
  "commonName": "Nombre común en español (ej: Pothos, Monstera, Cactus)",
  "scientificName": "Nombre científico (ej: Epipremnum aureum)",
  "family": "Familia botánica (ej: Araceae)",
  "careLevel": "easy|moderate|difficult|expert",
  "wateringFrequency": "veryRare|rare|moderate|frequent|veryFrequent",
  "lightRequirement": "deepShade|shade|indirectLight|brightIndirect|directLight|fullSun",
  "humidityRequirement": "veryLow|low|moderate|high|veryHigh",
  "toxicToPets": false,
  "toxicToHumans": false,
  "confidenceScore": 0.85,
  "description": "Descripción breve de la planta en 2-3 frases",
  "characteristics": ["Característica 1", "Característica 2", "Característica 3"],
  "careTips": ["Consejo de cuidado 1", "Consejo de cuidado 2"],
  "analysisNotes": "Observación general sobre la planta"
}

Instrucciones:
- careLevel: facilidad de cuidado general
- wateringFrequency: con qué frecuencia necesita riego
- lightRequirement: necesidad de luz
- humidityRequirement: necesidad de humedad ambiental
- toxicToPets / toxicToHumans: si la planta es tóxica
- confidenceScore: confianza en la identificación entre 0.0 y 1.0
- characteristics: 2-4 características visuales o botánicas destacadas
- careTips: 2-3 consejos prácticos de cuidado

Si no puedes identificar la planta, usa "Planta no identificada" en commonName y confidenceScore bajo (< 0.3).
Responde SOLO con el JSON, sin texto adicional.
'''.trim();

  // ---------------------------------------------------------------------------
  // Parse
  // ---------------------------------------------------------------------------

  PlantIdAIResult _parseResponse(String content) {
    try {
      final jsonStr = _extractJson(content);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final careLevel = _parseCareLevel(data['careLevel'] as String? ?? '');
      final wateringFrequency = _parseWateringFrequency(data['wateringFrequency'] as String? ?? '');
      final lightRequirement = _parseLightRequirement(data['lightRequirement'] as String? ?? '');
      final humidityRequirement = _parseHumidityRequirement(data['humidityRequirement'] as String? ?? '');

      final rawChars = data['characteristics'];
      final characteristics = rawChars is List
          ? rawChars.map((e) => e.toString()).toList()
          : <String>[];

      final rawTips = data['careTips'];
      final careTips = rawTips is List
          ? rawTips.map((e) => e.toString()).toList()
          : <String>[];

      return PlantIdAIResult(
        isSuccessful: true,
        commonName: data['commonName'] as String?,
        scientificName: data['scientificName'] as String?,
        family: data['family'] as String?,
        careLevel: careLevel,
        wateringFrequency: wateringFrequency,
        lightRequirement: lightRequirement,
        humidityRequirement: humidityRequirement,
        toxicToPets: data['toxicToPets'] as bool?,
        toxicToHumans: data['toxicToHumans'] as bool?,
        confidenceScore: (data['confidenceScore'] as num?)?.toDouble(),
        description: data['description'] as String?,
        characteristics: characteristics,
        careTips: careTips,
        analysisNotes: data['analysisNotes'] as String?,
      );
    } catch (e) {
      debugPrint('[PlantIdAIService] Parse error: $e\nContent: $content');
      return const PlantIdAIResult.failure('Error al procesar la respuesta de la IA');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _emit(PlantIdProgressCallback? cb, PlantIdStage stage) {
    cb?.call(stage, stage.message, stage.progress);
  }

  String _extractJson(String text) {
    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) return text.substring(start, end + 1);
    return text;
  }

  Future<Uint8List> _optimizeImage(Uint8List bytes) async {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;

      img.Image resized = decoded;
      if (decoded.width > 1024 || decoded.height > 1024) {
        resized = img.copyResize(
          decoded,
          width: decoded.width > decoded.height ? 1024 : -1,
          height: decoded.height >= decoded.width ? 1024 : -1,
        );
      }
      return Uint8List.fromList(img.encodeJpg(resized, quality: 80));
    } catch (_) {
      return bytes;
    }
  }

  // ---------------------------------------------------------------------------
  // Enum parsers
  // ---------------------------------------------------------------------------

  PlantIdCareLevel? _parseCareLevel(String s) =>
      PlantIdCareLevel.values.where((e) => e.name == s).firstOrNull;

  PlantIdWateringFrequency? _parseWateringFrequency(String s) =>
      PlantIdWateringFrequency.values.where((e) => e.name == s).firstOrNull;

  PlantIdLightRequirement? _parseLightRequirement(String s) =>
      PlantIdLightRequirement.values.where((e) => e.name == s).firstOrNull;

  PlantIdHumidityRequirement? _parseHumidityRequirement(String s) =>
      PlantIdHumidityRequirement.values.where((e) => e.name == s).firstOrNull;

  // ---------------------------------------------------------------------------
  // Stub (no API key)
  // ---------------------------------------------------------------------------

  PlantIdAIResult _stubResult() => const PlantIdAIResult(
    isSuccessful: true,
    commonName: 'Pothos dorado (demo)',
    scientificName: 'Epipremnum aureum',
    family: 'Araceae',
    careLevel: PlantIdCareLevel.easy,
    wateringFrequency: PlantIdWateringFrequency.moderate,
    lightRequirement: PlantIdLightRequirement.indirectLight,
    humidityRequirement: PlantIdHumidityRequirement.moderate,
    toxicToPets: true,
    toxicToHumans: false,
    confidenceScore: 0.92,
    description: 'Planta trepadora de interior muy popular por su resistencia y fácil cuidado. Sus hojas acorazonadas y brillantes pueden tener variaciones de color.',
    characteristics: ['Hojas acorazonadas', 'Tallos trepadores', 'Fácil propagación'],
    careTips: ['Riega cuando la tierra esté seca al tacto', 'Evita luz solar directa'],
    analysisNotes: 'Modo demostración — configura PLANT_ID_V2_API_KEY para análisis real.',
  );
}

// =============================================================================
// Enums
// =============================================================================

enum PlantIdCareLevel {
  easy('Fácil'),
  moderate('Moderado'),
  difficult('Difícil'),
  expert('Experto');

  final String displayName;
  const PlantIdCareLevel(this.displayName);
}

enum PlantIdWateringFrequency {
  veryRare('Muy raramente'),
  rare('Raramente'),
  moderate('Moderado'),
  frequent('Frecuente'),
  veryFrequent('Muy frecuente');

  final String displayName;
  const PlantIdWateringFrequency(this.displayName);
}

enum PlantIdLightRequirement {
  deepShade('Sombra profunda'),
  shade('Sombra'),
  indirectLight('Luz indirecta'),
  brightIndirect('Luz indirecta brillante'),
  directLight('Luz directa'),
  fullSun('Sol pleno');

  final String displayName;
  const PlantIdLightRequirement(this.displayName);
}

enum PlantIdHumidityRequirement {
  veryLow('Muy baja'),
  low('Baja'),
  moderate('Moderada'),
  high('Alta'),
  veryHigh('Muy alta');

  final String displayName;
  const PlantIdHumidityRequirement(this.displayName);
}
