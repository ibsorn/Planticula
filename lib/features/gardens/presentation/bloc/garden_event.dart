part of 'garden_bloc.dart';

abstract class GardenEvent extends Equatable {
  const GardenEvent();
  @override
  List<Object?> get props => [];
}

/// Carga todos los jardines y, si no hay ninguno, crea el jardín por defecto.
class GardensLoadRequested extends GardenEvent {}

/// Carga los grupos de un jardín específico.
class GardenGroupsLoadRequested extends GardenEvent {
  final String gardenId;
  const GardenGroupsLoadRequested(this.gardenId);
  @override
  List<Object?> get props => [gardenId];
}

/// Crea un nuevo jardín.
class GardenCreateRequested extends GardenEvent {
  final String name;
  final String? description;
  final String icon;
  final String color;
  final GardenType type;

  const GardenCreateRequested({
    required this.name,
    this.description,
    this.icon = 'garden',
    this.color = '#4CAF50',
    this.type = GardenType.personal,
  });

  @override
  List<Object?> get props => [name, description, icon, color, type];
}

/// Actualiza un jardín existente.
class GardenUpdateRequested extends GardenEvent {
  final Garden garden;
  const GardenUpdateRequested(this.garden);
  @override
  List<Object?> get props => [garden];
}

/// Elimina un jardín (no permite borrar el jardín por defecto).
class GardenDeleteRequested extends GardenEvent {
  final String id;
  const GardenDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

/// Selecciona un jardín como el jardín activo en la UI.
class GardenSelectRequested extends GardenEvent {
  final Garden? garden; // null = desseleccionar
  const GardenSelectRequested(this.garden);
  @override
  List<Object?> get props => [garden];
}

/// Crea un nuevo grupo dentro del jardín activo.
class GardenGroupCreateRequested extends GardenEvent {
  final String gardenId;
  final String name;
  final String? description;
  final String? icon;
  final String? color;

  const GardenGroupCreateRequested({
    required this.gardenId,
    required this.name,
    this.description,
    this.icon,
    this.color,
  });

  @override
  List<Object?> get props => [gardenId, name, description, icon, color];
}

/// Actualiza un grupo existente.
class GardenGroupUpdateRequested extends GardenEvent {
  final GardenGroup group;
  const GardenGroupUpdateRequested(this.group);
  @override
  List<Object?> get props => [group];
}

/// Elimina un grupo.
class GardenGroupDeleteRequested extends GardenEvent {
  final String id;
  const GardenGroupDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

/// Limpia el mensaje de error.
class GardenClearError extends GardenEvent {}
