import 'package:planticula/core/data/species/plant_species.dart';
import 'package:planticula/core/services/transplant_calculator.dart';
import 'package:planticula/core/services/watering_calculator.dart';
import 'package:planticula/core/services/weather_service.dart';

/// Orquesta las reglas de negocio de recomendaciones de una planta.
///
/// Centraliza decisiones que antes estaban duplicadas en las pantallas, como
/// "el clima solo afecta a plantas de exterior". Las pantallas reciben este
/// servicio inyectado y no necesitan conocer los calculadores subyacentes.
class PlantRecommendationService {
  /// Calcula la recomendación de riego.
  ///
  /// El [weather] solo se tiene en cuenta para plantas de exterior; para
  /// interior se ignora deliberadamente (regla de negocio centralizada aquí).
  WateringRecommendation watering({
    required PlantSpecies species,
    required PlantEnvironment environment,
    required GrowthStage growthStage,
    required PotSize potSize,
    WeatherData? weather,
  }) {
    return WateringCalculator.calculate(
      species: species,
      environment: environment,
      growthStage: growthStage,
      potSize: potSize,
      weather: environment == PlantEnvironment.outdoor ? weather : null,
    );
  }

  /// Evalúa si la planta necesita trasplante.
  TransplantRecommendation transplant({
    required PlantSpecies species,
    required PotSize currentPotSize,
    required GrowthStage currentStage,
    DateTime? plantedDate,
    DateTime? lastTransplanted,
  }) {
    return TransplantCalculator.evaluate(
      species: species,
      currentPotSize: currentPotSize,
      currentStage: currentStage,
      plantedDate: plantedDate,
      lastTransplanted: lastTransplanted,
    );
  }
}
