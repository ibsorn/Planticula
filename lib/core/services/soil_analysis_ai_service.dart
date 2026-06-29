import 'dart:typed_data';
import 'package:planticula/core/ai/identification_provider.dart' as ai;
import 'package:planticula/core/utils/logger.dart';
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

class SoilAnalysisAIService {
  final ai.IdentificationProvider<SoilAnalysisAIResult> _provider;

  SoilAnalysisAIService(this._provider);

  bool get isConfigured => _provider.isAvailable;

  Future<SoilAnalysisAIResult> analyzeFromBytes(
    Uint8List imageBytes, {
    SoilAnalysisProgressCallback? onProgress,
  }) async {
    if (!_provider.isAvailable) {
      return const SoilAnalysisAIResult.failure(
        'El análisis con IA no está disponible. Revisa tu conexión a internet '
        'y la configuración de Supabase/OpenRouter.',
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
    return SoilAnalysisAIResult.failure(
      result.errorMessage ?? 'Error en el análisis',
    );
  }

  static SoilAnalysisStage _mapStage(String stage) {
    return switch (stage) {
      'preparing' => SoilAnalysisStage.preparing,
      'uploading' => SoilAnalysisStage.uploading,
      'analyzing' => SoilAnalysisStage.analyzing,
      'processing' => SoilAnalysisStage.processing,
      'completed' => SoilAnalysisStage.completed,
      _ => SoilAnalysisStage.preparing,
    };
  }

  static String get soilPrompt => '''
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

  static SoilAnalysisAIResult parseResult(Map<String, dynamic> data) {
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

    return SoilAnalysisAIResult(
      isSuccessful: true,
      soilType: soilType,
      phLevel: phLevel,
      moistureLevel: moistureLevel,
      drainageQuality: drainageQuality,
      organicMatter: organicMatter,
      recommendations: recommendations,
      analysisNotes: data['analysisNotes'] as String?,
    );
  }

  static SoilType? _parseSoilType(String v) {
    try {
      return SoilType.values
          .firstWhere((e) => e.name.toLowerCase() == v.toLowerCase());
    } catch (e) {
      Logger.w('Unknown soil type "$v", defaulting to unknown: $e');
      return SoilType.unknown;
    }
  }

  static MoistureLevel? _parseMoistureLevel(String v) {
    try {
      return MoistureLevel.values
          .firstWhere((e) => e.name.toLowerCase() == v.toLowerCase());
    } catch (e) {
      Logger.w('Unknown moisture level "$v", defaulting to optimal: $e');
      return MoistureLevel.optimal;
    }
  }

  static DrainageQuality? _parseDrainageQuality(String v) {
    try {
      return DrainageQuality.values
          .firstWhere((e) => e.name.toLowerCase() == v.toLowerCase());
    } catch (e) {
      Logger.w('Unknown drainage quality "$v", defaulting to moderate: $e');
      return DrainageQuality.moderate;
    }
  }

  static NutrientLevel? _parseNutrientLevel(String v) {
    try {
      return NutrientLevel.values
          .firstWhere((e) => e.name.toLowerCase() == v.toLowerCase());
    } catch (e) {
      Logger.w('Unknown nutrient level "$v", defaulting to moderate: $e');
      return NutrientLevel.moderate;
    }
  }

}
