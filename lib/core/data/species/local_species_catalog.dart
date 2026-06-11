import 'plant_species.dart';

/// Local catalog of common plant species as fallback
/// Used when API is unavailable or for quick offline access
///
/// wateringMultiplier in growthPhases:
///   < 1.0 = water MORE often (seedlings need frequent small waterings)
///   = 1.0 = base frequency
///   > 1.0 = water LESS often (mature, established plants)
class LocalSpeciesCatalog {
  static const List<PlantSpecies> species = [
    // ========================================================================
    // POPULAR INDOOR PLANTS
    // ========================================================================
    PlantSpecies(
      id: 'local_monstera', commonName: 'Monstera', scientificName: 'Monstera deliciosa', category: 'indoor',
      wateringFrequencyIndoor: 7, wateringFrequencyOutdoor: 5,
      sunlightHoursMin: 4, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.medium,
      humidityLoving: true, minTemperature: 10, maxTemperature: 32,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 4, wateringMultiplier: 0.7, description: 'Esqueje o planta muy joven, mantener humedo'),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 18, wateringMultiplier: 0.85, description: 'Crecimiento activo, hojas sin agujeros'),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Hojas fenestradas, crecimiento estable'),
      ],
    ),
    PlantSpecies(
      id: 'local_pothos', commonName: 'Pothos', scientificName: 'Epipremnum aureum', category: 'indoor',
      wateringFrequencyIndoor: 7, wateringFrequencyOutdoor: 5,
      sunlightHoursMin: 2, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.low,
      droughtTolerant: true, minTemperature: 10,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 2, wateringMultiplier: 0.75),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 8, wateringMultiplier: 0.9),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_snake_plant', commonName: 'Lengua de suegra', scientificName: 'Sansevieria trifasciata', category: 'indoor',
      wateringFrequencyIndoor: 14, wateringFrequencyOutdoor: 10,
      sunlightHoursMin: 2, sunlightHoursMax: 8, sunlightLevel: SunlightLevel.low,
      droughtTolerant: true,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 3, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 12, wateringMultiplier: 0.9),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_peace_lily', commonName: 'Espatifilo', scientificName: 'Spathiphyllum wallisii', category: 'indoor',
      wateringFrequencyIndoor: 5, wateringFrequencyOutdoor: 4,
      sunlightHoursMin: 2, sunlightHoursMax: 5, sunlightLevel: SunlightLevel.low,
      humidityLoving: true, minTemperature: 12,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 3, wateringMultiplier: 0.7),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 12, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_ficus', commonName: 'Ficus elastica', scientificName: 'Ficus elastica', category: 'indoor',
      wateringFrequencyIndoor: 7, wateringFrequencyOutdoor: 5,
      sunlightHoursMin: 4, sunlightHoursMax: 8, sunlightLevel: SunlightLevel.high,
      minTemperature: 10,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 6, wateringMultiplier: 0.7),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 24, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_spider_plant', commonName: 'Cinta', scientificName: 'Chlorophytum comosum', category: 'indoor',
      wateringFrequencyIndoor: 7, wateringFrequencyOutdoor: 5,
      sunlightHoursMin: 3, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.medium,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 2, wateringMultiplier: 0.75),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 6, wateringMultiplier: 0.9),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_calathea', commonName: 'Calathea', scientificName: 'Calathea orbifolia', category: 'indoor',
      wateringFrequencyIndoor: 5, wateringFrequencyOutdoor: 3,
      sunlightHoursMin: 2, sunlightHoursMax: 5, sunlightLevel: SunlightLevel.low,
      humidityLoving: true, minTemperature: 15,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 3, wateringMultiplier: 0.7),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 12, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_philodendron', commonName: 'Filodendro', scientificName: 'Philodendron hederaceum', category: 'indoor',
      wateringFrequencyIndoor: 7, wateringFrequencyOutdoor: 5,
      sunlightHoursMin: 3, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.medium,
      humidityLoving: true, minTemperature: 12,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 3, wateringMultiplier: 0.75),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 12, wateringMultiplier: 0.9),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_zz_plant', commonName: 'Planta ZZ', scientificName: 'Zamioculcas zamiifolia', category: 'indoor',
      wateringFrequencyIndoor: 14, wateringFrequencyOutdoor: 10,
      sunlightHoursMin: 2, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.low,
      droughtTolerant: true, minTemperature: 10,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 6, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 18, wateringMultiplier: 0.9),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_orchid', commonName: 'Orquidea', scientificName: 'Phalaenopsis spp.', category: 'indoor',
      wateringFrequencyIndoor: 7, wateringFrequencyOutdoor: 5,
      sunlightHoursMin: 3, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.medium,
      humidityLoving: true, minTemperature: 15,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 12, wateringMultiplier: 0.8, description: 'Planta joven, raices en desarrollo'),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 24, wateringMultiplier: 0.9, description: 'Crece hojas, prepara floracion'),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Florece ciclicamente'),
      ],
    ),
    PlantSpecies(
      id: 'local_fiddle_leaf', commonName: 'Ficus lyrata', scientificName: 'Ficus lyrata', category: 'indoor',
      wateringFrequencyIndoor: 7, wateringFrequencyOutdoor: 5,
      sunlightHoursMin: 5, sunlightHoursMax: 8, sunlightLevel: SunlightLevel.high,
      humidityLoving: true, minTemperature: 12,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 6, wateringMultiplier: 0.7),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 24, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_rubber_plant', commonName: 'Arbol del caucho', scientificName: 'Ficus elastica', category: 'indoor',
      wateringFrequencyIndoor: 7, wateringFrequencyOutdoor: 5,
      sunlightHoursMin: 4, sunlightHoursMax: 8, sunlightLevel: SunlightLevel.high,
      minTemperature: 10,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 6, wateringMultiplier: 0.75),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 24, wateringMultiplier: 0.9),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_boston_fern', commonName: 'Helecho de Boston', scientificName: 'Nephrolepis exaltata', category: 'indoor',
      wateringFrequencyIndoor: 4, wateringFrequencyOutdoor: 3,
      sunlightHoursMin: 2, sunlightHoursMax: 5, sunlightLevel: SunlightLevel.low,
      humidityLoving: true, minTemperature: 10,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 3, wateringMultiplier: 0.65),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 8, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_dracaena', commonName: 'Dracena', scientificName: 'Dracaena marginata', category: 'indoor',
      wateringFrequencyIndoor: 10, wateringFrequencyOutdoor: 7,
      sunlightHoursMin: 3, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.medium,
      droughtTolerant: true, minTemperature: 10,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 6, wateringMultiplier: 0.75),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 24, wateringMultiplier: 0.9),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_croton', commonName: 'Croton', scientificName: 'Codiaeum variegatum', category: 'indoor',
      wateringFrequencyIndoor: 5, wateringFrequencyOutdoor: 4,
      sunlightHoursMin: 5, sunlightHoursMax: 8, sunlightLevel: SunlightLevel.high,
      humidityLoving: true, minTemperature: 15,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 4, wateringMultiplier: 0.7),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 12, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_pilea', commonName: 'Pilea', scientificName: 'Pilea peperomioides', category: 'indoor',
      wateringFrequencyIndoor: 7, wateringFrequencyOutdoor: 5,
      sunlightHoursMin: 4, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.medium,
      minTemperature: 10,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 2, wateringMultiplier: 0.75),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 6, wateringMultiplier: 0.9),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_bamboo', commonName: 'Bambu de la suerte', scientificName: 'Dracaena sanderiana', category: 'indoor',
      wateringFrequencyIndoor: 7, wateringFrequencyOutdoor: 5,
      sunlightHoursMin: 2, sunlightHoursMax: 5, sunlightLevel: SunlightLevel.low,
      minTemperature: 10,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 3, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 6, wateringMultiplier: 0.9),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_anthurium', commonName: 'Anturio', scientificName: 'Anthurium andraeanum', category: 'indoor',
      wateringFrequencyIndoor: 5, wateringFrequencyOutdoor: 4,
      sunlightHoursMin: 3, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.medium,
      humidityLoving: true, minTemperature: 15,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 4, wateringMultiplier: 0.7),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 12, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_bonsai', commonName: 'Bonsai (Ficus)', scientificName: 'Ficus retusa', category: 'indoor',
      wateringFrequencyIndoor: 4, wateringFrequencyOutdoor: 3,
      sunlightHoursMin: 4, sunlightHoursMax: 8, sunlightLevel: SunlightLevel.high,
      humidityLoving: true, minTemperature: 10,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 12, wateringMultiplier: 0.6, description: 'Pre-bonsai, necesita riego frecuente'),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 60, wateringMultiplier: 0.8, description: 'Formacion, podas frecuentes'),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Mantenimiento'),
      ],
    ),

    // === NEW INDOOR PLANTS ===
    PlantSpecies(
      id: 'local_alocasia', commonName: 'Alocasia', scientificName: 'Alocasia amazonica', category: 'indoor',
      wateringFrequencyIndoor: 5, wateringFrequencyOutdoor: 3,
      sunlightHoursMin: 4, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.medium,
      humidityLoving: true, minTemperature: 15,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 4, wateringMultiplier: 0.65, description: 'Bulbo recien plantado, riego moderado'),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 12, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_maranta', commonName: 'Maranta (planta de la oracion)', scientificName: 'Maranta leuconeura', category: 'indoor',
      wateringFrequencyIndoor: 5, wateringFrequencyOutdoor: 3,
      sunlightHoursMin: 2, sunlightHoursMax: 5, sunlightLevel: SunlightLevel.low,
      humidityLoving: true, minTemperature: 15,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 3, wateringMultiplier: 0.7),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 10, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_peperomia', commonName: 'Peperomia', scientificName: 'Peperomia obtusifolia', category: 'indoor',
      wateringFrequencyIndoor: 10, wateringFrequencyOutdoor: 7,
      sunlightHoursMin: 3, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.medium,
      minTemperature: 12,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 3, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 8, wateringMultiplier: 0.9),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_dieffenbachia', commonName: 'Diefembaquia', scientificName: 'Dieffenbachia seguine', category: 'indoor',
      wateringFrequencyIndoor: 5, wateringFrequencyOutdoor: 4,
      sunlightHoursMin: 3, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.medium,
      humidityLoving: true, minTemperature: 12,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 4, wateringMultiplier: 0.7),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 12, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_schefflera', commonName: 'Cheflera', scientificName: 'Schefflera arboricola', category: 'indoor',
      wateringFrequencyIndoor: 7, wateringFrequencyOutdoor: 5,
      sunlightHoursMin: 4, sunlightHoursMax: 7, sunlightLevel: SunlightLevel.medium,
      minTemperature: 10,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 4, wateringMultiplier: 0.75),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 18, wateringMultiplier: 0.9),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_begonia', commonName: 'Begonia', scientificName: 'Begonia rex', category: 'indoor',
      wateringFrequencyIndoor: 5, wateringFrequencyOutdoor: 3,
      sunlightHoursMin: 3, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.medium,
      humidityLoving: true, minTemperature: 12,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 3, wateringMultiplier: 0.7),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 8, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_string_of_pearls', commonName: 'Collar de perlas', scientificName: 'Senecio rowleyanus', category: 'succulent',
      wateringFrequencyIndoor: 14, wateringFrequencyOutdoor: 10,
      sunlightHoursMin: 4, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.high,
      droughtTolerant: true, minTemperature: 8,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 3, wateringMultiplier: 0.75),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 8, wateringMultiplier: 0.9),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_tradescantia', commonName: 'Tradescantia', scientificName: 'Tradescantia zebrina', category: 'indoor',
      wateringFrequencyIndoor: 5, wateringFrequencyOutdoor: 3,
      sunlightHoursMin: 4, sunlightHoursMax: 7, sunlightLevel: SunlightLevel.medium,
      minTemperature: 8,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.7),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 4, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_hoya', commonName: 'Hoya', scientificName: 'Hoya carnosa', category: 'indoor',
      wateringFrequencyIndoor: 10, wateringFrequencyOutdoor: 7,
      sunlightHoursMin: 4, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.medium,
      minTemperature: 10,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 6, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 24, wateringMultiplier: 0.9),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Florece en racimos, no mover'),
      ],
    ),
    PlantSpecies(
      id: 'local_ctenanthe', commonName: 'Ctenanthe', scientificName: 'Ctenanthe burle-marxii', category: 'indoor',
      wateringFrequencyIndoor: 5, wateringFrequencyOutdoor: 3,
      sunlightHoursMin: 2, sunlightHoursMax: 5, sunlightLevel: SunlightLevel.low,
      humidityLoving: true, minTemperature: 15,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 3, wateringMultiplier: 0.7),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 10, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_yucca', commonName: 'Yuca', scientificName: 'Yucca elephantipes', category: 'indoor',
      wateringFrequencyIndoor: 10, wateringFrequencyOutdoor: 7,
      sunlightHoursMin: 5, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.high,
      droughtTolerant: true, minTemperature: 0,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 6, wateringMultiplier: 0.75),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 24, wateringMultiplier: 0.9),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_strelitzia', commonName: 'Ave del paraiso', scientificName: 'Strelitzia reginae', category: 'indoor',
      wateringFrequencyIndoor: 7, wateringFrequencyOutdoor: 5,
      sunlightHoursMin: 5, sunlightHoursMax: 8, sunlightLevel: SunlightLevel.high,
      minTemperature: 8,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 12, wateringMultiplier: 0.7, description: 'Crecimiento lento, no florece aun'),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 36, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Florece a partir de 4-5 años'),
      ],
    ),
    PlantSpecies(
      id: 'local_aspidistra', commonName: 'Aspidistra', scientificName: 'Aspidistra elatior', category: 'indoor',
      wateringFrequencyIndoor: 10, wateringFrequencyOutdoor: 7,
      sunlightHoursMin: 1, sunlightHoursMax: 4, sunlightLevel: SunlightLevel.low,
      droughtTolerant: true, minTemperature: 0,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 6, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 24, wateringMultiplier: 0.9),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_kentia', commonName: 'Kentia', scientificName: 'Howea forsteriana', category: 'indoor',
      wateringFrequencyIndoor: 7, wateringFrequencyOutdoor: 5,
      sunlightHoursMin: 3, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.medium,
      minTemperature: 8,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 12, wateringMultiplier: 0.7),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 36, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),

    // ========================================================================
    // SUCCULENTS & CACTI
    // ========================================================================
    PlantSpecies(
      id: 'local_aloe', commonName: 'Aloe vera', scientificName: 'Aloe barbadensis', category: 'succulent', isEdible: true,
      wateringFrequencyIndoor: 14, wateringFrequencyOutdoor: 10,
      sunlightHoursMin: 6, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.fullSun,
      droughtTolerant: true,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 4, wateringMultiplier: 0.75),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 12, wateringMultiplier: 0.9),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_cactus', commonName: 'Cactus', scientificName: 'Cactaceae', category: 'succulent',
      wateringFrequencyIndoor: 21, wateringFrequencyOutdoor: 14,
      sunlightHoursMin: 6, sunlightHoursMax: 12, sunlightLevel: SunlightLevel.fullSun,
      droughtTolerant: true, minTemperature: 0, maxTemperature: 45,
      hotWeatherMultiplier: 0.8, coldWeatherMultiplier: 2.0, rainReductionDays: 5,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 12, wateringMultiplier: 0.7, description: 'Riego mas frecuente pero poco'),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 36, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_echeveria', commonName: 'Echeveria', scientificName: 'Echeveria elegans', category: 'succulent',
      wateringFrequencyIndoor: 14, wateringFrequencyOutdoor: 10,
      sunlightHoursMin: 6, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.fullSun,
      droughtTolerant: true,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 4, wateringMultiplier: 0.75),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 8, wateringMultiplier: 0.9),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_jade', commonName: 'Planta de jade', scientificName: 'Crassula ovata', category: 'succulent',
      wateringFrequencyIndoor: 14, wateringFrequencyOutdoor: 10,
      sunlightHoursMin: 4, sunlightHoursMax: 8, sunlightLevel: SunlightLevel.high,
      droughtTolerant: true,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 6, wateringMultiplier: 0.75),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 24, wateringMultiplier: 0.9),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_succulent', commonName: 'Suculenta (Sempervivum)', scientificName: 'Sempervivum spp.', category: 'succulent',
      wateringFrequencyIndoor: 14, wateringFrequencyOutdoor: 10,
      sunlightHoursMin: 5, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.fullSun,
      droughtTolerant: true, minTemperature: -10,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 3, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 6, wateringMultiplier: 0.9),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_haworthia', commonName: 'Haworthia', scientificName: 'Haworthia fasciata', category: 'succulent',
      wateringFrequencyIndoor: 14, wateringFrequencyOutdoor: 10,
      sunlightHoursMin: 3, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.medium,
      droughtTolerant: true,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 4, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 12, wateringMultiplier: 0.9),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_lithops', commonName: 'Piedras vivas', scientificName: 'Lithops spp.', category: 'succulent',
      wateringFrequencyIndoor: 30, wateringFrequencyOutdoor: 21,
      sunlightHoursMin: 5, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.fullSun,
      droughtTolerant: true, maxTemperature: 40,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 6, wateringMultiplier: 0.7, description: 'Riego con cuidado, muy sensibles'),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 18, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'No regar durante muda de hojas'),
      ],
    ),
    PlantSpecies(
      id: 'local_sedum', commonName: 'Sedum', scientificName: 'Sedum morganianum', category: 'succulent',
      wateringFrequencyIndoor: 14, wateringFrequencyOutdoor: 10,
      sunlightHoursMin: 5, sunlightHoursMax: 8, sunlightLevel: SunlightLevel.high,
      droughtTolerant: true,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 3, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 8, wateringMultiplier: 0.9),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),

    // ========================================================================
    // OUTDOOR / GARDEN - EDIBLE PLANTS
    // ========================================================================
    PlantSpecies(
      id: 'local_tomato', commonName: 'Tomate', scientificName: 'Solanum lycopersicum', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 3, wateringFrequencyOutdoor: 2,
      sunlightHoursMin: 6, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.fullSun,
      minTemperature: 10, hotWeatherMultiplier: 0.5, rainReductionDays: 1,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.6, description: 'Plantula fragil, riego suave frecuente'),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 2, wateringMultiplier: 0.75, description: 'Crecimiento vegetativo rapido'),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Fructificacion, riego profundo'),
      ],
      varieties: [
        PlantSpecies(
          id: 'local_tomato_cherry', parentId: 'local_tomato', category: 'outdoor', isEdible: true,
          commonName: 'Tomate cherry', scientificName: 'Solanum lycopersicum var. cerasiforme',
          description: 'Frutos pequeños, muy productivo. Ideal macetas y balcones. Mas resistente a enfermedades.',
          wateringFrequencyIndoor: 3, wateringFrequencyOutdoor: 2,
          sunlightHoursMin: 6, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.fullSun,
          minTemperature: 10, maxTemperature: 38, hotWeatherMultiplier: 0.5,
          growthPhases: [
            GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.6),
            GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 1, wateringMultiplier: 0.75),
            GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
          ],
        ),
        PlantSpecies(
          id: 'local_tomato_raf', parentId: 'local_tomato', category: 'outdoor', isEdible: true,
          commonName: 'Tomate RAF', scientificName: 'Solanum lycopersicum (RAF)',
          description: 'Variedad española gourmet. Sabor intenso. Necesita suelos algo salinos. Mas exigente en riego y nutricion.',
          wateringFrequencyIndoor: 2, wateringFrequencyOutdoor: 1,
          sunlightHoursMin: 6, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.fullSun,
          minTemperature: 12, maxTemperature: 32, hotWeatherMultiplier: 0.5,
          growthPhases: [
            GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.55),
            GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 2, wateringMultiplier: 0.7),
            GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
          ],
        ),
      ],
    ),
    PlantSpecies(
      id: 'local_basil', commonName: 'Albahaca', scientificName: 'Ocimum basilicum', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 3, wateringFrequencyOutdoor: 2,
      sunlightHoursMin: 6, sunlightHoursMax: 8, sunlightLevel: SunlightLevel.fullSun,
      minTemperature: 10,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.6, description: 'Mantener sustrato humedo sin encharcar'),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 1, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Cosechar antes de que florezca'),
      ],
    ),
    PlantSpecies(
      id: 'local_rosemary', commonName: 'Romero', scientificName: 'Rosmarinus officinalis', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 10, wateringFrequencyOutdoor: 7,
      sunlightHoursMin: 6, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.fullSun,
      droughtTolerant: true, minTemperature: -5,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 3, wateringMultiplier: 0.7),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 12, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_mint', commonName: 'Menta', scientificName: 'Mentha spicata', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 3, wateringFrequencyOutdoor: 2,
      sunlightHoursMin: 4, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.medium,
      humidityLoving: true, minTemperature: -5,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.65),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 2, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_pepper', commonName: 'Pimiento', scientificName: 'Capsicum annuum', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 3, wateringFrequencyOutdoor: 2,
      sunlightHoursMin: 6, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.fullSun,
      minTemperature: 12, hotWeatherMultiplier: 0.5,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.6),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 2, wateringMultiplier: 0.75),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_strawberry', commonName: 'Fresa', scientificName: 'Fragaria x ananassa', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 3, wateringFrequencyOutdoor: 2,
      sunlightHoursMin: 6, sunlightHoursMax: 8, sunlightLevel: SunlightLevel.fullSun,
      minTemperature: -5,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 2, wateringMultiplier: 0.65, description: 'Estolones o plantula, mantener humedo'),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 3, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Mas agua durante fructificacion'),
      ],
    ),
    PlantSpecies(
      id: 'local_parsley', commonName: 'Perejil', scientificName: 'Petroselinum crispum', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 3, wateringFrequencyOutdoor: 2,
      sunlightHoursMin: 4, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.medium,
      minTemperature: -5,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.6, description: 'Germinacion lenta (2-4 semanas)'),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 2, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_lettuce', commonName: 'Lechuga', scientificName: 'Lactuca sativa', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 2, wateringFrequencyOutdoor: 2,
      sunlightHoursMin: 4, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.medium,
      minTemperature: 0, maxTemperature: 28,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.6),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 1, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Cosechar antes de que espigue'),
      ],
    ),

    // === NEW EDIBLE PLANTS ===
    PlantSpecies(
      id: 'local_cucumber', commonName: 'Pepino', scientificName: 'Cucumis sativus', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 2, wateringFrequencyOutdoor: 1,
      sunlightHoursMin: 6, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.fullSun,
      minTemperature: 15, humidityLoving: true, hotWeatherMultiplier: 0.5,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.6),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 1, wateringMultiplier: 0.75),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Mucha agua durante fructificacion'),
      ],
    ),
    PlantSpecies(
      id: 'local_zucchini', commonName: 'Calabacin', scientificName: 'Cucurbita pepo', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 2, wateringFrequencyOutdoor: 1,
      sunlightHoursMin: 6, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.fullSun,
      minTemperature: 12, hotWeatherMultiplier: 0.5,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.6),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 1, wateringMultiplier: 0.7),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_eggplant', commonName: 'Berenjena', scientificName: 'Solanum melongena', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 2, wateringFrequencyOutdoor: 1,
      sunlightHoursMin: 6, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.fullSun,
      minTemperature: 15, hotWeatherMultiplier: 0.5,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.6),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 2, wateringMultiplier: 0.75),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_cilantro', commonName: 'Cilantro', scientificName: 'Coriandrum sativum', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 3, wateringFrequencyOutdoor: 2,
      sunlightHoursMin: 4, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.medium,
      maxTemperature: 28,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.6),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 1, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Se espiga rapido con calor'),
      ],
    ),
    PlantSpecies(
      id: 'local_thyme', commonName: 'Tomillo', scientificName: 'Thymus vulgaris', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 10, wateringFrequencyOutdoor: 7,
      sunlightHoursMin: 6, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.fullSun,
      droughtTolerant: true, minTemperature: -10,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 2, wateringMultiplier: 0.7),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 6, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_oregano', commonName: 'Oregano', scientificName: 'Origanum vulgare', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 7, wateringFrequencyOutdoor: 5,
      sunlightHoursMin: 6, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.fullSun,
      droughtTolerant: true, minTemperature: -10,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 2, wateringMultiplier: 0.7),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 4, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_chives', commonName: 'Cebollino', scientificName: 'Allium schoenoprasum', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 4, wateringFrequencyOutdoor: 3,
      sunlightHoursMin: 4, sunlightHoursMax: 8, sunlightLevel: SunlightLevel.medium,
      minTemperature: -15,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 2, wateringMultiplier: 0.65),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 4, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_spinach', commonName: 'Espinaca', scientificName: 'Spinacia oleracea', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 2, wateringFrequencyOutdoor: 2,
      sunlightHoursMin: 3, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.medium,
      minTemperature: -5, maxTemperature: 25,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.6),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 1, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Cosechar antes de que espigue'),
      ],
    ),
    PlantSpecies(
      id: 'local_pea', commonName: 'Guisante', scientificName: 'Pisum sativum', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 3, wateringFrequencyOutdoor: 2,
      sunlightHoursMin: 5, sunlightHoursMax: 8, sunlightLevel: SunlightLevel.fullSun,
      minTemperature: -2, maxTemperature: 25,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.65),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 1, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Mas agua durante floracion'),
      ],
    ),
    PlantSpecies(
      id: 'local_garlic', commonName: 'Ajo', scientificName: 'Allium sativum', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 7, wateringFrequencyOutdoor: 5,
      sunlightHoursMin: 6, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.fullSun,
      minTemperature: -10,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 2, wateringMultiplier: 0.7),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 4, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, wateringMultiplier: 1.2, description: 'Reducir riego antes de cosechar'),
      ],
    ),
    PlantSpecies(
      id: 'local_onion', commonName: 'Cebolla', scientificName: 'Allium cepa', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 4, wateringFrequencyOutdoor: 3,
      sunlightHoursMin: 6, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.fullSun,
      minTemperature: -5,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 2, wateringMultiplier: 0.65),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 3, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, wateringMultiplier: 1.3, description: 'Dejar de regar 2 semanas antes de cosechar'),
      ],
    ),
    PlantSpecies(
      id: 'local_carrot', commonName: 'Zanahoria', scientificName: 'Daucus carota', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 3, wateringFrequencyOutdoor: 2,
      sunlightHoursMin: 5, sunlightHoursMax: 8, sunlightLevel: SunlightLevel.fullSun,
      minTemperature: -5,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.6, description: 'Mantener humedo para germinacion'),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 2, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),

    // ========================================================================
    // OUTDOOR / GARDEN - ORNAMENTAL
    // ========================================================================
    PlantSpecies(
      id: 'local_lavender', commonName: 'Lavanda', scientificName: 'Lavandula angustifolia', category: 'outdoor',
      wateringFrequencyIndoor: 10, wateringFrequencyOutdoor: 7,
      sunlightHoursMin: 6, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.fullSun,
      droughtTolerant: true, minTemperature: -10,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 3, wateringMultiplier: 0.7),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 12, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_rose', commonName: 'Rosa', scientificName: 'Rosa spp.', category: 'outdoor',
      wateringFrequencyIndoor: 5, wateringFrequencyOutdoor: 3,
      sunlightHoursMin: 6, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.fullSun,
      minTemperature: -10,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 3, wateringMultiplier: 0.65),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 12, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Mas agua durante floracion'),
      ],
    ),
    PlantSpecies(
      id: 'local_geranium', commonName: 'Geranio', scientificName: 'Pelargonium spp.', category: 'outdoor',
      wateringFrequencyIndoor: 5, wateringFrequencyOutdoor: 3,
      sunlightHoursMin: 6, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.fullSun,
      minTemperature: 2,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 2, wateringMultiplier: 0.7),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 4, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_hydrangea', commonName: 'Hortensia', scientificName: 'Hydrangea macrophylla', category: 'outdoor',
      wateringFrequencyIndoor: 4, wateringFrequencyOutdoor: 2,
      sunlightHoursMin: 3, sunlightHoursMax: 6, sunlightLevel: SunlightLevel.medium,
      humidityLoving: true, minTemperature: -10,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 6, wateringMultiplier: 0.6),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 18, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Mucha agua en verano'),
      ],
    ),
    PlantSpecies(
      id: 'local_jasmine', commonName: 'Jazmin', scientificName: 'Jasminum officinale', category: 'outdoor',
      wateringFrequencyIndoor: 5, wateringFrequencyOutdoor: 3,
      sunlightHoursMin: 5, sunlightHoursMax: 8, sunlightLevel: SunlightLevel.high,
      minTemperature: -5,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 4, wateringMultiplier: 0.7),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 18, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0),
      ],
    ),
    PlantSpecies(
      id: 'local_bougainvillea', commonName: 'Buganvilla', scientificName: 'Bougainvillea glabra', category: 'outdoor',
      wateringFrequencyIndoor: 7, wateringFrequencyOutdoor: 5,
      sunlightHoursMin: 6, sunlightHoursMax: 12, sunlightLevel: SunlightLevel.fullSun,
      droughtTolerant: true, minTemperature: 2,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 6, wateringMultiplier: 0.7),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 18, wateringMultiplier: 0.85),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Algo de sequia estimula floracion'),
      ],
    ),
    PlantSpecies(
      id: 'local_olive', commonName: 'Olivo', scientificName: 'Olea europaea', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 10, wateringFrequencyOutdoor: 7,
      sunlightHoursMin: 6, sunlightHoursMax: 12, sunlightLevel: SunlightLevel.fullSun,
      droughtTolerant: true, minTemperature: -8, maxTemperature: 42,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 12, wateringMultiplier: 0.65),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 48, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Arbol establecido, muy resistente'),
      ],
    ),
    PlantSpecies(
      id: 'local_lemon', commonName: 'Limonero', scientificName: 'Citrus x limon', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 5, wateringFrequencyOutdoor: 3,
      sunlightHoursMin: 6, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.fullSun,
      minTemperature: 3, maxTemperature: 38,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 12, wateringMultiplier: 0.6, description: 'Esqueje o plantula, riego frecuente'),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 36, wateringMultiplier: 0.8),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Mas agua en fructificacion'),
      ],
    ),
    PlantSpecies(
      id: 'local_avocado', commonName: 'Aguacate', scientificName: 'Persea americana', category: 'outdoor', isEdible: true,
      wateringFrequencyIndoor: 5, wateringFrequencyOutdoor: 3,
      sunlightHoursMin: 6, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.fullSun,
      humidityLoving: true, maxTemperature: 38,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 6, wateringMultiplier: 0.6, description: 'Hueso o plantula, mantener humedo'),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 36, wateringMultiplier: 0.75),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Da fruto a partir de 5+ años'),
      ],
    ),
    PlantSpecies(
      id: 'local_sunflower', commonName: 'Girasol', scientificName: 'Helianthus annuus', category: 'outdoor',
      wateringFrequencyIndoor: 3, wateringFrequencyOutdoor: 2,
      sunlightHoursMin: 6, sunlightHoursMax: 12, sunlightLevel: SunlightLevel.fullSun,
      minTemperature: 8, maxTemperature: 38,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.6),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 2, wateringMultiplier: 0.75),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Planta anual, florece y muere'),
      ],
    ),

    // ========================================================================
    // CANNABIS - Parent species with varieties
    // ========================================================================
    PlantSpecies(
      id: 'local_cannabis', commonName: 'Cannabis', scientificName: 'Cannabis sativa', category: 'cannabis',
      description: 'Selecciona una variedad para obtener cuidados especificos',
      wateringFrequencyIndoor: 3, wateringFrequencyOutdoor: 2,
      sunlightHoursMin: 8, sunlightHoursMax: 12, sunlightLevel: SunlightLevel.fullSun,
      minTemperature: 15, maxTemperature: 30,
      humidityLoving: true, hotWeatherMultiplier: 0.5,
      growthPhases: [
        GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.5, description: 'Germinacion, riego muy suave'),
        GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 2, wateringMultiplier: 0.7, description: 'Vegetativo: riego creciente'),
        GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Floracion: maximo consumo de agua'),
      ],
      varieties: [
        // --- INDICA DOMINANT ---
        PlantSpecies(
          id: 'local_cannabis_critical', parentId: 'local_cannabis', category: 'cannabis',
          commonName: 'Critical', scientificName: 'Cannabis sativa (Critical)',
          description: 'Indica dominante. Alta produccion, floracion rapida (7-8 semanas). Resistente a moho.',
          wateringFrequencyIndoor: 2, wateringFrequencyOutdoor: 2,
          sunlightHoursMin: 10, sunlightHoursMax: 12, sunlightLevel: SunlightLevel.fullSun,
          minTemperature: 18, maxTemperature: 28, humidityLoving: true, hotWeatherMultiplier: 0.5,
          growthPhases: [GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.5), GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 1, wateringMultiplier: 0.7, description: 'Vegetativo 4-5 semanas'), GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Floracion 7-8 semanas')],
        ),
        PlantSpecies(
          id: 'local_cannabis_og_kush', parentId: 'local_cannabis', category: 'cannabis',
          commonName: 'OG Kush', scientificName: 'Cannabis sativa (OG Kush)',
          description: 'Hibrido indica. Aroma a pino/limon. Floracion 8-9 semanas. Control de humedad en floracion.',
          wateringFrequencyIndoor: 2, wateringFrequencyOutdoor: 2,
          sunlightHoursMin: 10, sunlightHoursMax: 12, sunlightLevel: SunlightLevel.fullSun,
          minTemperature: 20, maxTemperature: 28, humidityLoving: true, hotWeatherMultiplier: 0.5,
          growthPhases: [GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.5), GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 2, wateringMultiplier: 0.7, description: 'Vegetativo 5-6 semanas'), GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Floracion 8-9 semanas')],
        ),
        PlantSpecies(
          id: 'local_cannabis_northern_lights', parentId: 'local_cannabis', category: 'cannabis',
          commonName: 'Northern Lights', scientificName: 'Cannabis indica (Northern Lights)',
          description: 'Indica pura clasica. Muy resistente, ideal principiantes. Floracion 7-8 semanas. Poco olor.',
          wateringFrequencyIndoor: 3, wateringFrequencyOutdoor: 2,
          sunlightHoursMin: 8, sunlightHoursMax: 12, sunlightLevel: SunlightLevel.fullSun,
          minTemperature: 16, maxTemperature: 28, humidityLoving: true, hotWeatherMultiplier: 0.5,
          growthPhases: [GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.5), GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 1, wateringMultiplier: 0.7, description: 'Vegetativo 4-5 semanas'), GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Floracion 7-8 semanas')],
        ),
        PlantSpecies(
          id: 'local_cannabis_gorilla_glue', parentId: 'local_cannabis', category: 'cannabis',
          commonName: 'Gorilla Glue (GG4)', scientificName: 'Cannabis sativa (Gorilla Glue #4)',
          description: 'Hibrido equilibrado, muy resinoso. Alta potencia. Floracion 8-9 semanas. Necesita soporte.',
          wateringFrequencyIndoor: 2, wateringFrequencyOutdoor: 2,
          sunlightHoursMin: 10, sunlightHoursMax: 12, sunlightLevel: SunlightLevel.fullSun,
          minTemperature: 18, maxTemperature: 30, humidityLoving: true, hotWeatherMultiplier: 0.5,
          growthPhases: [GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.5), GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 2, wateringMultiplier: 0.7, description: 'Vegetativo 5-6 semanas'), GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Floracion 8-9 semanas')],
        ),
        PlantSpecies(
          id: 'local_cannabis_blue_cheese', parentId: 'local_cannabis', category: 'cannabis',
          commonName: 'Blue Cheese', scientificName: 'Cannabis indica (Blue Cheese)',
          description: 'Indica dominante (80/20). Aroma queso/berry. Floracion 8 semanas. Compacta, ideal espacios reducidos.',
          wateringFrequencyIndoor: 3, wateringFrequencyOutdoor: 2,
          sunlightHoursMin: 8, sunlightHoursMax: 12, sunlightLevel: SunlightLevel.fullSun,
          minTemperature: 16, maxTemperature: 26, humidityLoving: true, hotWeatherMultiplier: 0.6,
          growthPhases: [GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.5), GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 1, wateringMultiplier: 0.7, description: 'Vegetativo 4-5 semanas'), GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Floracion 7-8 semanas')],
        ),
        PlantSpecies(
          id: 'local_cannabis_granddaddy_purple', parentId: 'local_cannabis', category: 'cannabis',
          commonName: 'Granddaddy Purple', scientificName: 'Cannabis indica (Granddaddy Purple)',
          description: 'Indica pura, colores purpura. Floracion 8-9 semanas. Noches frias para color.',
          wateringFrequencyIndoor: 3, wateringFrequencyOutdoor: 2,
          sunlightHoursMin: 8, sunlightHoursMax: 10, sunlightLevel: SunlightLevel.fullSun,
          minTemperature: 14, maxTemperature: 26, humidityLoving: true, hotWeatherMultiplier: 0.6,
          growthPhases: [GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.5), GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 2, wateringMultiplier: 0.7, description: 'Vegetativo 5-6 semanas'), GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Floracion 8-9 semanas')],
        ),
        // --- SATIVA DOMINANT ---
        PlantSpecies(
          id: 'local_cannabis_amnesia_haze', parentId: 'local_cannabis', category: 'cannabis',
          commonName: 'Amnesia Haze', scientificName: 'Cannabis sativa (Amnesia Haze)',
          description: 'Sativa dominante (80/20). Floracion larga 10-12 semanas. Crece mucho, necesita poda apical.',
          wateringFrequencyIndoor: 2, wateringFrequencyOutdoor: 2,
          sunlightHoursMin: 10, sunlightHoursMax: 14, sunlightLevel: SunlightLevel.fullSun,
          minTemperature: 20, maxTemperature: 30, humidityLoving: true, hotWeatherMultiplier: 0.5,
          growthPhases: [GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.5), GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 2, wateringMultiplier: 0.7, description: 'Vegetativo 6-8 semanas'), GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Floracion 10-12 semanas')],
        ),
        PlantSpecies(
          id: 'local_cannabis_jack_herer', parentId: 'local_cannabis', category: 'cannabis',
          commonName: 'Jack Herer', scientificName: 'Cannabis sativa (Jack Herer)',
          description: 'Sativa dominante clasica. Aroma a pino/especias. Floracion 9-10 semanas.',
          wateringFrequencyIndoor: 2, wateringFrequencyOutdoor: 2,
          sunlightHoursMin: 10, sunlightHoursMax: 14, sunlightLevel: SunlightLevel.fullSun,
          minTemperature: 18, maxTemperature: 30, humidityLoving: true, hotWeatherMultiplier: 0.5,
          growthPhases: [GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.5), GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 2, wateringMultiplier: 0.7, description: 'Vegetativo 5-7 semanas'), GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Floracion 9-10 semanas')],
        ),
        PlantSpecies(
          id: 'local_cannabis_sour_diesel', parentId: 'local_cannabis', category: 'cannabis',
          commonName: 'Sour Diesel', scientificName: 'Cannabis sativa (Sour Diesel)',
          description: 'Sativa 90/10. Aroma diesel/citrico. Floracion 10-11 semanas. Crece mucho, ideal exterior.',
          wateringFrequencyIndoor: 2, wateringFrequencyOutdoor: 2,
          sunlightHoursMin: 10, sunlightHoursMax: 14, sunlightLevel: SunlightLevel.fullSun,
          minTemperature: 20, maxTemperature: 32, humidityLoving: true, hotWeatherMultiplier: 0.5,
          growthPhases: [GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.5), GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 2, wateringMultiplier: 0.7, description: 'Vegetativo 6-8 semanas'), GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Floracion 10-11 semanas')],
        ),
        // --- HYBRID 50/50 ---
        PlantSpecies(
          id: 'local_cannabis_white_widow', parentId: 'local_cannabis', category: 'cannabis',
          commonName: 'White Widow', scientificName: 'Cannabis sativa (White Widow)',
          description: 'Hibrido equilibrado 50/50. Muy resinosa. Floracion 8-9 semanas. Resistente al frio.',
          wateringFrequencyIndoor: 3, wateringFrequencyOutdoor: 2,
          sunlightHoursMin: 8, sunlightHoursMax: 12, sunlightLevel: SunlightLevel.fullSun,
          minTemperature: 14, maxTemperature: 28, humidityLoving: true, hotWeatherMultiplier: 0.5,
          growthPhases: [GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.5), GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 2, wateringMultiplier: 0.7, description: 'Vegetativo 5-6 semanas'), GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Floracion 8-9 semanas')],
        ),
        PlantSpecies(
          id: 'local_cannabis_gelato', parentId: 'local_cannabis', category: 'cannabis',
          commonName: 'Gelato', scientificName: 'Cannabis sativa (Gelato)',
          description: 'Hibrido ligeramente indica. Aroma dulce/helado. Floracion 8-9 semanas. Colores purpura.',
          wateringFrequencyIndoor: 2, wateringFrequencyOutdoor: 2,
          sunlightHoursMin: 10, sunlightHoursMax: 12, sunlightLevel: SunlightLevel.fullSun,
          minTemperature: 18, maxTemperature: 28, humidityLoving: true, hotWeatherMultiplier: 0.5,
          growthPhases: [GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.5), GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 2, wateringMultiplier: 0.7, description: 'Vegetativo 5-6 semanas'), GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Floracion 8-9 semanas')],
        ),
        // --- AUTOFLOWERING ---
        PlantSpecies(
          id: 'local_cannabis_auto_northern', parentId: 'local_cannabis', category: 'cannabis',
          commonName: 'Northern Lights Auto', scientificName: 'Cannabis sativa (NL Auto)',
          description: 'Autofloreciente. Ciclo completo 8-10 semanas. No depende del fotoperiodo. Ideal principiantes.',
          wateringFrequencyIndoor: 3, wateringFrequencyOutdoor: 2,
          sunlightHoursMin: 12, sunlightHoursMax: 20, sunlightLevel: SunlightLevel.fullSun,
          minTemperature: 16, maxTemperature: 28, humidityLoving: true, hotWeatherMultiplier: 0.5,
          growthPhases: [GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.5, description: 'Germinacion 1-2 semanas'), GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 1, wateringMultiplier: 0.7, description: 'Vegetativo 2-3 semanas'), GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Floracion 5-6 semanas')],
        ),
        PlantSpecies(
          id: 'local_cannabis_auto_critical', parentId: 'local_cannabis', category: 'cannabis',
          commonName: 'Critical Auto', scientificName: 'Cannabis sativa (Critical Auto)',
          description: 'Autofloreciente. Ciclo 9-10 semanas. Alta produccion para auto. Compacta.',
          wateringFrequencyIndoor: 3, wateringFrequencyOutdoor: 2,
          sunlightHoursMin: 12, sunlightHoursMax: 20, sunlightLevel: SunlightLevel.fullSun,
          minTemperature: 16, maxTemperature: 28, humidityLoving: true, hotWeatherMultiplier: 0.5,
          growthPhases: [GrowthPhaseInfo(stage: GrowthStage.seedling, durationMonths: 1, wateringMultiplier: 0.5), GrowthPhaseInfo(stage: GrowthStage.juvenile, durationMonths: 1, wateringMultiplier: 0.7, description: 'Vegetativo 2-3 semanas'), GrowthPhaseInfo(stage: GrowthStage.adult, durationMonths: 0, description: 'Floracion 6-7 semanas')],
        ),
      ],
    ),
  ];
}
