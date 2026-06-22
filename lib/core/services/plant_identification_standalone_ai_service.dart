import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:planticula/core/ai/identification_provider.dart' as ai;

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

class PlantIdentificationStandaloneAIService {
  final ai.IdentificationProvider<PlantIdAIResult> _provider;

  PlantIdentificationStandaloneAIService(this._provider);

  bool get isConfigured => _provider.isAvailable;

  Future<PlantIdAIResult> analyzeFromBytes(
    Uint8List imageBytes, {
    PlantIdProgressCallback? onProgress,
  }) async {
    if (!_provider.isAvailable) {
      return const PlantIdAIResult.failure(
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

    debugPrint('[PlantIdV2] result: success=${result.isSuccessful}, confidence=${result.confidence}, provider=${result.providerInfo.name}, error=${result.errorMessage}');
    if (result.data != null) {
      debugPrint('[PlantIdV2] commonName=${result.data!.commonName}, scientific=${result.data!.scientificName}');
    }

    if (result.isSuccessful && result.data != null) {
      final data = result.data!;
      // If commonName is null or "Planta no identificada", return failure with diagnostic info
      if (data.commonName == null || data.commonName == 'Planta no identificada') {
        return PlantIdAIResult.failure(
          'No se pudo identificar la planta (provider: ${result.providerInfo.name}, confidence: ${result.confidence})',
        );
      }
      return data;
    }
    return PlantIdAIResult.failure(
      result.errorMessage ?? 'Error en el análisis',
    );
  }

  static PlantIdStage _mapStage(String stage) {
    return switch (stage) {
      'preparing' => PlantIdStage.preparing,
      'uploading' => PlantIdStage.uploading,
      'analyzing' => PlantIdStage.analyzing,
      'processing' => PlantIdStage.processing,
      'completed' => PlantIdStage.completed,
      _ => PlantIdStage.preparing,
    };
  }

  static String get plantIdPrompt => '''
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

  static PlantIdAIResult parseResult(Map<String, dynamic> data) {
    final careLevel = _parseCareLevel(data['careLevel'] as String? ?? '');
    final wateringFrequency =
        _parseWateringFrequency(data['wateringFrequency'] as String? ?? '');
    final lightRequirement =
        _parseLightRequirement(data['lightRequirement'] as String? ?? '');
    final humidityRequirement =
        _parseHumidityRequirement(data['humidityRequirement'] as String? ?? '');

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
  }

  static PlantIdCareLevel? _parseCareLevel(String s) =>
      PlantIdCareLevel.values.where((e) => e.name == s).firstOrNull;

  static PlantIdWateringFrequency? _parseWateringFrequency(String s) =>
      PlantIdWateringFrequency.values.where((e) => e.name == s).firstOrNull;

  static PlantIdLightRequirement? _parseLightRequirement(String s) =>
      PlantIdLightRequirement.values.where((e) => e.name == s).firstOrNull;

  static PlantIdHumidityRequirement? _parseHumidityRequirement(String s) =>
      PlantIdHumidityRequirement.values.where((e) => e.name == s).firstOrNull;

}

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
