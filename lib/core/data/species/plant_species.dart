import 'package:equatable/equatable.dart';

/// Represents a plant species with its care requirements
/// Can have varieties (subspecies) via the `varieties` list
/// A variety has a `parentId` pointing to its parent species
class PlantSpecies extends Equatable {
  final String id;
  final String commonName;
  final String scientificName;
  final String? imageUrl;
  final String? parentId; // If this is a variety, points to parent species
  final List<PlantSpecies> varieties; // Sub-varieties of this species
  final String? description; // Brief description or notes about the strain
  final String? category; // indoor, outdoor, succulent, cannabis, etc.
  final bool isEdible; // Whether the plant produces edible fruits/leaves/herbs

  // Watering info (days between waterings)
  final int wateringFrequencyIndoor;
  final int wateringFrequencyOutdoor;

  // Sunlight requirements
  final double sunlightHoursMin; // hours per day
  final double sunlightHoursMax;
  final SunlightLevel sunlightLevel;

  // Growth phases
  final List<GrowthPhaseInfo> growthPhases;

  // Transplant schedule: what pot size each phase needs and when to transplant
  // Describes the minimum recommended pot size at each growth stage.
  // If empty, no transplant tracking is available for this species.
  final List<TransplantPhaseInfo> transplantSchedule;

  // Climate sensitivity
  final int minTemperature; // Celsius
  final int maxTemperature;
  final bool droughtTolerant;
  final bool humidityLoving;

  // Watering adjustments
  final double hotWeatherMultiplier;  // multiply watering freq when >30C
  final double coldWeatherMultiplier; // multiply when <10C
  final double rainReductionDays;     // skip days after rain

  const PlantSpecies({
    required this.id,
    required this.commonName,
    required this.scientificName,
    this.imageUrl,
    this.parentId,
    this.varieties = const [],
    this.description,
    this.category,
    this.isEdible = false,
    required this.wateringFrequencyIndoor,
    required this.wateringFrequencyOutdoor,
    required this.sunlightHoursMin,
    required this.sunlightHoursMax,
    required this.sunlightLevel,
    required this.growthPhases,
    this.transplantSchedule = const [],
    this.minTemperature = 5,
    this.maxTemperature = 35,
    this.droughtTolerant = false,
    this.humidityLoving = false,
    this.hotWeatherMultiplier = 0.7,
    this.coldWeatherMultiplier = 1.5,
    this.rainReductionDays = 2,
  });

  /// Whether this species has selectable varieties
  bool get hasVarieties => varieties.isNotEmpty;

  /// Whether this is a sub-variety of another species
  bool get isVariety => parentId != null;

  /// Category helpers for adaptive UI
  bool get isCannabis => category == 'cannabis';
  bool get isSucculent => category == 'succulent';
  bool get isIndoorPlant => category == 'indoor';

  /// Get the base watering frequency based on environment
  int getBaseWateringDays(PlantEnvironment env) {
    return env == PlantEnvironment.indoor
        ? wateringFrequencyIndoor
        : wateringFrequencyOutdoor;
  }

  /// Get the transplant info for a specific growth stage (null if not defined)
  TransplantPhaseInfo? getTransplantInfo(GrowthStage stage) {
    for (final info in transplantSchedule) {
      if (info.stage == stage) return info;
    }
    return null;
  }

  /// Whether this species has a defined transplant schedule
  bool get hasTransplantSchedule => transplantSchedule.isNotEmpty;

  /// Get the watering multiplier for a specific growth stage
  double getWateringMultiplier(GrowthStage stage) {
    for (final phase in growthPhases) {
      if (phase.stage == stage) return phase.wateringMultiplier;
    }
    return 1.0;
  }

  /// Estimate months until adult phase from current phase
  int? monthsUntilAdult(GrowthStage currentStage) {
    if (currentStage == GrowthStage.adult) return 0;

    int totalMonths = 0;
    bool counting = false;

    for (final phase in growthPhases) {
      if (phase.stage == currentStage) {
        counting = true;
        totalMonths += phase.durationMonths ~/ 2; // halfway through current
        continue;
      }
      if (counting && phase.stage != GrowthStage.adult) {
        totalMonths += phase.durationMonths;
      }
      if (phase.stage == GrowthStage.adult) break;
    }

    return counting ? totalMonths : null;
  }

  factory PlantSpecies.fromJson(Map<String, dynamic> json) {
    return PlantSpecies(
      id: json['id'] as String,
      commonName: json['common_name'] as String,
      scientificName: json['scientific_name'] as String,
      imageUrl: json['image_url'] as String?,
      parentId: json['parent_id'] as String?,
      description: json['description'] as String?,
      category: json['category'] as String?,
      isEdible: json['is_edible'] as bool? ?? false,
      wateringFrequencyIndoor: json['watering_frequency_indoor'] as int? ?? 7,
      wateringFrequencyOutdoor: json['watering_frequency_outdoor'] as int? ?? 5,
      sunlightHoursMin: (json['sunlight_hours_min'] as num?)?.toDouble() ?? 4,
      sunlightHoursMax: (json['sunlight_hours_max'] as num?)?.toDouble() ?? 8,
      sunlightLevel: SunlightLevel.fromString(json['sunlight_level'] as String? ?? 'medium'),
      growthPhases: (json['growth_phases'] as List<dynamic>?)
              ?.map((e) => GrowthPhaseInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          GrowthPhaseInfo.defaultPhases,
      minTemperature: json['min_temperature'] as int? ?? 5,
      maxTemperature: json['max_temperature'] as int? ?? 35,
      droughtTolerant: json['drought_tolerant'] as bool? ?? false,
      humidityLoving: json['humidity_loving'] as bool? ?? false,
      hotWeatherMultiplier: (json['hot_weather_multiplier'] as num?)?.toDouble() ?? 0.7,
      coldWeatherMultiplier: (json['cold_weather_multiplier'] as num?)?.toDouble() ?? 1.5,
      rainReductionDays: (json['rain_reduction_days'] as num?)?.toDouble() ?? 2,
      transplantSchedule: (json['transplant_schedule'] as List<dynamic>?)
              ?.map((e) => TransplantPhaseInfo.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  @override
  List<Object?> get props => [id, commonName, scientificName];
}

enum PlantEnvironment {
  indoor,
  outdoor;

  String get displayName {
    switch (this) {
      case PlantEnvironment.indoor:
        return 'Interior';
      case PlantEnvironment.outdoor:
        return 'Exterior';
    }
  }

  String get icon {
    switch (this) {
      case PlantEnvironment.indoor:
        return 'home';
      case PlantEnvironment.outdoor:
        return 'park';
    }
  }
}

enum GrowthStage {
  seedling,
  juvenile,
  adult;

  String get displayName {
    switch (this) {
      case GrowthStage.seedling:
        return 'Plantula';
      case GrowthStage.juvenile:
        return 'Juvenil';
      case GrowthStage.adult:
        return 'Adulta';
    }
  }

  static GrowthStage fromString(String value) {
    switch (value.toLowerCase()) {
      case 'seedling':
        return GrowthStage.seedling;
      case 'juvenile':
        return GrowthStage.juvenile;
      case 'adult':
        return GrowthStage.adult;
      default:
        return GrowthStage.adult;
    }
  }
}

enum SunlightLevel {
  low,
  medium,
  high,
  fullSun;

  String get displayName {
    switch (this) {
      case SunlightLevel.low:
        return 'Sombra';
      case SunlightLevel.medium:
        return 'Semisombra';
      case SunlightLevel.high:
        return 'Luz indirecta brillante';
      case SunlightLevel.fullSun:
        return 'Sol directo';
    }
  }

  static SunlightLevel fromString(String value) {
    switch (value.toLowerCase()) {
      case 'low':
      case 'shade':
        return SunlightLevel.low;
      case 'medium':
      case 'part_shade':
        return SunlightLevel.medium;
      case 'high':
      case 'bright':
        return SunlightLevel.high;
      case 'full_sun':
      case 'fullsun':
        return SunlightLevel.fullSun;
      default:
        return SunlightLevel.medium;
    }
  }
}

/// Tamaño de maceta con rangos de litros y datos para calculo de riego/agua
enum PotSize {
  extraSmall, // Muy pequeña: 0.5-1.5L
  small,      // Pequeña: 1.5-5L
  medium,     // Mediana: 5-15L
  large,      // Grande: 15-40L
  extraLarge; // Muy grande / suelo directo: 40L+

  String get displayName {
    switch (this) {
      case PotSize.extraSmall:
        return 'Muy pequeña';
      case PotSize.small:
        return 'Pequeña';
      case PotSize.medium:
        return 'Mediana';
      case PotSize.large:
        return 'Grande';
      case PotSize.extraLarge:
        return 'Muy grande / Suelo';
    }
  }

  /// Rango de litros de la maceta
  String get litersRange {
    switch (this) {
      case PotSize.extraSmall:
        return '0.5 - 1.5 L';
      case PotSize.small:
        return '1.5 - 5 L';
      case PotSize.medium:
        return '5 - 15 L';
      case PotSize.large:
        return '15 - 40 L';
      case PotSize.extraLarge:
        return '40+ L / Suelo';
    }
  }

  /// Volumen medio representativo en litros (para calculos)
  double get avgLiters {
    switch (this) {
      case PotSize.extraSmall:
        return 1.0;
      case PotSize.small:
        return 3.0;
      case PotSize.medium:
        return 10.0;
      case PotSize.large:
        return 25.0;
      case PotSize.extraLarge:
        return 50.0;
    }
  }

  /// Multiplicador de frecuencia de riego respecto a maceta mediana (base).
  /// Macetas pequeñas se secan antes -> regar mas seguido (multiplier < 1.0)
  /// Macetas grandes retienen mas -> regar menos seguido (multiplier > 1.0)
  double get wateringFrequencyMultiplier {
    switch (this) {
      case PotSize.extraSmall:
        return 0.6;  // Regar ~40% mas frecuente
      case PotSize.small:
        return 0.8;  // Regar ~20% mas frecuente
      case PotSize.medium:
        return 1.0;  // Base (sin ajuste)
      case PotSize.large:
        return 1.3;  // Regar ~30% menos frecuente
      case PotSize.extraLarge:
        return 1.6;  // Regar ~60% menos frecuente
    }
  }

  /// Mililitros de agua base por riego (para maceta mediana de referencia).
  /// Se escala segun la etapa de crecimiento.
  /// Estos son los ml para una planta adulta en cada tamaño de maceta.
  int get baseWaterMl {
    switch (this) {
      case PotSize.extraSmall:
        return 100;   // 50-150ml
      case PotSize.small:
        return 250;   // 150-350ml
      case PotSize.medium:
        return 500;   // 350-700ml
      case PotSize.large:
        return 1000;  // 700-1500ml
      case PotSize.extraLarge:
        return 2000;  // 1500-3000ml
    }
  }

  /// Icono representativo
  String get icon {
    switch (this) {
      case PotSize.extraSmall:
        return '🪴';
      case PotSize.small:
        return '🌱';
      case PotSize.medium:
        return '🪻';
      case PotSize.large:
        return '🌳';
      case PotSize.extraLarge:
        return '🏡';
    }
  }

  static PotSize fromString(String value) {
    switch (value.toLowerCase()) {
      case 'extra_small':
      case 'extrasmall':
        return PotSize.extraSmall;
      case 'small':
        return PotSize.small;
      case 'medium':
        return PotSize.medium;
      case 'large':
        return PotSize.large;
      case 'extra_large':
      case 'extralarge':
        return PotSize.extraLarge;
      default:
        return PotSize.medium;
    }
  }

  /// Nombre para almacenar en DB (snake_case)
  String get dbValue {
    switch (this) {
      case PotSize.extraSmall:
        return 'extra_small';
      case PotSize.small:
        return 'small';
      case PotSize.medium:
        return 'medium';
      case PotSize.large:
        return 'large';
      case PotSize.extraLarge:
        return 'extra_large';
    }
  }
}

/// Describes the transplant requirements for a specific growth stage.
///
/// Design rationale:
/// - Lives on the *species*, not on the *plant instance* → species knowledge, not user data
/// - `minPotSize`: smallest acceptable pot for this stage
/// - `idealPotSize`: best pot for healthy growth at this stage
/// - `triggerAfterMonths`: how many months into this stage before triggering the transplant alert
///   (0 = alert at the very start of the stage, i.e. when entering it)
/// - `notes`: human-readable tip shown in the UI
///
/// Example for a Monstera (indoor):
///   seedling  → minPot: extraSmall, idealPot: small,  triggerAfterMonths: 2
///   juvenile  → minPot: small,      idealPot: medium, triggerAfterMonths: 6
///   adult     → minPot: medium,     idealPot: large,  triggerAfterMonths: 12
class TransplantPhaseInfo extends Equatable {
  final GrowthStage stage;

  /// Minimum pot size that works for this stage.
  /// If the plant's current pot is SMALLER than this, alert immediately.
  final PotSize minPotSize;

  /// Ideal pot size that allows optimal growth at this stage.
  final PotSize idealPotSize;

  /// Months after entering this growth stage before we start suggesting transplant.
  /// Allows the plant time to settle before alerting the user.
  /// 0 = alert as soon as this stage starts.
  final int triggerAfterMonths;

  /// Optional care tip shown to the user when a transplant is due.
  final String? notes;

  const TransplantPhaseInfo({
    required this.stage,
    required this.minPotSize,
    required this.idealPotSize,
    this.triggerAfterMonths = 0,
    this.notes,
  });

  factory TransplantPhaseInfo.fromJson(Map<String, dynamic> json) {
    return TransplantPhaseInfo(
      stage: GrowthStage.fromString(json['stage'] as String),
      minPotSize: PotSize.fromString(json['min_pot_size'] as String? ?? 'small'),
      idealPotSize: PotSize.fromString(json['ideal_pot_size'] as String? ?? 'medium'),
      triggerAfterMonths: json['trigger_after_months'] as int? ?? 0,
      notes: json['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [stage, minPotSize, idealPotSize, triggerAfterMonths];
}

class GrowthPhaseInfo extends Equatable {
  final GrowthStage stage;
  final int durationMonths;
  final String? description;
  /// Multiplier applied to base watering frequency for this growth stage.
  /// < 1.0 = water more often (e.g. seedlings need more frequent watering)
  /// = 1.0 = use base frequency as-is
  /// > 1.0 = water less often (e.g. dormant/mature plants)
  final double wateringMultiplier;

  const GrowthPhaseInfo({
    required this.stage,
    required this.durationMonths,
    this.description,
    this.wateringMultiplier = 1.0,
  });

  factory GrowthPhaseInfo.fromJson(Map<String, dynamic> json) {
    return GrowthPhaseInfo(
      stage: GrowthStage.fromString(json['stage'] as String),
      durationMonths: json['duration_months'] as int,
      description: json['description'] as String?,
      wateringMultiplier: (json['watering_multiplier'] as num?)?.toDouble() ?? 1.0,
    );
  }

  static List<GrowthPhaseInfo> get defaultPhases => const [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 3, wateringMultiplier: 0.7),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 12, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ];

  @override
  List<Object?> get props => [stage, durationMonths, wateringMultiplier];
}
