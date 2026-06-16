// Value objects de plantas (Dart puro, sin dependencias de framework):
// entorno, etapa de crecimiento, nivel de luz y tamaño de maceta.
//
// Re-exportados desde plant_species.dart para conservar los imports existentes.

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

/// Etapas de crecimiento de planta - sistema expandido de 5 fases
/// Cada etapa incluye metadatos enriquecidos para UI y recomendaciones
enum GrowthStage {
  /// Germinación: recién salió de la semilla, cotiledones visibles
  germination(
    displayName: 'Germinación',
    shortDescription: 'Recién salió de la semilla',
    icon: '🌱',
    order: 0,
    wateringFrequencyMultiplier: 0.7,
    lightNeedsMultiplier: 0.6,
    typicalTechniques: [],
  ),

  /// Plántula: pequeña, 2-6 hojas verdaderas, estableciéndose
  seedling(
    displayName: 'Plántula',
    shortDescription: 'Pequeña, pocos centímetros',
    icon: '🌿',
    order: 1,
    wateringFrequencyMultiplier: 0.8,
    lightNeedsMultiplier: 0.8,
    typicalTechniques: [],
  ),

  /// Desarrollo vegetativo: crecimiento activo, técnicas aplicables
  development(
    displayName: 'Desarrollo',
    shortDescription: 'Creciendo activamente',
    icon: '🪴',
    order: 2,
    wateringFrequencyMultiplier: 1.0,
    lightNeedsMultiplier: 1.0,
    typicalTechniques: ['LST', 'Topping', 'FIM', 'Poda de formación'],
  ),

  /// Madura: tamaño final establecido, sin crecimiento nuevo significativo
  mature(
    displayName: 'Madura',
    shortDescription: 'Tamaño final, estable',
    icon: '🌳',
    order: 3,
    wateringFrequencyMultiplier: 0.9,
    lightNeedsMultiplier: 0.9,
    typicalTechniques: ['Poda de mantenimiento', 'Propagación'],
  ),

  /// Floración/Fructificación: fase reproductiva
  flowering(
    displayName: 'Flor/Fruto',
    shortDescription: 'Con flores o frutos',
    icon: '🌸',
    order: 4,
    wateringFrequencyMultiplier: 1.1,
    lightNeedsMultiplier: 1.0,
    typicalTechniques: ['Poda de sacar tallos', 'Soporte de frutos'],
  );

  final String displayName;
  final String shortDescription;
  final String icon;
  final int order;
  final double wateringFrequencyMultiplier;
  final double lightNeedsMultiplier;
  final List<String> typicalTechniques;

  const GrowthStage({
    required this.displayName,
    required this.shortDescription,
    required this.icon,
    required this.order,
    required this.wateringFrequencyMultiplier,
    required this.lightNeedsMultiplier,
    required this.typicalTechniques,
  });

  /// Nombre en inglés para la API (backward compatibility)
  String get apiValue {
    switch (this) {
      case GrowthStage.germination:
        return 'germination';
      case GrowthStage.seedling:
        return 'seedling';
      case GrowthStage.development:
        return 'development';
      case GrowthStage.mature:
        return 'mature';
      case GrowthStage.flowering:
        return 'flowering';
    }
  }

  /// Descripción extendida para tooltips y ayuda
  String get extendedDescription {
    switch (this) {
      case GrowthStage.germination:
        return 'La planta acaba de germinar. Cotiledones visibles, sistema radicular incipiente. Riego muy ligero, evita encharcamiento.';
      case GrowthStage.seedling:
        return 'Plántula establecida con 2-6 hojas verdaderas. Fase vulnerable, requiere cuidado moderado.';
      case GrowthStage.development:
        return 'Crecimiento vegetativo activo. Momento ideal para técnicas de entrenamiento (LST, topping) si aplica.';
      case GrowthStage.mature:
        return 'Planta alcanzó tamaño final. Crecimiento lateral mínimo. Mantenimiento y cuidados regulares.';
      case GrowthStage.flowering:
        return 'Fase reproductiva activa. Puede requerir más nutrientes de floración y soporte estructural.';
    }
  }

  /// Etapa siguiente en el ciclo (null si es la última)
  GrowthStage? get nextStage {
    final stages = GrowthStage.values;
    final nextIndex = order + 1;
    if (nextIndex < stages.length) {
      return stages.firstWhere((s) => s.order == nextIndex);
    }
    return null;
  }

  /// Etapa anterior en el ciclo (null si es la primera)
  GrowthStage? get previousStage {
    final prevIndex = order - 1;
    if (prevIndex >= 0) {
      return GrowthStage.values.firstWhere((s) => s.order == prevIndex);
    }
    return null;
  }

  /// Si esta etapa aplica técnicas avanzadas
  bool get supportsAdvancedTechniques => typicalTechniques.isNotEmpty;

  /// Técnicas recomendadas formateadas para UI
  String get techniquesDescription {
    if (typicalTechniques.isEmpty) return '';
    return typicalTechniques.join(' · ');
  }

  /// Parse desde string (case insensitive, soporta valores antiguos)
  static GrowthStage fromString(String value) {
    final normalized = value.toLowerCase().trim();

    // Nuevos valores
    switch (normalized) {
      case 'germination':
      case 'germinacion':
        return GrowthStage.germination;
      case 'seedling':
      case 'plantula':
      case 'plántula':
        return GrowthStage.seedling;
      case 'development':
      case 'desarrollo':
      case 'vegetative':
      case 'vegetativo':
        return GrowthStage.development;
      case 'mature':
      case 'madura':
      case 'adult':
      case 'adulta':
        return GrowthStage.mature;
      case 'flowering':
      case 'floracion':
      case 'floración':
      case 'fruit':
      case 'fruto':
        return GrowthStage.flowering;
    }

    // Legacy mappings (valores antiguos)
    switch (normalized) {
      case 'juvenile':
      case 'juvenil':
        return GrowthStage.seedling; // Juvenil → Plántula
      default:
        return GrowthStage.development; // Default seguro
    }
  }

  /// Todas las etapas ordenadas
  static List<GrowthStage> get orderedStages =>
      GrowthStage.values.toList()..sort((a, b) => a.order.compareTo(b.order));
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
