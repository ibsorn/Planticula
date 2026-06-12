import 'package:flutter_test/flutter_test.dart';
import 'package:planticula/core/data/species/plant_species.dart';
import 'package:planticula/core/services/watering_calculator.dart';
import 'package:planticula/core/services/weather_service.dart';

/// Helper para crear WeatherData de prueba
WeatherData _makeWeather({
  double temp = 22,
  double humidity = 60,
  double precip = 0,
  int days = 3,
}) {
  final now = DateTime.now();
  final dailyForecasts = <DailyForecast>[];

  for (int i = 0; i < days; i++) {
    dailyForecasts.add(DailyForecast(
      date: now.add(Duration(days: i)),
      maxTemp: temp,
      minTemp: temp - 5,
      precipitationMm: precip,
      weatherCode: precip > 0 ? 61 : 0,
    ));
  }

  return WeatherData(
    current: CurrentWeather(
      temperature: temp,
      humidity: humidity,
      precipitationMm: precip > 0 ? precip : 0,
      weatherCode: precip > 0 ? 61 : 0,
    ),
    daily: dailyForecasts,
  );
}

void main() {
  group('WateringCalculator', () {
    const testSpecies = PlantSpecies(
      id: 'test',
      commonName: 'Test Plant',
      scientificName: 'Testus plantus',
      category: 'indoor',
      wateringFrequencyIndoor: 7,
      wateringFrequencyOutdoor: 5,
      sunlightHoursMin: 4,
      sunlightHoursMax: 8,
      sunlightLevel: SunlightLevel.medium,
      growthPhases: [
        GrowthPhaseInfo(
          stage: GrowthStage.seedling,
          durationMonths: 3,
          wateringMultiplier: 0.7,
        ),
        GrowthPhaseInfo(
          stage: GrowthStage.juvenile,
          durationMonths: 6,
          wateringMultiplier: 0.85,
        ),
        GrowthPhaseInfo(
          stage: GrowthStage.adult,
          durationMonths: 0,
        ),
      ],
    );

    test('base indoor species with wateringFrequencyIndoor: 7 returns frequency around 7', () {
      final result = WateringCalculator.calculate(
        species: testSpecies,
        environment: PlantEnvironment.indoor,
      );

      expect(result.baseFrequencyDays, equals(7));
      expect(result.frequencyDays, closeTo(7, 1));
    });

    test('seedling stage with wateringMultiplier: 0.7 has lower frequency days than adult', () {
      final seedlingResult = WateringCalculator.calculate(
        species: testSpecies,
        environment: PlantEnvironment.indoor,
        growthStage: GrowthStage.seedling,
      );

      final adultResult = WateringCalculator.calculate(
        species: testSpecies,
        environment: PlantEnvironment.indoor,
      );

      // Seedling has multiplier 0.7, so it should need watering more frequently (fewer days)
      expect(seedlingResult.frequencyDays, lessThan(adultResult.frequencyDays));
      expect(seedlingResult.frequencyDays, closeTo(5, 1)); // 7 * 0.7 = 4.9 ≈ 5
    });

    test('extraSmall pot increases frequency (lower days), large pot decreases frequency (higher days)', () {
      final extraSmallResult = WateringCalculator.calculate(
        species: testSpecies,
        environment: PlantEnvironment.indoor,
        potSize: PotSize.extraSmall,
      );

      final mediumResult = WateringCalculator.calculate(
        species: testSpecies,
        environment: PlantEnvironment.indoor,
      );

      final largeResult = WateringCalculator.calculate(
        species: testSpecies,
        environment: PlantEnvironment.indoor,
        potSize: PotSize.large,
      );

      // extraSmall multiplier is 0.6 → more frequent (lower days)
      // large multiplier is 1.3 → less frequent (higher days)
      expect(extraSmallResult.frequencyDays, lessThan(mediumResult.frequencyDays));
      expect(largeResult.frequencyDays, greaterThan(mediumResult.frequencyDays));
    });

    test('hot weather (temp > 30) decreases frequency days for outdoor plants', () {
      final hotWeather = _makeWeather(temp: 32);
      final normalWeather = _makeWeather();

      final hotResult = WateringCalculator.calculate(
        species: testSpecies,
        environment: PlantEnvironment.outdoor,
        weather: hotWeather,
      );

      final normalResult = WateringCalculator.calculate(
        species: testSpecies,
        environment: PlantEnvironment.outdoor,
        weather: normalWeather,
      );

      // Hot weather should trigger more frequent watering (fewer days)
      expect(hotResult.frequencyDays, lessThan(normalResult.frequencyDays));
      expect(hotResult.adjustments.any((a) => a.contains('Calor')), isTrue);
    });

    test('rain forecast increases frequency days (less frequent watering)', () {
      final rainyWeather = _makeWeather(precip: 10); // More than 5mm triggers adjustment
      final dryWeather = _makeWeather();

      final rainyResult = WateringCalculator.calculate(
        species: testSpecies,
        environment: PlantEnvironment.outdoor,
        weather: rainyWeather,
      );

      final dryResult = WateringCalculator.calculate(
        species: testSpecies,
        environment: PlantEnvironment.outdoor,
        weather: dryWeather,
      );

      // Rain should reduce watering frequency (higher days)
      expect(rainyResult.frequencyDays, greaterThan(dryResult.frequencyDays));
      expect(rainyResult.adjustments.any((a) => a.contains('Lluvia')), isTrue);
    });

    test('mlPerWatering is always positive', () {
      final result = WateringCalculator.calculate(
        species: testSpecies,
        environment: PlantEnvironment.indoor,
      );

      expect(result.waterMl, greaterThan(0));
    });

    test('waterMlRange is a non-empty string', () {
      final result = WateringCalculator.calculate(
        species: testSpecies,
        environment: PlantEnvironment.indoor,
      );

      expect(result.waterMlRange, isNotEmpty);
      expect(result.waterMlRange.length, greaterThan(3));
    });

    test('drought tolerant species gets less water', () {
      const droughtSpecies = PlantSpecies(
        id: 'drought',
        commonName: 'Drought Plant',
        scientificName: 'Droughtus plantus',
        category: 'succulent',
        wateringFrequencyIndoor: 14,
        wateringFrequencyOutdoor: 10,
        sunlightHoursMin: 6,
        sunlightHoursMax: 10,
        sunlightLevel: SunlightLevel.fullSun,
        growthPhases: [
          GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
        ],
        droughtTolerant: true,
      );

      final result = WateringCalculator.calculate(
        species: droughtSpecies,
        environment: PlantEnvironment.indoor,
      );

      // Drought tolerant plants get 70% of normal water
      // Medium pot base is 500ml, 70% = 350ml
      expect(result.waterMl, closeTo(350, 50));
    });

    test('humidity loving species gets more water', () {
      const humiditySpecies = PlantSpecies(
        id: 'humidity',
        commonName: 'Humidity Plant',
        scientificName: 'Humidus plantus',
        category: 'indoor',
        wateringFrequencyIndoor: 5,
        wateringFrequencyOutdoor: 3,
        sunlightHoursMin: 4,
        sunlightHoursMax: 8,
        sunlightLevel: SunlightLevel.medium,
        growthPhases: [
          GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
        ],
        humidityLoving: true,
      );

      final result = WateringCalculator.calculate(
        species: humiditySpecies,
        environment: PlantEnvironment.indoor,
      );

      // Humidity loving plants get 120% of normal water
      // Medium pot base is 500ml, 120% = 600ml
      expect(result.waterMl, closeTo(600, 50));
    });

    test('seedling gets ~40% of adult water amount', () {
      final seedlingResult = WateringCalculator.calculate(
        species: testSpecies,
        environment: PlantEnvironment.indoor,
        growthStage: GrowthStage.seedling,
      );

      final adultResult = WateringCalculator.calculate(
        species: testSpecies,
        environment: PlantEnvironment.indoor,
      );

      // Seedling gets 40% of adult water amount
      expect(seedlingResult.waterMl, closeTo(adultResult.waterMl * 0.4, 20));
    });

    test('juvenile gets ~70% of adult water amount', () {
      final juvenileResult = WateringCalculator.calculate(
        species: testSpecies,
        environment: PlantEnvironment.indoor,
        growthStage: GrowthStage.juvenile,
      );

      final adultResult = WateringCalculator.calculate(
        species: testSpecies,
        environment: PlantEnvironment.indoor,
      );

      // Juvenile gets 70% of adult water amount
      expect(juvenileResult.waterMl, closeTo(adultResult.waterMl * 0.7, 20));
    });

    test('cold weather (temp < 10) increases frequency days for outdoor plants', () {
      final coldWeather = _makeWeather(temp: 5);
      final normalWeather = _makeWeather();

      final coldResult = WateringCalculator.calculate(
        species: testSpecies,
        environment: PlantEnvironment.outdoor,
        weather: coldWeather,
      );

      final normalResult = WateringCalculator.calculate(
        species: testSpecies,
        environment: PlantEnvironment.outdoor,
        weather: normalWeather,
      );

      // Cold weather should reduce watering frequency (more days)
      expect(coldResult.frequencyDays, greaterThan(normalResult.frequencyDays));
      expect(coldResult.adjustments.any((a) => a.contains('Frio')), isTrue);
    });

    test('indoor plants in winter (cold outside) get slight frequency reduction', () {
      final coldOutsideWeather = _makeWeather(temp: 5);
      final normalWeather = _makeWeather();

      final coldResult = WateringCalculator.calculate(
        species: testSpecies,
        environment: PlantEnvironment.indoor,
        weather: coldOutsideWeather,
      );

      final normalResult = WateringCalculator.calculate(
        species: testSpecies,
        environment: PlantEnvironment.indoor,
        weather: normalWeather,
      );

      // Indoor heating in winter dries plants, so slightly more frequent watering
      expect(coldResult.frequencyDays, lessThan(normalResult.frequencyDays));
      expect(coldResult.adjustments.any((a) => a.contains('Calefaccion')), isTrue);
    });
  });
}
