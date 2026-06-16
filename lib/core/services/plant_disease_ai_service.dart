import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:planticula/core/services/ai_provider_config.dart';
import 'package:planticula/features/plant_disease/domain/entities/plant_disease_diagnosis.dart';

/// Stages of the disease diagnosis process for UI progress feedback.
enum DiagnosisStage {
  preparing('Preparando imagen...', 0.1),
  uploading('Enviando a análisis...', 0.3),
  analyzing('La IA está diagnosticando tu planta...', 0.6),
  processing('Procesando resultados...', 0.9),
  completed('¡Diagnóstico completado!', 1.0);

  final String message;
  final double progress;

  const DiagnosisStage(this.message, this.progress);
}

typedef DiagnosisProgressCallback = void Function(
  DiagnosisStage stage,
  String message,
  double progress,
);

/// Result returned by [PlantDiseaseAIService.analyzeFromBytes].
class PlantDiseaseAIResult {
  final bool isSuccessful;
  final String? errorMessage;

  final DiagnosisType? diagnosisType;
  final String? problemName;
  final String? scientificName;
  final ProblemSeverity? severity;
  final double? confidenceScore;
  final String? description;
  final List<DiagnosisRemedy> remedies;
  final String? preventionTips;
  final String? analysisNotes;

  const PlantDiseaseAIResult({
    required this.isSuccessful,
    this.errorMessage,
    this.diagnosisType,
    this.problemName,
    this.scientificName,
    this.severity,
    this.confidenceScore,
    this.description,
    this.remedies = const [],
    this.preventionTips,
    this.analysisNotes,
  });

  const PlantDiseaseAIResult.failure(String message)
      : isSuccessful = false,
        errorMessage = message,
        diagnosisType = null,
        problemName = null,
        scientificName = null,
        severity = null,
        confidenceScore = null,
        description = null,
        remedies = const [],
        preventionTips = null,
        analysisNotes = null;
}

/// Diagnoses plant health problems (pests, diseases, deficiencies) from images
/// using a configurable AI vision model.
///
/// Provider and model are resolved via [AiProviderConfig.plantDisease]:
/// - DISEASE_AI_API_KEY / DISEASE_AI_BASE_URL / DISEASE_AI_MODEL
/// Fallback to shared OPENROUTER_* keys if per-function keys are absent.
///
/// The AI is instructed to prioritise homemade remedies over commercial products.
class PlantDiseaseAIService {
  AiProviderConfig get _cfg => AiProviderConfig.plantDisease();


  /// Analyses [imageBytes] for plant health problems.
  ///
  /// Falls back to a stub result when no API key is configured.
  Future<PlantDiseaseAIResult> analyzeFromBytes(
    Uint8List imageBytes, {
    DiagnosisProgressCallback? onProgress,
  }) async {
    try {
      if (!_cfg.hasApiKey) {
        return _stubResult();
      }
      return await _analyzeWithOpenRouter(imageBytes, onProgress);
    } catch (e) {
      return PlantDiseaseAIResult.failure(
        'Error al analizar la imagen: ${e.toString()}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // OpenRouter call
  // ---------------------------------------------------------------------------

  Future<PlantDiseaseAIResult> _analyzeWithOpenRouter(
    Uint8List imageBytes,
    DiagnosisProgressCallback? onProgress,
  ) async {
    _emit(onProgress, DiagnosisStage.preparing);

    final optimized = await _optimizeImage(imageBytes);
    final base64Image = base64Encode(optimized);

    _emit(onProgress, DiagnosisStage.uploading);

    final client = http.Client();
    try {
      final cfg = _cfg;
      final request = http.Request(
        'POST',
        Uri.parse(cfg.chatCompletionsUrl),
      );
      request.headers.addAll({
        'Authorization': 'Bearer ${cfg.apiKey}',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://planticula.app',
        'X-Title': 'Planticula Plant Disease Diagnosis',
      });
      request.body = jsonEncode({
        'model': cfg.model,
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
        'max_tokens': 1200,
        'temperature': 0.2,
      });

      final startTime = DateTime.now();
      final requestFuture = request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () =>
            throw Exception('Tiempo de espera agotado.'),
      );

      Timer? heartbeat;
      if (onProgress != null) {
        heartbeat = Timer.periodic(const Duration(milliseconds: 500), (_) {
          final elapsed = DateTime.now().difference(startTime).inMilliseconds;
          final ratio = (elapsed / 15000).clamp(0.0, 1.0);
          final p = 0.35 + 0.20 * ratio;
          onProgress(
            DiagnosisStage.analyzing,
            'La IA está diagnosticando tu planta${'.' * ((elapsed ~/ 1000) % 4)}',
            p,
          );
        });
      }

      final streamed = await requestFuture;
      heartbeat?.cancel();

      _emit(onProgress, DiagnosisStage.processing);

      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        throw Exception(
          'AI API error ${response.statusCode}: ${response.body}',
        );
      }

      final jsonResp = jsonDecode(response.body);
      final content =
          jsonResp['choices']?[0]?['message']?['content'] as String?;
      if (content == null || content.isEmpty) {
        throw Exception('Respuesta vacía de OpenRouter');
      }

      _emit(onProgress, DiagnosisStage.completed);
      return _parseResponse(content);
    } finally {
      client.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Prompt
  // ---------------------------------------------------------------------------

  String _buildPrompt() => '''
Analiza esta imagen de planta y diagnostica cualquier problema de salud visible. Responde SOLO con JSON válido:

{
  "diagnosisType": "pest|disease|deficiency|environmentalStress|healthy|unknown",
  "problemName": "Nombre del problema en español (ej: Pulgón verde, Oídio, Clorosis férrica)",
  "scientificName": "Nombre científico si aplica, o null",
  "severity": "low|medium|high|critical",
  "confidenceScore": 0.85,
  "description": "Descripción detallada del problema identificado en 2-3 frases",
  "remedies": [
    {
      "title": "Jabón potásico casero",
      "description": "Mezcla efectiva contra insectos chupadores",
      "type": "homemade",
      "ingredients": "1 litro de agua tibia, 2 cucharadas de jabón de Castilla o jabón de fregar",
      "instructions": "Mezcla bien y aplica con spray en el envés de las hojas. Repite cada 5-7 días.",
      "effectiveness": "high"
    },
    {
      "title": "Aceite de neem",
      "description": "Insecticida y fungicida natural orgánico",
      "type": "organic",
      "ingredients": null,
      "instructions": "Aplica según las instrucciones del producto. Preferiblemente al atardecer.",
      "effectiveness": "veryHigh"
    }
  ],
  "preventionTips": "Consejos para prevenir el problema en el futuro",
  "analysisNotes": "Observaciones generales sobre el estado de la planta"
}

Reglas importantes:
- diagnosisType: "pest" para insectos/ácaros, "disease" para hongos/bacterias/virus, "deficiency" para carencias de nutrientes o agua, "environmentalStress" para problemas por luz/temperatura/humedad, "healthy" si la planta está sana, "unknown" si no puedes determinar
- severity: "low" si es leve y controlable, "medium" si requiere atención, "high" si es urgente, "critical" si la planta puede morir
- remedies: SIEMPRE incluye primero remedios caseros (type: "homemade") con cosas que se tienen en casa (agua, jabón, vinagre, ajo, bicarbonato, alcohol, aceite de oliva...). Luego orgánicos y por último químicos si son necesarios. Incluye 2-4 remedios.
- Si la planta está sana (healthy), problemName = "Planta sana", severity = "low", descripción positiva, remedies = [] con tips de mantenimiento
- Responde SOLO con el JSON, sin texto adicional
'''.trim();

  // ---------------------------------------------------------------------------
  // Parse
  // ---------------------------------------------------------------------------

  PlantDiseaseAIResult _parseResponse(String content) {
    try {
      final jsonStr = _extractJson(content);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final diagnosisType = (data['diagnosisType'] as String? ?? 'unknown')
          .toDiagnosisType();
      final problemName = data['problemName'] as String?;
      final scientificName = data['scientificName'] as String?;
      final severity = (data['severity'] as String? ?? 'medium')
          .toProblemSeverity();
      final confidenceScore =
          (data['confidenceScore'] as num?)?.toDouble() ?? 0.7;
      final description = data['description'] as String?;
      final preventionTips = data['preventionTips'] as String?;
      final analysisNotes = data['analysisNotes'] as String?;

      final rawRemedies = data['remedies'];
      final remedies = <DiagnosisRemedy>[];
      if (rawRemedies is List) {
        for (final r in rawRemedies) {
          if (r is Map<String, dynamic>) {
            remedies.add(DiagnosisRemedy(
              title: r['title'] as String? ?? '',
              description: r['description'] as String? ?? '',
              type: (r['type'] as String? ?? 'homemade').toRemedyType(),
              ingredients: r['ingredients'] as String?,
              instructions: r['instructions'] as String?,
              effectiveness: (r['effectiveness'] as String? ?? 'moderate')
                  .toRemedyEffectiveness(),
            ));
          }
        }
      }

      return PlantDiseaseAIResult(
        isSuccessful: true,
        diagnosisType: diagnosisType,
        problemName: problemName ?? diagnosisType.displayName,
        scientificName: scientificName,
        severity: severity,
        confidenceScore: confidenceScore,
        description: description,
        remedies: remedies,
        preventionTips: preventionTips,
        analysisNotes: analysisNotes,
      );
    } catch (e) {
      debugPrint('⚠️ Error parsing disease diagnosis response: $e\n$content');
      return PlantDiseaseAIResult.failure(
        'No se pudo procesar la respuesta del diagnóstico',
      );
    }
  }

  String _extractJson(String text) {
    final codeBlockRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)```');
    final match = codeBlockRegex.firstMatch(text);
    if (match != null) return match.group(1)!.trim();

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end > start) return text.substring(start, end + 1);

    return text.trim();
  }

  // ---------------------------------------------------------------------------
  // Image optimisation
  // ---------------------------------------------------------------------------

  Future<Uint8List> _optimizeImage(Uint8List bytes) async {
    try {
      final decoded = img.decodeImage(bytes);
      if (decoded == null) return bytes;

      const maxDim = 1024;
      int w = decoded.width;
      int h = decoded.height;

      if (w > maxDim || h > maxDim) {
        if (w > h) {
          h = (h * maxDim ~/ w);
          w = maxDim;
        } else {
          w = (w * maxDim ~/ h);
          h = maxDim;
        }
      }

      final resized = (w != decoded.width || h != decoded.height)
          ? img.copyResize(decoded,
              width: w, height: h, interpolation: img.Interpolation.linear)
          : decoded;

      return Uint8List.fromList(img.encodeJpg(resized, quality: 82));
    } catch (_) {
      return bytes;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _emit(DiagnosisProgressCallback? cb, DiagnosisStage stage) {
    cb?.call(stage, stage.message, stage.progress);
  }

  /// Stub result for development (no API key configured).
  PlantDiseaseAIResult _stubResult() => PlantDiseaseAIResult(
        isSuccessful: true,
        diagnosisType: DiagnosisType.pest,
        problemName: 'Pulgón verde (modo demo)',
        scientificName: 'Aphis fabae',
        severity: ProblemSeverity.medium,
        confidenceScore: 0.85,
        description:
            'Se detectan colonias de pulgones en los brotes nuevos. '
            'Los pulgones chupan la savia y pueden transmitir virus. '
            'Configura OPENROUTER_API_KEY para diagnósticos reales.',
        remedies: [
          const DiagnosisRemedy(
            title: 'Spray de ajo y agua',
            description: 'Repelente natural muy eficaz contra pulgones',
            type: RemedyType.homemade,
            ingredients: '4-5 dientes de ajo, 1 litro de agua',
            instructions:
                'Hierve el ajo en el agua, deja enfriar y filtra. '
                'Aplica con spray sobre las zonas afectadas cada 3 días.',
            effectiveness: RemedyEffectiveness.high,
          ),
          const DiagnosisRemedy(
            title: 'Agua con jabón de fregar',
            description: 'Elimina los pulgones por contacto',
            type: RemedyType.homemade,
            ingredients: '1 litro de agua, 2 cucharadas de jabón neutro',
            instructions:
                'Mezcla y aplica directamente sobre los pulgones. '
                'Repite cada 5 días hasta eliminarlos.',
            effectiveness: RemedyEffectiveness.moderate,
          ),
          const DiagnosisRemedy(
            title: 'Aceite de neem',
            description: 'Insecticida orgánico de amplio espectro',
            type: RemedyType.organic,
            ingredients: null,
            instructions:
                'Dilúyelo según las instrucciones. '
                'Aplica al atardecer para evitar daños por sol.',
            effectiveness: RemedyEffectiveness.veryHigh,
          ),
        ],
        preventionTips:
            'Revisa las plantas regularmente, especialmente los brotes nuevos. '
            'Favorece la presencia de mariquitas (depredadores naturales). '
            'Evita el exceso de nitrógeno que favorece el crecimiento de pulgones.',
        analysisNotes: 'Diagnóstico simulado (modo desarrollo).',
      );
}
