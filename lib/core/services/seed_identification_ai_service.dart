import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:planticula/core/services/ai_provider_config.dart';

/// Stages of the seed identification process for UI progress feedback.
enum SeedIdStage {
  preparing('Preparando imagen...', 0.1),
  uploading('Enviando a análisis...', 0.3),
  analyzing('La IA está identificando la semilla...', 0.6),
  processing('Procesando resultados...', 0.9),
  completed('¡Identificación completada!', 1.0);

  final String message;
  final double progress;

  const SeedIdStage(this.message, this.progress);
}

typedef SeedIdProgressCallback = void Function(
  SeedIdStage stage,
  String message,
  double progress,
);

/// Result returned by [SeedIdentificationAIService.analyzeFromBytes].
class SeedIdAIResult {
  final bool isSuccessful;
  final String? errorMessage;

  final String? commonName;
  final String? scientificName;
  final String? family;
  final SeedIdGerminationDifficulty? germinationDifficulty;
  final SeedIdGerminationTime? germinationTime;
  final SeedIdSowingDepth? sowingDepth;
  final SeedIdSowingSeason? bestSowingSeason;
  final double? confidenceScore;
  final String? description;
  final List<String> germinationTips;
  final String? soilRecommendation;
  final String? analysisNotes;

  const SeedIdAIResult({
    required this.isSuccessful,
    this.errorMessage,
    this.commonName,
    this.scientificName,
    this.family,
    this.germinationDifficulty,
    this.germinationTime,
    this.sowingDepth,
    this.bestSowingSeason,
    this.confidenceScore,
    this.description,
    this.germinationTips = const [],
    this.soilRecommendation,
    this.analysisNotes,
  });

  const SeedIdAIResult.failure(String message)
      : isSuccessful = false,
        errorMessage = message,
        commonName = null,
        scientificName = null,
        family = null,
        germinationDifficulty = null,
        germinationTime = null,
        sowingDepth = null,
        bestSowingSeason = null,
        confidenceScore = null,
        description = null,
        germinationTips = const [],
        soilRecommendation = null,
        analysisNotes = null;
}

/// Identifies seeds from photos using a configurable AI vision model.
///
/// Provider and model resolved via [AiProviderConfig.seedIdentification]:
///   SEED_ID_API_KEY / SEED_ID_BASE_URL / SEED_ID_MODEL
/// Fallback to shared OPENROUTER_* keys if per-function keys are absent.
class SeedIdentificationAIService {
  final AiProviderConfig _cfg;

  const SeedIdentificationAIService(this._cfg);

  Future<SeedIdAIResult> analyzeFromBytes(
    Uint8List imageBytes, {
    SeedIdProgressCallback? onProgress,
  }) async {
    try {
      if (!_cfg.isFullyConfigured) {
        return _stubResult();
      }
      return await _analyzeWithOpenRouter(imageBytes, onProgress);
    } catch (e) {
      return SeedIdAIResult.failure('Error al analizar la imagen: ${e.toString()}');
    }
  }

  // ---------------------------------------------------------------------------
  // OpenRouter call
  // ---------------------------------------------------------------------------

  Future<SeedIdAIResult> _analyzeWithOpenRouter(
    Uint8List imageBytes,
    SeedIdProgressCallback? onProgress,
  ) async {
    _emit(onProgress, SeedIdStage.preparing);

    final optimized = await _optimizeImage(imageBytes);
    final base64Image = base64Encode(optimized);

    _emit(onProgress, SeedIdStage.uploading);

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
        'X-Title': 'Planticula Seed Identification',
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
        'max_tokens': 900,
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
            SeedIdStage.analyzing,
            'La IA está identificando la semilla${'.' * ((elapsed ~/ 1000) % 4)}',
            p,
          );
        });
      }

      final streamed = await requestFuture;
      heartbeat?.cancel();

      _emit(onProgress, SeedIdStage.processing);

      final response = await http.Response.fromStream(streamed);
      if (response.statusCode != 200) {
        throw Exception('AI API error ${response.statusCode}: ${response.body}');
      }

      final json = jsonDecode(response.body);
      final content = json['choices']?[0]?['message']?['content'] as String?;
      if (content == null || content.isEmpty) {
        throw Exception('Respuesta vacía de OpenRouter');
      }

      _emit(onProgress, SeedIdStage.completed);
      return _parseResponse(content);
    } finally {
      client.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Prompt
  // ---------------------------------------------------------------------------

  String _buildPrompt() => '''
Identifica la semilla de esta imagen y responde SOLO con JSON válido:

{
  "commonName": "Nombre común en español (ej: Tomate, Girasol, Lavanda)",
  "scientificName": "Nombre científico (ej: Solanum lycopersicum)",
  "family": "Familia botánica (ej: Solanaceae)",
  "germinationDifficulty": "easy|moderate|difficult|expert",
  "germinationTime": "veryFast|fast|moderate|slow|verySlow",
  "sowingDepth": "surface|shallow|medium|deep",
  "bestSowingSeason": "spring|summer|autumn|winter|yearRound",
  "confidenceScore": 0.85,
  "description": "Descripción breve de la semilla y la planta que produce en 2-3 frases",
  "germinationTips": ["Consejo de germinación 1", "Consejo de germinación 2"],
  "soilRecommendation": "Tipo de sustrato recomendado para germinar",
  "analysisNotes": "Observación general sobre la semilla"
}

Instrucciones:
- germinationDifficulty: dificultad para hacer germinar la semilla
- germinationTime: tiempo estimado de germinación (veryFast=1-3d, fast=4-7d, moderate=1-2sem, slow=2-4sem, verySlow=+4sem)
- sowingDepth: profundidad de siembra (surface=en superficie, shallow=0.5-1cm, medium=1-3cm, deep=+3cm)
- bestSowingSeason: mejor época para sembrar
- confidenceScore: confianza en la identificación entre 0.0 y 1.0
- germinationTips: 2-4 consejos específicos para una buena germinación
- soilRecommendation: descripción breve del sustrato ideal

Si no puedes identificar la semilla, usa "Semilla no identificada" en commonName y confidenceScore bajo (< 0.3).
Responde SOLO con el JSON, sin texto adicional.
'''.trim();

  // ---------------------------------------------------------------------------
  // Parse
  // ---------------------------------------------------------------------------

  SeedIdAIResult _parseResponse(String content) {
    try {
      final jsonStr = _extractJson(content);
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;

      final rawTips = data['germinationTips'];
      final germinationTips = rawTips is List
          ? rawTips.map((e) => e.toString()).toList()
          : <String>[];

      return SeedIdAIResult(
        isSuccessful: true,
        commonName: data['commonName'] as String?,
        scientificName: data['scientificName'] as String?,
        family: data['family'] as String?,
        germinationDifficulty: _parseGerminationDifficulty(data['germinationDifficulty'] as String? ?? ''),
        germinationTime: _parseGerminationTime(data['germinationTime'] as String? ?? ''),
        sowingDepth: _parseSowingDepth(data['sowingDepth'] as String? ?? ''),
        bestSowingSeason: _parseSowingSeason(data['bestSowingSeason'] as String? ?? ''),
        confidenceScore: (data['confidenceScore'] as num?)?.toDouble(),
        description: data['description'] as String?,
        germinationTips: germinationTips,
        soilRecommendation: data['soilRecommendation'] as String?,
        analysisNotes: data['analysisNotes'] as String?,
      );
    } catch (e) {
      debugPrint('[SeedIdAIService] Parse error: $e\nContent: $content');
      return const SeedIdAIResult.failure('Error al procesar la respuesta de la IA');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _emit(SeedIdProgressCallback? cb, SeedIdStage stage) {
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

  SeedIdGerminationDifficulty? _parseGerminationDifficulty(String s) =>
      SeedIdGerminationDifficulty.values.where((e) => e.name == s).firstOrNull;

  SeedIdGerminationTime? _parseGerminationTime(String s) =>
      SeedIdGerminationTime.values.where((e) => e.name == s).firstOrNull;

  SeedIdSowingDepth? _parseSowingDepth(String s) =>
      SeedIdSowingDepth.values.where((e) => e.name == s).firstOrNull;

  SeedIdSowingSeason? _parseSowingSeason(String s) =>
      SeedIdSowingSeason.values.where((e) => e.name == s).firstOrNull;

  // ---------------------------------------------------------------------------
  // Stub (no API key)
  // ---------------------------------------------------------------------------

  SeedIdAIResult _stubResult() => const SeedIdAIResult(
    isSuccessful: true,
    commonName: 'Tomate cherry (demo)',
    scientificName: 'Solanum lycopersicum var. cerasiforme',
    family: 'Solanaceae',
    germinationDifficulty: SeedIdGerminationDifficulty.easy,
    germinationTime: SeedIdGerminationTime.fast,
    sowingDepth: SeedIdSowingDepth.shallow,
    bestSowingSeason: SeedIdSowingSeason.spring,
    confidenceScore: 0.88,
    description: 'Semilla pequeña y redondeada de tomate cherry. Produce plantas productivas con frutos dulces.',
    germinationTips: [
      'Mantén el sustrato húmedo pero no encharcado',
      'Temperatura ideal entre 20-25°C',
      'Cubre ligeramente con tierra fina',
    ],
    soilRecommendation: 'Sustrato universal con perlita para mejorar el drenaje.',
    analysisNotes: 'Modo demostración — configura SEED_ID_API_KEY para análisis real.',
  );
}

// =============================================================================
// Enums
// =============================================================================

enum SeedIdGerminationDifficulty {
  easy('Fácil'),
  moderate('Moderada'),
  difficult('Difícil'),
  expert('Experto');

  final String displayName;
  const SeedIdGerminationDifficulty(this.displayName);
}

enum SeedIdGerminationTime {
  veryFast('1-3 días'),
  fast('4-7 días'),
  moderate('1-2 semanas'),
  slow('2-4 semanas'),
  verySlow('Más de 4 semanas');

  final String displayName;
  const SeedIdGerminationTime(this.displayName);
}

enum SeedIdSowingDepth {
  surface('En superficie'),
  shallow('0.5-1 cm'),
  medium('1-3 cm'),
  deep('Más de 3 cm');

  final String displayName;
  const SeedIdSowingDepth(this.displayName);
}

enum SeedIdSowingSeason {
  spring('Primavera'),
  summer('Verano'),
  autumn('Otoño'),
  winter('Invierno'),
  yearRound('Todo el año');

  final String displayName;
  const SeedIdSowingSeason(this.displayName);
}
