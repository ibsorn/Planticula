import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:planticula/features/locations/domain/entities/location.dart';
import 'package:planticula/features/locations/domain/entities/organization.dart';
import 'package:planticula/features/locations/domain/repositories/location_repository.dart';
import 'package:planticula/features/locations/domain/repositories/organization_repository.dart';

part 'location_event.dart';
part 'location_state.dart';

/// Bloc global del árbol de localización y la organización activa.
///
/// Se provee a nivel raíz en main.dart; acceder siempre con
/// `context.read<LocationBloc>()`.
class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final OrganizationRepository _orgRepo;
  final LocationRepository _locationRepo;

  LocationBloc(this._orgRepo, this._locationRepo)
      : super(const LocationState()) {
    on<LocationsLoadRequested>(_onLoad);
    on<LocationSelectRequested>(_onSelect);
    on<LocationCreateRequested>(_onCreate);
    on<LocationUpdateRequested>(_onUpdate);
    on<LocationDeleteRequested>(_onDelete);
    on<LocationClearError>(_onClearError);
  }

  Future<void> _onLoad(
    LocationsLoadRequested event,
    Emitter<LocationState> emit,
  ) async {
    emit(state.copyWith(status: LocationStatus.loading));

    // 1. Garantizar la organización por defecto.
    final orgResult = await _orgRepo.getOrCreateDefaultOrganization();
    final org = orgResult.data;
    if (org == null) {
      emit(state.copyWith(
        status: LocationStatus.error,
        errorMessage: orgResult.errorMessage ?? 'No se pudo cargar la organización',
      ));
      return;
    }

    // 2. Cargar el árbol de localizaciones de esa organización.
    final result = await _locationRepo.getLocations(org.id);
    result.when(
      success: (locations) => emit(state.copyWith(
        status: locations.isEmpty ? LocationStatus.empty : LocationStatus.loaded,
        organization: org,
        organizations: state.organizations.isEmpty ? [org] : state.organizations,
        locations: locations,
      )),
      failure: (msg, _, __) => emit(state.copyWith(
        status: LocationStatus.error,
        errorMessage: msg,
      )),
    );
  }

  void _onSelect(LocationSelectRequested event, Emitter<LocationState> emit) {
    emit(state.copyWith(
      selectedLocation: event.location,
      clearSelectedLocation: event.location == null,
    ));
  }

  Future<void> _onCreate(
    LocationCreateRequested event,
    Emitter<LocationState> emit,
  ) async {
    final org = state.organization;
    if (org == null) return;
    emit(state.copyWith(opStatus: LocationOpStatus.loading));
    final result = await _locationRepo.createLocation(
      organizationId: org.id,
      parentId: event.parentId,
      kind: event.kind,
      name: event.name,
      description: event.description,
      icon: event.icon,
      color: event.color,
    );
    result.when(
      success: (location) => emit(state.copyWith(
        locations: [...state.locations, location],
        status: LocationStatus.loaded,
        opStatus: LocationOpStatus.success,
      )),
      failure: (msg, _, __) => emit(state.copyWith(
        opStatus: LocationOpStatus.error,
        errorMessage: msg,
      )),
    );
  }

  Future<void> _onUpdate(
    LocationUpdateRequested event,
    Emitter<LocationState> emit,
  ) async {
    emit(state.copyWith(opStatus: LocationOpStatus.loading));
    final result = await _locationRepo.updateLocation(event.location);
    result.when(
      success: (updated) => emit(state.copyWith(
        locations:
            state.locations.map((l) => l.id == updated.id ? updated : l).toList(),
        selectedLocation:
            state.selectedLocation?.id == updated.id ? updated : state.selectedLocation,
        opStatus: LocationOpStatus.success,
      )),
      failure: (msg, _, __) => emit(state.copyWith(
        opStatus: LocationOpStatus.error,
        errorMessage: msg,
      )),
    );
  }

  Future<void> _onDelete(
    LocationDeleteRequested event,
    Emitter<LocationState> emit,
  ) async {
    emit(state.copyWith(opStatus: LocationOpStatus.loading));
    final result = await _locationRepo.deleteLocation(event.id);
    result.when(
      success: (_) {
        // Eliminar el nodo y sus descendientes del estado local.
        final descendants = state.descendantIdsOf(event.id).toSet();
        final remaining =
            state.locations.where((l) => !descendants.contains(l.id)).toList();
        emit(state.copyWith(
          locations: remaining,
          status: remaining.isEmpty ? LocationStatus.empty : LocationStatus.loaded,
          opStatus: LocationOpStatus.success,
          clearSelectedLocation:
              state.selectedLocation != null && descendants.contains(state.selectedLocation!.id),
        ));
      },
      failure: (msg, _, __) => emit(state.copyWith(
        opStatus: LocationOpStatus.error,
        errorMessage: msg,
      )),
    );
  }

  void _onClearError(LocationClearError event, Emitter<LocationState> emit) {
    emit(state.copyWith(clearError: true, opStatus: LocationOpStatus.initial));
  }
}
