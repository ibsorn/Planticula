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
