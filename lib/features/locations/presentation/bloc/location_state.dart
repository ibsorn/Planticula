part of 'location_bloc.dart';

enum LocationStatus { initial, loading, loaded, empty, error }
enum LocationOpStatus { initial, loading, success, error }

class LocationState extends Equatable {
  final LocationStatus status;
  final LocationOpStatus opStatus;

  /// Organización activa (multi-tenant). Null hasta que se carga.
  final Organization? organization;

  /// Organizaciones del usuario (para el selector del drawer).
  final List<Organization> organizations;

  /// Lista plana de todos los nodos de la organización activa.
  final List<Location> locations;

  /// Nodo activo en la UI (null = "Todas").
  final Location? selectedLocation;

  final String? errorMessage;

  const LocationState({
    this.status = LocationStatus.initial,
    this.opStatus = LocationOpStatus.initial,
    this.organization,
    this.organizations = const [],
    this.locations = const [],
    this.selectedLocation,
    this.errorMessage,
  });

  bool get isLoading   => status == LocationStatus.loading;
  bool get isEmpty     => status == LocationStatus.empty;
  bool get hasError    => status == LocationStatus.error;
  bool get isOpLoading => opStatus == LocationOpStatus.loading;
  bool get isOpSuccess => opStatus == LocationOpStatus.success;

  /// Nodos raíz (viveros / sites), ordenados por sort_order.
  List<Location> get roots =>
      locations.where((l) => l.parentId == null).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  /// Hijos directos de un nodo, ordenados por sort_order.
  List<Location> childrenOf(String parentId) =>
      locations.where((l) => l.parentId == parentId).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  /// IDs del nodo dado y de todos sus descendientes (para filtrar plantas).
  List<String> descendantIdsOf(String locationId) {
    final result = <String>[locationId];
    final queue = <String>[locationId];
    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      for (final child in locations.where((l) => l.parentId == current)) {
        result.add(child.id);
        queue.add(child.id);
      }
    }
    return result;
  }

  LocationState copyWith({
    LocationStatus? status,
    LocationOpStatus? opStatus,
    Organization? organization,
    List<Organization>? organizations,
    List<Location>? locations,
    Location? selectedLocation,
    bool clearSelectedLocation = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LocationState(
      status: status ?? this.status,
      opStatus: opStatus ?? this.opStatus,
      organization: organization ?? this.organization,
      organizations: organizations ?? this.organizations,
      locations: locations ?? this.locations,
      selectedLocation:
          clearSelectedLocation ? null : (selectedLocation ?? this.selectedLocation),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status, opStatus, organization, organizations, locations,
        selectedLocation, errorMessage,
      ];
}
