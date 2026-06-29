part of 'location_bloc.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();
  @override
  List<Object?> get props => [];
}

/// Garantiza la organización por defecto y carga su árbol de localizaciones.
class LocationsLoadRequested extends LocationEvent {}

/// Selecciona un nodo como localización activa (null = "Todas").
class LocationSelectRequested extends LocationEvent {
  final Location? location;
  const LocationSelectRequested(this.location);
  @override
  List<Object?> get props => [location];
}

/// Crea un nuevo nodo de localización.
class LocationCreateRequested extends LocationEvent {
  final String? parentId;
  final LocationKind kind;
  final String name;
  final String? description;
  final String icon;
  final String color;

  const LocationCreateRequested({
    this.parentId,
    required this.kind,
    required this.name,
    this.description,
    this.icon = 'garden',
    this.color = '#4CAF50',
  });

  @override
  List<Object?> get props => [parentId, kind, name, description, icon, color];
}

/// Actualiza un nodo existente.
class LocationUpdateRequested extends LocationEvent {
  final Location location;
  const LocationUpdateRequested(this.location);
  @override
  List<Object?> get props => [location];
}

/// Elimina un nodo (sus hijos se borran en cascada).
class LocationDeleteRequested extends LocationEvent {
  final String id;
  const LocationDeleteRequested(this.id);
  @override
  List<Object?> get props => [id];
}

/// Limpia el mensaje de error.
class LocationClearError extends LocationEvent {}
