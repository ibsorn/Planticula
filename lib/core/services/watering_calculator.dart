import 'package:planticula/core/constants/app_constants.dart';
import 'package:planticula/core/data/species/plant_species.dart';
import 'package:planticula/core/services/weather_service.dart';

/// Intelligent watering calculator that considers species, environment,
/// pot size, growth stage, and weather
class WateringCalculator {
  /// Calculate the recommended watering frequency in days
  /// considering species, environment, pot size, and optionally weather data
  static WateringRecommendation calculate({
    required PlantSpecies species,
    required PlantEnvironment environment,
    GrowthStage growthStage = GrowthStage.adult,
    PotSize potSize = PotSize.medium,
    WeatherData? weather,
  }) {
    // Base frequency from species + environment
    final baseDays = species.getBaseWateringDays(environment);
    double adjustedDays = baseDays.toDouble();
    String reason = 'Frecuencia base para ${species.commonName}';
    final adjustments = <String>[];

    // Growth stage adjustment
    final stageMultiplier = species.getWateringMultiplier(growthStage);
    if (stageMultiplier != 1.0) {
      adjustedDays *= stageMultiplier;
      if (stageMultiplier < 1.0) {
        adjustments.add('Planta joven: necesita riego mas frecuente');
      } else {
        adjustments.add('Planta madura: necesita menos riego');
      }
    }

    // Pot size adjustment
    final potMultiplier = potSize.wateringFrequencyMultiplier;
    if (potMultiplier != 1.0) {
      adjustedDays *= potMultiplier;
      if (potMultiplier < 1.0) {
        adjustments.add('Maceta ${potSize.displayName.toLowerCase()}: se seca antes');
      } else {
        adjustments.add('Maceta ${potSize.displayName.toLowerCase()}: retiene mas humedad');
      }
    }

    // Weather adjustments (only for outdoor plants with weather data)
    if (environment == PlantEnvironment.outdoor && weather != null) {
      // Temperature adjustment
      final avgTemp = weather.avgMaxTempNextDays(AppConstants.weatherForecastDays);
      if (avgTemp > AppConstants.tempHighThresholdC) {
        adjustedDays *= species.hotWeatherMultiplier;
        adjustments.add('Calor (${avgTemp.round()}C): regar mas seguido');
      } else if (avgTemp < AppConstants.tempLowThresholdC) {
        adjustedDays *= species.coldWeatherMultiplier;
        adjustments.add('Frio (${avgTemp.round()}C): reducir riego');
      }

      // Rain adjustment
      final rainNextDays = weather.precipitationNextDays(AppConstants.weatherForecastDays);
      if (rainNextDays > AppConstants.rainHeavyMm) {
        adjustedDays += species.rainReductionDays;
        adjustments.add('Lluvia prevista (${rainNextDays.round()}mm): posponer riego');
      } else if (rainNextDays > AppConstants.rainLightMm) {
        adjustedDays += species.rainReductionDays / 2;
        adjustments.add('Lluvia ligera prevista: ajuste menor');
      }

      // Humidity adjustment for humidity-loving plants
      if (species.humidityLoving && weather.current.humidity < AppConstants.humidityLowPct) {
        adjustedDays *= AppConstants.lowHumidityWateringMultiplier;
        adjustments.add('Humedad baja: regar mas seguido');
      }
    }

    // Indoor adjustments
    if (environment == PlantEnvironment.indoor && weather != null) {
      // In winter (cold outside), indoor heating dries plants
      final avgTemp = weather.avgMaxTempNextDays(AppConstants.weatherForecastDays);
      if (avgTemp < AppConstants.tempLowThresholdC) {
        adjustedDays *= AppConstants.indoorHeatingMultiplier; // Slightly more frequent due to heating
        adjustments.add('Calefaccion interior: regar un poco mas');
      }
    }

    // Clamp to reasonable range
    final finalDays = adjustedDays.round().clamp(AppConstants.wateringFrequencyMinDays, AppConstants.wateringFrequencyMaxDays);

    if (adjustments.isEmpty) {
      reason = environment == PlantEnvironment.indoor
          ? 'Frecuencia para interior'
          : 'Frecuencia para exterior';
    }

    // Calculate water amount in ml
    final waterMl = calculateWaterMl(
      potSize: potSize,
      growthStage: growthStage,
      species: species,
    );

    return WateringRecommendation(
      frequencyDays: finalDays,
      baseFrequencyDays: baseDays,
      reason: reason,
      adjustments: adjustments,
      nextWatering: DateTime.now().add(Duration(days: finalDays)),
      sunlightHoursMin: species.sunlightHoursMin,
      sunlightHoursMax: species.sunlightHoursMax,
      sunlightLevel: species.sunlightLevel,
      waterMl: waterMl,
      potSize: potSize,
    );
  }

  /// Calculate recommended water amount in ml per watering session
  /// Based on pot size, growth stage, and species characteristics.
  ///
  /// Logic:
  /// - Base ml comes from pot size (bigger pot = more water)
  /// - Seedlings get ~40% of adult water amount
  /// - Juveniles get ~70% of adult water amount  
  /// - Drought-tolerant plants get ~70% of normal water
  /// - Humidity-loving plants get ~120% of normal water
  static int calculateWaterMl({
    required PotSize potSize,
    required GrowthStage growthStage,
    required PlantSpecies species,
  }) {
    double ml = potSize.baseWaterMl.toDouble();

    // Growth stage multiplier for water amount
    switch (growthStage) {
      case GrowthStage.seedling:
        ml *= AppConstants.seedlingWaterMultiplier;
      case GrowthStage.juvenile:
        ml *= AppConstants.juvenileWaterMultiplier;
      case GrowthStage.adult:
        ml *= 1.0;
    }

    // Species characteristics
    if (species.droughtTolerant) {
      ml *= AppConstants.droughtTolerantWaterMultiplier; // Succulents/cacti need less water per session
    }
    if (species.humidityLoving) {
      ml *= AppConstants.humidityLovingWaterMultiplier; // Tropical plants like more water
    }

    return ml.round().clamp(AppConstants.waterMlMin, AppConstants.waterMlMax);
  }

  /// Calculate next watering date after marking plant as watered
  static DateTime calculateNextWatering({
    required int frequencyDays,
    DateTime? fromDate,
  }) {
    final from = fromDate ?? DateTime.now();
    return from.add(Duration(days: frequencyDays));
  }
}

class WateringRecommendation {
  final int frequencyDays;
  final int baseFrequencyDays;
  final String reason;
  final List<String> adjustments;
  final DateTime nextWatering;
  final double sunlightHoursMin;
  final double sunlightHoursMax;
  final SunlightLevel sunlightLevel;
  final int waterMl; // Millilitres of water per watering session
  final PotSize potSize;

  const WateringRecommendation({
    required this.frequencyDays,
    required this.baseFrequencyDays,
    required this.reason,
    required this.adjustments,
    required this.nextWatering,
    required this.sunlightHoursMin,
    required this.sunlightHoursMax,
    required this.sunlightLevel,
    required this.waterMl,
    required this.potSize,
  });

  bool get hasWeatherAdjustments => adjustments.isNotEmpty;

  String get sunlightDescription =>
      '${sunlightHoursMin.round()}-${sunlightHoursMax.round()}h de sol al dia (${sunlightLevel.displayName})';

  String get frequencyDescription {
    if (frequencyDays == 1) return 'Cada dia';
    if (frequencyDays == 7) return 'Cada semana';
    if (frequencyDays == 14) return 'Cada 2 semanas';
    return 'Cada $frequencyDays dias';
  }

  /// Human-readable water amount
  String get waterMlDescription {
    if (waterMl >= AppConstants.waterMlLiterThreshold) {
      final liters = waterMl / 1000;
      return '${liters.toStringAsFixed(1)} L';
    }
    return '$waterMl ml';
  }

  /// Range description (±20%)
  String get waterMlRange {
    final min = (waterMl * AppConstants.waterRangeLowerFactor).round();
    final max = (waterMl * AppConstants.waterRangeUpperFactor).round();
    if (max >= AppConstants.waterMlLiterThreshold) {
      return '${(min / 1000).toStringAsFixed(1)}-${(max / 1000).toStringAsFixed(1)} L';
    }
    return '$min-$max ml';
  }
}
