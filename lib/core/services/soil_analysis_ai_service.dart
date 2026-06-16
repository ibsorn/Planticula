import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:planticula/core/services/ai_provider_config.dart';
import 'package:planticula/features/soil_analysis/domain/entities/soil_analysis.dart';

/// Stages of the soil analysis process for UI progress feedback.
enum SoilAnalysisStage {
  preparing('Preparando imagen...', 0.1),
  uploading('Enviando a análisis...', 0.3),
  analyzing('La IA está analizando el sustrato...', 0.6),
  processing('Procesando resultados...', 0.9),
  completed('¡Análisis completado!', 1.0);

  final String message;
  final double progress;

  const SoilAnalysisStage(this.message, this.progress);
}

typedef SoilAnalysisProgressCallback = void Function(
  SoilAnalysisStage stage,
  String message,
  double progress,
);

/// Result returned by [SoilAnalysisAIService.analyzeFromBytes].
class SoilAnalysisAIResult {
  final bool isSuccessful;
  final String? errorMessage;

  // Parsed fields
  final SoilType? soilType;
  final double? phLevel;
  final MoistureLevel? moistureLevel;
  final DrainageQuality? drainageQuality;
  final NutrientLevel? organicMatter;
  final List<String> recommendations;
  final String? analysisNotes;

  const SoilAnalysisAIResult({
    required this.isSuccessful,
    this.errorMessage,
    this.soilType,
    this.phLevel,
    this.moistureLevel,
    this.drainageQuality,
    this.organicMatter,
    this.recommendations = const [],
    this.analysisNotes,
  });

  const SoilAnalysisAIResult.failure(String message)
      : isSuccessful = false,
        errorMessage = message,
        soilType = null,
        phLevel = null,
        moistureLevel = null,
        drainageQuality = null,
        organicMatter = null,
        recommendations = const [],
        analysisNotes = null;
}

/// Analyses soil/substrate images using OpenRouter vision models.
///
/// Replaces the missing Supabase Edge Function with a direct client-side
/// call to OpenRouter, reusing the same API key and model configuration
/// already used by [PlantIdentificationService].
class SoilAnalysisAIService {
  final AiProviderConfig _cfg;

  const SoilAnalysisAIService(this._cfg);


  /// Analyses [imageBytes] and returns a structured [SoilAnalysisAIResult].
  ///
  /// If no API key is configured the service falls back to a stub result so
  /// the UI remains usable during development.
  Future<SoilAnalysisAIResult> analyzeFromBytes(
    Uint8List imageBytes, {
    SoilAnalysisProgressCallback? onProgress,
  }) async {
    try {
      if (!_cfg.hasApiKey) {
        return _stubResult();
      }
      return await _analyzeWithOpenRouter(imageBytes, onProgress);
    } catch (e) {
      return SoilAnalysisAIResult.failure(
        'Error al analizar la imagen: ${e.toString()}',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // OpenRouter call
  // ---------------------------------------------------------------------------

  Future<SoilAnalysisAIResult> _analyzeWithOpenRouter(
    Uint8List imageBytes,
    SoilAnalysisProgressCallback? onProgress,
  ) async {
    _emit(onProgress, SoilAnalysisStage.preparing);

    final optimized = await _optimizeImage(imageBytes);
    final base64Image = base64Encode(optimized);

    _emit(onProgress, SoilAnalysisStage.uploading);

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
        'X-Title': 'Planticula Soil Analysis',
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
        'max_tokens': 800,
        'temperature': 0.2,
      });

      final startTime = DateTime.now();
      final requestFuture = request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () =>
            throw Exception('Tiempo de espera agotado. La IA está tardando demasiado.'),
      );

      // Heartbeat progress while waiting for the AI
      Timer? heartbeat;
      if (onProgress != null) {
        heartbeat = Timer.periodic(const Duration(milliseconds: 500), (_) {
          final elapsed = DateTime.now().difference(startTime).inMilliseconds;
          final ratio = (elapsed / 15000).clamp(0.0, 1.0);
          final p = 0.35 + 0.20 * ratio;
          onProgress(
            SoilAnalysisStage.analyzing,
            'La IA está analizando el sustrato${'.' * ((elapsed ~/ 1000) % 4)}',
            p,
          );
        });
      }

      final streamed = await requestFuture;
      heartbeat?.cancel();

      _emit(onProgress, SoilAnalysisStage.processing);

      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        throw Exception(
          'AI API error ${response.statusCode}: ${response.body}',
        );
      }

      final json = jsonDecode(response.body);
      final content =
          json['choices']?[0]?['message']?['content'] as String?;
      if (content == null || content.isEmpty) {
        throw Exception('Respuesta vacía de OpenRouter');
      }

      _emit(onProgress, SoilAnalysisStage.completed);
      return _parseResponse(content);
    } finally {
      client.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Prompt
  // ---------------------------------------------------------------------------

  String _buildPrompt() => '''
Analiza esta imagen de sustrato/tierra de planta y responde SOLO con JSON válido:

{
  "soilType": "sandy|clay|silty|loamy|peaty|chalky|rocky|pottingMix|cactusMix|orchidMix|unknown",
  "phLevel": 6.5,
  "moistureLevel": "veryDry|dry|slightlyDry|optimal|moist|wet|waterlogged",
  "drainageQuality": "excellent|good|moderate|poor|veryPoor",
  "organicMatter": "veryLow|low|moderate|high|veryHigh",
  "recommendations": ["Recomendación 1", "Recomendación 2", "Recomendación 3"],
  "analysisNotes": "Notas generales sobre el estado del sustrato"
}

Instrucciones:
- soilType: tipo de sustrato visible en la imagen
- phLevel: pH estimado entre 1.0 y 14.0 basado en el color y tipo de sustrato
- moistureLevel: nivel de humedad visual (color oscuro = húmedo, claro = seco)
- drainageQuality: calidad de drenaje estimada según el tipo de sustrato
- organicMatter: cantidad de materia orgánica visible (oscuro = más materia)
- recommendations: 2-4 recomendaciones concretas para mejorar el sustrato
- analysisNotes: observación general en 1-2 frases

Si no puedes determinar un campo, usa el valor más neutro (ej: "unknown", 7.0, "optimal").
Responde SOLO con el JSON, sin texto adicional.
'''.trim();

  // ---------------------------------------------------------------------------
  // Parse
  // ---------------------------------------------------------------------------

  SoilAnalysisAIResult _parseResponse(String content) {
    try {
      final jsonStr = _extractJson(content);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final soilType = _parseSoilType(data['soilType'] as String? ?? '');
      final phLevel = (data['phLevel'] as num?)?.toDouble();
      final moistureLevel =
          _parseMoistureLevel(data['moistureLevel'] as String? ?? '');
      final drainageQuality =
          _parseDrainageQuality(data['drainageQuality'] as String? ?? '');
      final organicMatter =
          _parseNutrientLevel(data['organicMatter'] as String? ?? '');

      final rawRecs = data['recommendations'];
      final recommendations = rawRecs is List
          ? rawRecs.map((e) => e.toString()).toList()
          : <String>[];

      final notes = data['analysisNotes'] as String?;

      return SoilAnalysisAIResult(
        isSuccessful: true,
        soilType: soilType,
        phLevel: phLevel,
        moistureLevel: moistureLevel,
        drainageQuality: drainageQuality,
        organicMatter: organicMatter,
        recommendations: recommendations,
        analysisNotes: notes,
      );
    } catch (e) {
      debugPrint('⚠️ Error parsing soil analysis response: $e\n$content');
      return SoilAnalysisAIResult.failure(
        'No se pudo procesar la respuesta del análisis',
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
  // Enum parsers
  // ---------------------------------------------------------------------------

  SoilType? _parseSoilType(String v) {
    try {
      return SoilType.values.firstWhere(
        (e) => e.name.toLowerCase() == v.toLowerCase(),
      );
    } catch (_) {
      return SoilType.unknown;
    }
  }

  MoistureLevel? _parseMoistureLevel(String v) {
    try {
      return MoistureLevel.values.firstWhere(
        (e) => e.name.toLowerCase() == v.toLowerCase(),
      );
    } catch (_) {
      return MoistureLevel.optimal;
    }
  }

  DrainageQuality? _parseDrainageQuality(String v) {
    try {
      return DrainageQuality.values.firstWhere(
        (e) => e.name.toLowerCase() == v.toLowerCase(),
      );
    } catch (_) {
      return DrainageQuality.moderate;
    }
  }

  NutrientLevel? _parseNutrientLevel(String v) {
    try {
      return NutrientLevel.values.firstWhere(
        (e) => e.name.toLowerCase() == v.toLowerCase(),
      );
    } catch (_) {
      return NutrientLevel.moderate;
    }
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

  void _emit(SoilAnalysisProgressCallback? cb, SoilAnalysisStage stage) {
    cb?.call(stage, stage.message, stage.progress);
  }

  /// Stub result for development (no API key configured).
  SoilAnalysisAIResult _stubResult() => const SoilAnalysisAIResult(
        isSuccessful: true,
        soilType: SoilType.pottingMix,
        phLevel: 6.5,
        moistureLevel: MoistureLevel.optimal,
        drainageQuality: DrainageQuality.good,
        organicMatter: NutrientLevel.moderate,
        recommendations: [
          'El sustrato parece estar en buen estado general.',
          'Considera añadir perlita para mejorar la aireación.',
          'Riega cuando los primeros 2 cm de sustrato estén secos.',
        ],
        analysisNotes:
            'Análisis simulado (modo desarrollo). Configura OPENROUTER_API_KEY para análisis reales.',
      );
}
