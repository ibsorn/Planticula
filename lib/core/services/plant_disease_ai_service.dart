import 'dart:typed_data';
import 'package:planticula/core/ai/identification_provider.dart' as ai;
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

class PlantDiseaseAIService {
  final ai.IdentificationProvider<PlantDiseaseAIResult> _provider;

  PlantDiseaseAIService(this._provider);

  bool get isConfigured => _provider.isAvailable;

  Future<PlantDiseaseAIResult> analyzeFromBytes(
    Uint8List imageBytes, {
    DiagnosisProgressCallback? onProgress,
  }) async {
    if (!_provider.isAvailable) {
      return const PlantDiseaseAIResult.failure(
        'El diagnóstico con IA no está disponible. Revisa tu conexión a '
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
    return PlantDiseaseAIResult.failure(
      result.errorMessage ?? 'Error en el análisis',
    );
  }

  static DiagnosisStage _mapStage(String stage) {
    return switch (stage) {
      'preparing' => DiagnosisStage.preparing,
      'uploading' => DiagnosisStage.uploading,
      'analyzing' => DiagnosisStage.analyzing,
      'processing' => DiagnosisStage.processing,
      'completed' => DiagnosisStage.completed,
      _ => DiagnosisStage.preparing,
    };
  }

  static String get diseasePrompt => '''
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

  static PlantDiseaseAIResult parseResult(Map<String, dynamic> data) {
    final diagnosisType =
        (data['diagnosisType'] as String? ?? 'unknown').toDiagnosisType();
    final problemName = data['problemName'] as String?;
    final scientificName = data['scientificName'] as String?;
    final severity =
        (data['severity'] as String? ?? 'medium').toProblemSeverity();
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
  }

}
