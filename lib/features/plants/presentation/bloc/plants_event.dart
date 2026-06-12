part of 'plants_bloc.dart';

abstract class PlantsEvent extends Equatable {
  const PlantsEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar todas las plantas del usuario
class PlantsLoadRequested extends PlantsEvent {}

/// Cargar plantas que necesitan riego
class PlantsLoadNeedingWaterRequested extends PlantsEvent {}

/// Buscar plantas por nombre
class PlantsSearchRequested extends PlantsEvent {
  final String query;

  const PlantsSearchRequested(this.query);

  @override
  List<Object?> get props => [query];
}

/// Crear una nueva planta
class PlantCreateRequested extends PlantsEvent {
  final String name;
  final String? scientificName;
  final String? speciesId;
  final String? speciesCategory;
  final String? imageUrl;
  final String? location;
  final String? notes;
  final int? wateringFrequency;
  final DateTime? acquiredDate;
  final String? environment;
  final String? growthStage;
  final String? potSize;
  final double? latitude;
  final double? longitude;

  const PlantCreateRequested({
    required this.name,
    this.scientificName,
    this.speciesId,
    this.speciesCategory,
    this.imageUrl,
    this.location,
    this.notes,
    this.wateringFrequency,
    this.acquiredDate,
    this.environment,
    this.growthStage,
    this.potSize,
    this.latitude,
    this.longitude,
  });

  @override
  List<Object?> get props => [
        name,
        scientificName,
        speciesId,
        speciesCategory,
        imageUrl,
        location,
        notes,
        wateringFrequency,
        acquiredDate,
        environment,
        growthStage,
        potSize,
        latitude,
        longitude,
      ];
}

/// Actualizar una planta existente
class PlantUpdateRequested extends PlantsEvent {
  final Plant plant;

  const PlantUpdateRequested(this.plant);

  @override
  List<Object?> get props => [plant];
}

/// Eliminar una planta
class PlantDeleteRequested extends PlantsEvent {
  final String id;

  const PlantDeleteRequested(this.id);

  @override
  List<Object?> get props => [id];
}

/// Marcar planta como regada
class PlantWaterRequested extends PlantsEvent {
  final String id;

  const PlantWaterRequested(this.id);

  @override
  List<Object?> get props => [id];
}

/// Registrar trasplante a una maceta nueva
class PlantTransplantRequested extends PlantsEvent {
  final String id;
  final String newPotSize; // PotSize.dbValue

  const PlantTransplantRequested({required this.id, required this.newPotSize});

  @override
  List<Object?> get props => [id, newPotSize];
}

/// Seleccionar una planta (para ver detalle)
class PlantSelectRequested extends PlantsEvent {
  final String id;

  const PlantSelectRequested(this.id);

  @override
  List<Object?> get props => [id];
}

/// Limpiar errores
class PlantsClearError extends PlantsEvent {}
