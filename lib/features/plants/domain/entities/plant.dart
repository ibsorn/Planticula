import 'package:equatable/equatable.dart';
import 'package:planticula/core/data/species/plant_species.dart';

/// Entidad Plant - Representa una planta del usuario
///
/// Campos principales:
/// - id: UUID generado por Supabase
/// - name: Nombre de la especie/planta (del catálogo o ingresado manualmente)
/// - customName: Nombre personalizado que el usuario le asigna (ej: "Mi tomatera favorita")
/// - scientificName: Nombre científico (opcional)
/// - speciesId: ID de la especie (local_ o api_)
/// - imageUrl: URL de la imagen en Storage (opcional)
/// - location: Ubicación en casa (ej: "Sala", "Terraza")
/// - notes: Notas adicionales
/// - wateringFrequency: Días entre riegos (calculado automaticamente)
/// - lastWatered: Última fecha de riego
/// - nextWatering: Próxima fecha calculada
/// - acquiredDate: Fecha de adquisición
/// - environment: Interior o exterior
/// - growthStage: Fase de crecimiento actual
/// - speciesCategory: Categoría de la especie (indoor, outdoor, succulent, cannabis)
/// - latitude/longitude: Ubicación GPS del usuario
/// - createdAt/updatedAt: Timestamps automáticos
/// - lastTransplanted: Last time the user registered a pot transplant
class Plant extends Equatable {
  final String id;
  final String name;
  final String? customName;
  final String? scientificName;
  final String? speciesId;
  final String? speciesCategory; // Cached from species: indoor, outdoor, succulent, cannabis
  final String? imageUrl;
  final String? location;
  final String? notes;
  final int? wateringFrequency; // Días entre riegos (auto-calculado)
  final DateTime? lastWatered;
  final DateTime? nextWatering;
  final DateTime? acquiredDate;
  final String? environment; // 'indoor' or 'outdoor'
  final String? growthStage; // 'seedling', 'juvenile', 'adult'
  final String? potSize; // 'extra_small', 'small', 'medium', 'large', 'extra_large'
  final DateTime? lastTransplanted; // Last registered transplant date
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Plant({
    required this.id,
    required this.name,
    this.customName,
    this.scientificName,
    this.speciesId,
    this.speciesCategory,
    this.imageUrl,
    this.location,
    this.notes,
    this.wateringFrequency,
    this.lastWatered,
    this.nextWatering,
    this.acquiredDate,
    this.environment,
    this.growthStage,
    this.potSize,
    this.lastTransplanted,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  /// Crea una copia con algunos campos modificados
  Plant copyWith({
    String? id,
    String? name,
    String? customName,
    String? scientificName,
    String? speciesId,
    String? speciesCategory,
    String? imageUrl,
    String? location,
    String? notes,
    int? wateringFrequency,
    DateTime? lastWatered,
    DateTime? nextWatering,
    DateTime? acquiredDate,
    String? environment,
    String? growthStage,
    String? potSize,
    DateTime? lastTransplanted,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Plant(
      id: id ?? this.id,
      name: name ?? this.name,
      customName: customName ?? this.customName,
      scientificName: scientificName ?? this.scientificName,
      speciesId: speciesId ?? this.speciesId,
      speciesCategory: speciesCategory ?? this.speciesCategory,
      imageUrl: imageUrl ?? this.imageUrl,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      wateringFrequency: wateringFrequency ?? this.wateringFrequency,
      lastWatered: lastWatered ?? this.lastWatered,
      nextWatering: nextWatering ?? this.nextWatering,
      acquiredDate: acquiredDate ?? this.acquiredDate,
      environment: environment ?? this.environment,
      growthStage: growthStage ?? this.growthStage,
      potSize: potSize ?? this.potSize,
      lastTransplanted: lastTransplanted ?? this.lastTransplanted,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Nombre a mostrar: customName si existe, sino name
  String get displayName => customName?.isNotEmpty == true ? customName! : name;

  /// Indica si tiene un nombre personalizado
  bool get hasCustomName => customName != null && customName!.isNotEmpty;

  /// Calcula si la planta necesita riego
  bool get needsWatering {
    if (nextWatering == null) return false;
    return DateTime.now().isAfter(nextWatering!) ||
        DateTime.now().isAtSameMomentAs(nextWatering!);
  }

  /// Días restantes hasta el próximo riego (puede ser negativo si está atrasado)
  int? get daysUntilWatering {
    if (nextWatering == null) return null;
    return nextWatering!.difference(DateTime.now()).inDays;
  }

  /// Indica si tiene configurado recordatorio de riego
  bool get hasWateringReminder => wateringFrequency != null && wateringFrequency! > 0;

  /// Parsed environment enum
  PlantEnvironment get plantEnvironment =>
      environment == 'outdoor' ? PlantEnvironment.outdoor : PlantEnvironment.indoor;

  /// Parsed growth stage enum
  GrowthStage get plantGrowthStage => GrowthStage.fromString(growthStage ?? 'adult');

  /// Parsed pot size enum
  PotSize get plantPotSize => PotSize.fromString(potSize ?? 'medium');

  /// Whether plant is outdoors
  bool get isOutdoor => environment == 'outdoor';

  @override
  List<Object?> get props => [
        id,
        name,
        customName,
        scientificName,
        speciesId,
        speciesCategory,
        imageUrl,
        location,
        notes,
        wateringFrequency,
        lastWatered,
        nextWatering,
        acquiredDate,
        environment,
        growthStage,
        potSize,
        lastTransplanted,
        latitude,
        longitude,
        createdAt,
        updatedAt,
      ];
}
