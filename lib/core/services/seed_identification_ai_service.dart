import 'dart:typed_data';
import 'package:planticula/core/ai/identification_provider.dart' as ai;

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

class SeedIdentificationAIService {
  final ai.IdentificationProvider<SeedIdAIResult> _provider;

  SeedIdentificationAIService(this._provider);

  bool get isConfigured => _provider.isAvailable;

  Future<SeedIdAIResult> analyzeFromBytes(
    Uint8List imageBytes, {
    SeedIdProgressCallback? onProgress,
  }) async {
    if (!_provider.isAvailable) {
      return const SeedIdAIResult.failure(
        'La identificación con IA no está disponible. Revisa tu conexión a '
        'internet y la configuración de Supabase/OpenRouter.',
      );
    }

    final result = await _provider.identify(
      imageBytes,
      onProgress: onProgress != null
          ? (stage, msg, prog) => onProgress(_mapStage(stage), msg, prog)
          : null,
    );

    if (result.isSuccessful && result.data != null) {
      return result.data!;
    }
    return SeedIdAIResult.failure(
      result.errorMessage ?? 'Error en el análisis',
    );
  }

  static SeedIdStage _mapStage(String stage) {
    return switch (stage) {
      'preparing' => SeedIdStage.preparing,
      'uploading' => SeedIdStage.uploading,
      'analyzing' => SeedIdStage.analyzing,
      'processing' => SeedIdStage.processing,
      'completed' => SeedIdStage.completed,
      _ => SeedIdStage.preparing,
    };
  }

  static String get seedIdPrompt => '''
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

  static SeedIdAIResult parseResult(Map<String, dynamic> data) {
    final rawTips = data['germinationTips'];
    final germinationTips = rawTips is List
        ? rawTips.map((e) => e.toString()).toList()
        : <String>[];

    return SeedIdAIResult(
      isSuccessful: true,
      commonName: data['commonName'] as String?,
      scientificName: data['scientificName'] as String?,
      family: data['family'] as String?,
      germinationDifficulty:
          _parseGerminationDifficulty(data['germinationDifficulty'] as String? ?? ''),
      germinationTime:
          _parseGerminationTime(data['germinationTime'] as String? ?? ''),
      sowingDepth: _parseSowingDepth(data['sowingDepth'] as String? ?? ''),
      bestSowingSeason:
          _parseSowingSeason(data['bestSowingSeason'] as String? ?? ''),
      confidenceScore: (data['confidenceScore'] as num?)?.toDouble(),
      description: data['description'] as String?,
      germinationTips: germinationTips,
      soilRecommendation: data['soilRecommendation'] as String?,
      analysisNotes: data['analysisNotes'] as String?,
    );
  }

  static SeedIdGerminationDifficulty? _parseGerminationDifficulty(String s) =>
      SeedIdGerminationDifficulty.values.where((e) => e.name == s).firstOrNull;

  static SeedIdGerminationTime? _parseGerminationTime(String s) =>
      SeedIdGerminationTime.values.where((e) => e.name == s).firstOrNull;

  static SeedIdSowingDepth? _parseSowingDepth(String s) =>
      SeedIdSowingDepth.values.where((e) => e.name == s).firstOrNull;

  static SeedIdSowingSeason? _parseSowingSeason(String s) =>
      SeedIdSowingSeason.values.where((e) => e.name == s).firstOrNull;

}

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
