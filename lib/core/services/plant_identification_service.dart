import 'dart:io';
import 'dart:typed_data';
import 'package:planticula/core/ai/identification_provider.dart' as ai;
import 'package:planticula/core/data/species/plant_species.dart';
import 'package:planticula/core/services/species_service.dart';

/// Etapas del proceso de identificaciÃ³n para mostrar progreso al usuario
enum IdentificationStage {
  preparing('Preparando imagen...', 0.1),
  uploading('Subiendo imagen...', 0.3),
  analyzing('La IA estÃ¡ analizando tu planta...', 0.6),
  processing('Procesando resultados...', 0.9),
  completed('Â¡IdentificaciÃ³n completada!', 1.0);

  final String message;
  final double progress;

  const IdentificationStage(this.message, this.progress);
}

/// Callback para reportar progreso de identificaciÃ³n
typedef ProgressCallback = void Function(
  IdentificationStage stage,
  String message,
  double progress,
);

/// Resultado de identificaciÃ³n de planta desde imagen
class PlantIdentificationResult {
  final PlantSpecies? species;
  final double speciesConfidence;
  final PlantEnvironment? suggestedEnvironment;
  final double environmentConfidence;
  final GrowthStage? suggestedGrowthStage;
  final double growthStageConfidence;
  final PotSize? suggestedPotSize;
  final double potSizeConfidence;
  final bool isSuccessful;
  final String? errorMessage;
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

/// Servicio para identificar plantas desde imÃ¡genes usando IA vision.
///
/// Delega la lÃ³gica HTTP/optimizaciÃ³n a [LlmVisionProvider] y conserva
/// la validaciÃ³n contra [SpeciesService] (catÃ¡logo de especies).
class PlantIdentificationService {
  final SpeciesService _speciesService;
  final ai.IdentificationProvider<Map<String, dynamic>> _provider;

  PlantIdentificationService(this._speciesService, this._provider);

  /// Identifica una planta desde una imagen usando IA
  Future<PlantIdentificationResult> identifyFromImage(
    Uint8List imageBytes, {
    PlantEnvironment? location,
    ProgressCallback? onProgress,
  }) async {
    try {
      if (!_provider.isAvailable) {
        return const PlantIdentificationResult(
          isSuccessful: false,
          errorMessage:
              'La identificaciÃ³n con IA no estÃ¡ disponible. Revisa tu conexiÃ³n '
              'a internet y la configuraciÃ³n de Supabase/OpenRouter.',
        );
      }

      final result = await _provider.identify(
        imageBytes,
        onProgress: onProgress != null
            ? (stage, msg, prog) =>
                onProgress(_mapStage(stage), msg, prog)
            : null,
      );

      if (result.isSuccessful && result.data != null) {
        return await _matchSpeciesAndBuildResult(
          result.data!,
          location,
        );
      }
      return PlantIdentificationResult(
        isSuccessful: false,
        errorMessage: result.errorMessage ?? 'Error en la identificaciÃ³n',
      );
    } catch (e) {
      return PlantIdentificationResult(
        isSuccessful: false,
        errorMessage: 'Error al procesar la imagen: $e',
      );
    }
  }

  /// Identifica una planta desde un archivo de imagen (compatibilidad legacy)
  Future<PlantIdentificationResult> identifyFromImageFile(
    File imageFile, {
    PlantEnvironment? location,
    ProgressCallback? onProgress,
  }) async {
    final bytes = await imageFile.readAsBytes();
    return identifyFromImage(bytes, location: location, onProgress: onProgress);
  }

  // ---------------------------------------------------------------------------
  // Species matching + result building
  // ---------------------------------------------------------------------------

  Future<PlantIdentificationResult> _matchSpeciesAndBuildResult(
    Map<String, dynamic> data,
    PlantEnvironment? location,
  ) async {
    final commonName = data['commonName'] as String?;
    final scientificName = data['scientificName'] as String?;

    PlantSpecies? matchedSpecies;
    double speciesConfidence = 0.0;

    if (commonName != null && commonName.isNotEmpty) {
      final searchResults = await _speciesService.searchSpecies(commonName);
      if (searchResults.isNotEmpty) {
        matchedSpecies = searchResults.first;
        speciesConfidence =
            (data['speciesConfidence'] as num?)?.toDouble() ?? 0.7;
      }
    }

    if (matchedSpecies == null &&
        scientificName != null &&
        scientificName.isNotEmpty) {
      final searchResults = await _speciesService.searchSpecies(scientificName);
      if (searchResults.isNotEmpty) {
        matchedSpecies = searchResults.first;
        speciesConfidence =
            (data['speciesConfidence'] as num?)?.toDouble() ?? 0.6;
      }
    }

    final environmentStr = data['environment'] as String?;
    final PlantEnvironment? suggestedEnvironment =
        environmentStr != null ? _parseEnvironment(environmentStr) : location;
    final environmentConfidence =
        (data['environmentConfidence'] as num?)?.toDouble() ??
            (suggestedEnvironment != null ? 0.7 : 0.0);

    final growthStageStr = data['growthStage'] as String?;
    final GrowthStage? suggestedGrowthStage =
        growthStageStr != null ? GrowthStage.fromString(growthStageStr) : null;
    final growthStageConfidence =
        (data['growthStageConfidence'] as num?)?.toDouble() ?? 0.6;

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
      errorMessage: matchedSpecies == null
          ? 'No se encontrÃ³ la especie "$commonName" en la base de datos'
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Stage mapping
  // ---------------------------------------------------------------------------

  static IdentificationStage _mapStage(String stage) {
    return switch (stage) {
      'preparing' => IdentificationStage.preparing,
      'uploading' => IdentificationStage.uploading,
      'analyzing' => IdentificationStage.analyzing,
      'processing' => IdentificationStage.processing,
      'completed' => IdentificationStage.completed,
      _ => IdentificationStage.preparing,
    };
  }

  // ---------------------------------------------------------------------------
  // Prompt
  // ---------------------------------------------------------------------------

  static String get plantIdV1Prompt => '''
Analiza esta imagen de planta y proporciona la siguiente informaciÃ³n en formato JSON:

{
  "commonName": "Nombre comÃºn en espaÃ±ol (ej: Helecho, Tomate, Monstera)",
  "scientificName": "Nombre cientÃ­fico (ej: Monstera deliciosa)",
  "environment": "indoor|outdoor",
  "growthStage": "germination|seedling|development|mature|flowering",
  "potSize": "extra_small|small|medium|large|extra_large",
  "speciesConfidence": 0.85,
  "environmentConfidence": 0.75,
  "growthStageConfidence": 0.80,
  "potSizeConfidence": 0.65,
  "reasoning": "Breve explicaciÃ³n de por quÃ© identificaste esta planta asÃ­"
}

Instrucciones detalladas:
- commonName: El nombre mÃ¡s comÃºn en espaÃ±ol para esta planta
- scientificName: Nombre cientÃ­fico/LatÃ­n si puedes identificarlo, o null si no estÃ¡s seguro
- environment: "indoor" si parece planta de interior/casa, "outdoor" si parece de exterior/jardÃ­n

- growthStage (NUEVO SISTEMA DE 5 ETAPAS):
  "germination": ReciÃ©n germinada, cotiledones visibles, sistema radicular incipiente
  "seedling": PlÃ¡ntula establecida, 2-6 hojas verdaderas, aÃºn pequeÃ±a y vulnerable
  "development": Crecimiento vegetativo activo, aumentando tamaÃ±o constantemente, momento ideal para tÃ©cnicas como LST/topping
  "mature": Planta alcanzÃ³ tamaÃ±o final, crecimiento lateral mÃ­nimo, estable
  "flowering": Fase reproductiva con flores o frutos visibles, o claramente en fase de floraciÃ³n

- potSize: Estima el tamaÃ±o de maceta basÃ¡ndote en la proporciÃ³n planta/maceta
  - extra_small: ~5cm (semillas/plÃ¡ntulas)
  - small: ~10-12cm
  - medium: ~15-20cm
  - large: ~25-30cm
  - extra_large: 35cm+

- Las confianzas deben ser valores entre 0.0 y 1.0

Responde SOLO con el JSON vÃ¡lido, sin texto adicional.
'''.trim();

  // ---------------------------------------------------------------------------
  // Parsers
  // ---------------------------------------------------------------------------

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

  PotSize? _parsePotSize(String value) {
    switch (value.toLowerCase().trim().replaceAll('_', '')) {
      case 'extrasmall':
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
      case 'xl':
        return PotSize.extraLarge;
      default:
        return null;
    }
  }
}
