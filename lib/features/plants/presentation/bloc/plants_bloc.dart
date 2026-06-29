import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planticula/core/services/notification_service.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
import 'package:planticula/features/plants/domain/repositories/plants_repository.dart';

part 'plants_event.dart';
part 'plants_state.dart';

class PlantsBloc extends Bloc<PlantsEvent, PlantsState> {
  final PlantsRepository _repository;
  final NotificationService _notifications;

  PlantsBloc(this._repository, this._notifications) : super(const PlantsState()) {
    on<PlantsLoadRequested>(_onLoadRequested);
    on<PlantsLoadNeedingWaterRequested>(_onLoadNeedingWaterRequested);
    on<PlantsSearchRequested>(_onSearchRequested);
    on<PlantCreateRequested>(_onCreateRequested);
    on<PlantUpdateRequested>(_onUpdateRequested);
    on<PlantDeleteRequested>(_onDeleteRequested);
    on<PlantWaterRequested>(_onWaterRequested);
    on<PlantWaterOnDateRequested>(_onWaterOnDateRequested);
    on<PlantTransplantRequested>(_onTransplantRequested);
    on<PlantSelectRequested>(_onSelectRequested);
    on<PlantsClearError>(_onClearError);
    on<PlantClearLastWateringRequested>(_onClearLastWateringRequested);
    on<PlantsFilterByLocation>(_onFilterByLocation);
    on<PlantAssignToLocationRequested>(_onAssignToLocation);
  }

  Future<void> _onLoadRequested(
    PlantsLoadRequested event,
    Emitter<PlantsState> emit,
  ) async {
    await _loadPlants(emit);
  }

  Future<void> _loadPlants(Emitter<PlantsState> emit) async {
    emit(state.copyWith(status: PlantsStatus.loading));

    final result = await _repository.getPlants();

    result.when(
      success: (plants) {
        emit(state.copyWith(
          status: plants.isEmpty ? PlantsStatus.empty : PlantsStatus.loaded,
          plants: plants,
        ));
        // Reprogramar todos los recordatorios de riego con la lista completa.
        _notifications.syncForPlants(plants);
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          status: PlantsStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onLoadNeedingWaterRequested(
    PlantsLoadNeedingWaterRequested event,
    Emitter<PlantsState> emit,
  ) async {
    emit(state.copyWith(status: PlantsStatus.loading));

    final result = await _repository.getPlantsNeedingWater();

    result.when(
      success: (plants) {
        emit(state.copyWith(
          status: plants.isEmpty ? PlantsStatus.empty : PlantsStatus.loaded,
          plants: plants,
        ));
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          status: PlantsStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onSearchRequested(
    PlantsSearchRequested event,
    Emitter<PlantsState> emit,
  ) async {
    if (event.query.isEmpty) {
      await _loadPlants(emit);
      return;
    }

    emit(state.copyWith(status: PlantsStatus.loading));

    final result = await _repository.searchPlants(event.query);

    result.when(
      success: (plants) {
        emit(state.copyWith(
          status: plants.isEmpty ? PlantsStatus.empty : PlantsStatus.loaded,
          plants: plants,
        ));
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          status: PlantsStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onCreateRequested(
    PlantCreateRequested event,
    Emitter<PlantsState> emit,
  ) async {
    emit(state.copyWith(
      operationStatus: PlantsOperationStatus.loading,
    ));

    final result = await _repository.createPlant(
      name: event.name,
      customName: event.customName,
      scientificName: event.scientificName,
      speciesId: event.speciesId,
      speciesCategory: event.speciesCategory,
      imageUrl: event.imageUrl,
      location: event.location,
      notes: event.notes,
      wateringFrequency: event.wateringFrequency,
      acquiredDate: event.acquiredDate,
      environment: event.environment,
      growthStage: event.growthStage,
      potSize: event.potSize,
      latitude: event.latitude,
      longitude: event.longitude,
      organizationId: event.organizationId,
      locationId: event.locationId,
    );

    result.when(
      success: (plant) {
        final plants = [plant, ...state.plants];
        emit(state.copyWith(
          plants: plants,
          status: PlantsStatus.loaded,
          operationStatus: PlantsOperationStatus.success,
        ));
        _notifications.schedulePlant(plant);
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          operationStatus: PlantsOperationStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onUpdateRequested(
    PlantUpdateRequested event,
    Emitter<PlantsState> emit,
  ) async {
    emit(state.copyWith(
      operationStatus: PlantsOperationStatus.loading,
    ));

    final result = await _repository.updatePlant(event.plant);

    result.when(
      success: (plant) {
        final plants = state.plants
            .map((p) => p.id == plant.id ? plant : p)
            .toList();
        emit(state.copyWith(
          plants: plants,
          selectedPlant: plant.id == state.selectedPlant?.id ? plant : state.selectedPlant,
          operationStatus: PlantsOperationStatus.success,
        ));
        _notifications.schedulePlant(plant);
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          operationStatus: PlantsOperationStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onDeleteRequested(
    PlantDeleteRequested event,
    Emitter<PlantsState> emit,
  ) async {
    emit(state.copyWith(
      operationStatus: PlantsOperationStatus.loading,
    ));

    final result = await _repository.deletePlant(event.id);

    result.when(
      success: (_) {
        final plants = state.plants.where((p) => p.id != event.id).toList();
        emit(state.copyWith(
          plants: plants,
          status: plants.isEmpty ? PlantsStatus.empty : PlantsStatus.loaded,
          selectedPlant: state.selectedPlant?.id == event.id ? null : state.selectedPlant,
          operationStatus: PlantsOperationStatus.success,
        ));
        _notifications.cancelForPlant(event.id);
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          operationStatus: PlantsOperationStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onWaterRequested(
    PlantWaterRequested event,
    Emitter<PlantsState> emit,
  ) async {
    emit(state.copyWith(
      operationStatus: PlantsOperationStatus.loading,
    ));

    final result = await _repository.waterPlant(event.id);

    result.when(
      success: (plant) {
        final plants = state.plants
            .map((p) => p.id == plant.id ? plant : p)
            .toList();
        emit(state.copyWith(
          plants: plants,
          selectedPlant: plant.id == state.selectedPlant?.id ? plant : state.selectedPlant,
          operationStatus: PlantsOperationStatus.success,
        ));
        _notifications.schedulePlant(plant);
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          operationStatus: PlantsOperationStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onWaterOnDateRequested(
    PlantWaterOnDateRequested event,
    Emitter<PlantsState> emit,
  ) async {
    emit(state.copyWith(
      operationStatus: PlantsOperationStatus.loading,
    ));

    final result = await _repository.waterPlantWithDate(event.id, event.daysAgo);

    result.when(
      success: (plant) {
        final plants = state.plants
            .map((p) => p.id == plant.id ? plant : p)
            .toList();
        emit(state.copyWith(
          plants: plants,
          selectedPlant: plant.id == state.selectedPlant?.id ? plant : state.selectedPlant,
          operationStatus: PlantsOperationStatus.success,
        ));
        _notifications.schedulePlant(plant);
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          operationStatus: PlantsOperationStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onTransplantRequested(
    PlantTransplantRequested event,
    Emitter<PlantsState> emit,
  ) async {
    emit(state.copyWith(
      operationStatus: PlantsOperationStatus.loading,
    ));

    final result = await _repository.transplantPlant(event.id, event.newPotSize);

    result.when(
      success: (plant) {
        final plants = state.plants
            .map((p) => p.id == plant.id ? plant : p)
            .toList();
        emit(state.copyWith(
          plants: plants,
          selectedPlant: plant.id == state.selectedPlant?.id ? plant : state.selectedPlant,
          operationStatus: PlantsOperationStatus.success,
        ));
        _notifications.schedulePlant(plant);
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          operationStatus: PlantsOperationStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  void _onSelectRequested(
    PlantSelectRequested event,
    Emitter<PlantsState> emit,
  ) {
    if (state.plants.isEmpty) return;
    final plant = state.plants.firstWhere(
      (p) => p.id == event.id,
      orElse: () => state.plants.first,
    );
    emit(state.copyWith(selectedPlant: plant));
  }

  void _onClearError(
    PlantsClearError event,
    Emitter<PlantsState> emit,
  ) {
    emit(const PlantsState());
  }

  Future<void> _onClearLastWateringRequested(
    PlantClearLastWateringRequested event,
    Emitter<PlantsState> emit,
  ) async {
    emit(state.copyWith(
      operationStatus: PlantsOperationStatus.loading,
    ));

    // Buscar la planta actual en el estado
    final plant = state.plants.firstWhere(
      (p) => p.id == event.id,
      orElse: () => state.selectedPlant!,
    );

    // Crear copia con lastWatered = null
    final updatedPlant = plant.copyWith(lastWatered: null);

    final result = await _repository.updatePlant(updatedPlant);

    result.when(
      success: (p) {
        final plants = state.plants
            .map((pl) => pl.id == p.id ? p : pl)
            .toList();
        emit(state.copyWith(
          plants: plants,
          selectedPlant: p.id == state.selectedPlant?.id ? p : state.selectedPlant,
          operationStatus: PlantsOperationStatus.success,
        ));
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          operationStatus: PlantsOperationStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onFilterByLocation(
    PlantsFilterByLocation event,
    Emitter<PlantsState> emit,
  ) async {
    emit(state.copyWith(status: PlantsStatus.loading));
    final result = await _repository.getPlantsByLocationIds(event.locationIds);
    result.when(
      success: (plants) => emit(state.copyWith(
        status: plants.isEmpty ? PlantsStatus.empty : PlantsStatus.loaded,
        plants: plants,
      )),
      failure: (msg, _, __) => emit(state.copyWith(
        status: PlantsStatus.error,
        errorMessage: msg,
      )),
    );
  }

  Future<void> _onAssignToLocation(
    PlantAssignToLocationRequested event,
    Emitter<PlantsState> emit,
  ) async {
    emit(state.copyWith(operationStatus: PlantsOperationStatus.loading));
    final result = await _repository.assignPlantToLocation(
      event.plantId,
      locationId: event.locationId,
    );
    result.when(
      success: (plant) {
        final plants = state.plants
            .map((p) => p.id == plant.id ? plant : p)
            .toList();
        emit(state.copyWith(
          plants: plants,
          selectedPlant:
              plant.id == state.selectedPlant?.id ? plant : state.selectedPlant,
          operationStatus: PlantsOperationStatus.success,
        ));
      },
      failure: (msg, _, __) => emit(state.copyWith(
        operationStatus: PlantsOperationStatus.error,
        errorMessage: msg,
      )),
    );
  }
}
