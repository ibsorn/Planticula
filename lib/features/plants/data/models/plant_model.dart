import 'package:planticula/features/plants/domain/entities/plant.dart' as domain;

/// Modelo de datos para Plant - Mapeo con tablas de Supabase
class PlantModel extends domain.Plant {
  const PlantModel({
    required super.id,
    required super.name,
    super.scientificName,
    super.speciesId,
    super.speciesCategory,
    super.imageUrl,
    super.location,
    super.notes,
    super.wateringFrequency,
    super.lastWatered,
    super.nextWatering,
    super.acquiredDate,
    super.environment,
    super.growthStage,
    super.latitude,
    super.longitude,
    super.createdAt,
    super.updatedAt,
  });

  /// Crea un modelo desde JSON de Supabase
  factory PlantModel.fromJson(Map<String, dynamic> json) {
    return PlantModel(
      id: json['id'] as String,
      name: json['name'] as String,
      scientificName: json['scientific_name'] as String?,
      speciesId: json['species_id'] as String?,
      speciesCategory: json['species_category'] as String?,
      imageUrl: json['image_url'] as String?,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      wateringFrequency: json['watering_frequency'] as int?,
      lastWatered: json['last_watered'] != null
          ? DateTime.parse(json['last_watered'] as String)
          : null,
      nextWatering: json['next_watering'] != null
          ? DateTime.parse(json['next_watering'] as String)
          : null,
      acquiredDate: json['acquired_date'] != null
          ? DateTime.parse(json['acquired_date'] as String)
          : null,
      environment: json['environment'] as String?,
      growthStage: json['growth_stage'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convierte a JSON para enviar a Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'scientific_name': scientificName,
      'species_id': speciesId,
      'species_category': speciesCategory,
      'image_url': imageUrl,
      'location': location,
      'notes': notes,
      'watering_frequency': wateringFrequency,
      'last_watered': lastWatered?.toIso8601String(),
      'next_watering': nextWatering?.toIso8601String(),
      'acquired_date': acquiredDate?.toIso8601String(),
      'environment': environment,
      'growth_stage': growthStage,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Crea un modelo desde la entidad de dominio
  factory PlantModel.fromDomain(domain.Plant plant) {
    return PlantModel(
      id: plant.id,
      name: plant.name,
      scientificName: plant.scientificName,
      speciesId: plant.speciesId,
      speciesCategory: plant.speciesCategory,
      imageUrl: plant.imageUrl,
      location: plant.location,
      notes: plant.notes,
      wateringFrequency: plant.wateringFrequency,
      lastWatered: plant.lastWatered,
      nextWatering: plant.nextWatering,
      acquiredDate: plant.acquiredDate,
      environment: plant.environment,
      growthStage: plant.growthStage,
      latitude: plant.latitude,
      longitude: plant.longitude,
      createdAt: plant.createdAt,
      updatedAt: plant.updatedAt,
    );
  }

  /// Crea una copia con modificaciones
  PlantModel copyWithModel({
    String? id,
    String? name,
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
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlantModel(
      id: id ?? this.id,
      name: name ?? this.name,
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
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Crea modelo para nueva planta (sin ID, timestamps se generan en DB)
  factory PlantModel.create({
    required String name,
    String? scientificName,
    String? speciesId,
    String? speciesCategory,
    String? imageUrl,
    String? location,
    String? notes,
    int? wateringFrequency,
    DateTime? acquiredDate,
    String? environment,
    String? growthStage,
    double? latitude,
    double? longitude,
  }) {
    return PlantModel(
      id: '', // Se generará en Supabase
      name: name,
      scientificName: scientificName,
      speciesId: speciesId,
      speciesCategory: speciesCategory,
      imageUrl: imageUrl,
      location: location,
      notes: notes,
      wateringFrequency: wateringFrequency,
      acquiredDate: acquiredDate,
      environment: environment,
      growthStage: growthStage,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
