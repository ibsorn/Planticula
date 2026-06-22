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
  final String? customName;
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
  final String? gardenId;
  final String? groupId;

  const PlantCreateRequested({
    required this.name,
    this.customName,
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
    this.gardenId,
    this.groupId,
  });

  @override
  List<Object?> get props => [
        name,
        customName,
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
        gardenId,
        groupId,
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

/// Marcar planta como regada en una fecha específica (para riegos pasados)
class PlantWaterOnDateRequested extends PlantsEvent {
  final String id;
  final int daysAgo; // 0 = hoy, 1 = ayer, 2 = anteayer, etc.

  const PlantWaterOnDateRequested({
    required this.id,
    required this.daysAgo,
  });

  @override
  List<Object?> get props => [id, daysAgo];
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

/// Borrar el último registro de riego (para corregir errores)
class PlantClearLastWateringRequested extends PlantsEvent {
  final String id;

  const PlantClearLastWateringRequested(this.id);

  @override
  List<Object?> get props => [id];
}

/// Cargar plantas filtradas por jardín
class PlantsFilterByGarden extends PlantsEvent {
  final String gardenId;
  const PlantsFilterByGarden(this.gardenId);
  @override
  List<Object?> get props => [gardenId];
}

/// Cargar plantas filtradas por grupo
class PlantsFilterByGroup extends PlantsEvent {
  final String groupId;
  const PlantsFilterByGroup(this.groupId);
  @override
  List<Object?> get props => [groupId];
}

/// Asignar una planta a un jardín (y opcionalmente a un grupo)
class PlantAssignToGardenRequested extends PlantsEvent {
  final String plantId;
  final String gardenId;
  final String? groupId;

  const PlantAssignToGardenRequested({
    required this.plantId,
    required this.gardenId,
    this.groupId,
  });

  @override
  List<Object?> get props => [plantId, gardenId, groupId];
}
