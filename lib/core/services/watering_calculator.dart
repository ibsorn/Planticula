import 'package:planticula/core/data/species/plant_species.dart';
import 'package:planticula/core/services/weather_service.dart';

/// Intelligent watering calculator that considers species, environment, and weather
class WateringCalculator {
  /// Calculate the recommended watering frequency in days
  /// considering species, environment, and optionally weather data
  static WateringRecommendation calculate({
    required PlantSpecies species,
    required PlantEnvironment environment,
    GrowthStage growthStage = GrowthStage.adult,
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

    // Weather adjustments (only for outdoor plants with weather data)
    if (environment == PlantEnvironment.outdoor && weather != null) {
      // Temperature adjustment
      final avgTemp = weather.avgMaxTempNextDays(3);
      if (avgTemp > 30) {
        adjustedDays *= species.hotWeatherMultiplier;
        adjustments.add('Calor (${avgTemp.round()}C): regar mas seguido');
      } else if (avgTemp < 10) {
        adjustedDays *= species.coldWeatherMultiplier;
        adjustments.add('Frio (${avgTemp.round()}C): reducir riego');
      }

      // Rain adjustment
      final rainNextDays = weather.precipitationNextDays(3);
      if (rainNextDays > 5) {
        adjustedDays += species.rainReductionDays;
        adjustments.add('Lluvia prevista (${rainNextDays.round()}mm): posponer riego');
      } else if (rainNextDays > 2) {
        adjustedDays += species.rainReductionDays / 2;
        adjustments.add('Lluvia ligera prevista: ajuste menor');
      }

      // Humidity adjustment for humidity-loving plants
      if (species.humidityLoving && weather.current.humidity < 40) {
        adjustedDays *= 0.8;
        adjustments.add('Humedad baja: regar mas seguido');
      }
    }

    // Indoor adjustments
    if (environment == PlantEnvironment.indoor && weather != null) {
      // In winter (cold outside), indoor heating dries plants
      final avgTemp = weather.avgMaxTempNextDays(3);
      if (avgTemp < 10) {
        adjustedDays *= 0.9; // Slightly more frequent due to heating
        adjustments.add('Calefaccion interior: regar un poco mas');
      }
    }

    // Clamp to reasonable range
    final finalDays = adjustedDays.round().clamp(1, 60);

    if (adjustments.isEmpty) {
      reason = environment == PlantEnvironment.indoor
          ? 'Frecuencia para interior'
          : 'Frecuencia para exterior';
    }

    return WateringRecommendation(
      frequencyDays: finalDays,
      baseFrequencyDays: baseDays,
      reason: reason,
      adjustments: adjustments,
      nextWatering: DateTime.now().add(Duration(days: finalDays)),
      sunlightHoursMin: species.sunlightHoursMin,
      sunlightHoursMax: species.sunlightHoursMax,
      sunlightLevel: species.sunlightLevel,
    );
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

  const WateringRecommendation({
    required this.frequencyDays,
    required this.baseFrequencyDays,
    required this.reason,
    required this.adjustments,
    required this.nextWatering,
    required this.sunlightHoursMin,
    required this.sunlightHoursMax,
    required this.sunlightLevel,
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
}
