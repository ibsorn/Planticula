import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
import 'package:planticula/features/plants/domain/repositories/plants_repository.dart';

part 'plants_event.dart';
part 'plants_state.dart';

class PlantsBloc extends Bloc<PlantsEvent, PlantsState> {
  final PlantsRepository _repository;

  PlantsBloc(this._repository) : super(const PlantsState()) {
    on<PlantsLoadRequested>(_onLoadRequested);
    on<PlantsLoadNeedingWaterRequested>(_onLoadNeedingWaterRequested);
    on<PlantsSearchRequested>(_onSearchRequested);
    on<PlantCreateRequested>(_onCreateRequested);
    on<PlantUpdateRequested>(_onUpdateRequested);
    on<PlantDeleteRequested>(_onDeleteRequested);
    on<PlantWaterRequested>(_onWaterRequested);
    on<PlantSelectRequested>(_onSelectRequested);
    on<PlantsClearError>(_onClearError);
  }

  Future<void> _onLoadRequested(
    PlantsLoadRequested event,
    Emitter<PlantsState> emit,
  ) async {
    emit(state.copyWith(status: PlantsStatus.loading));

    final result = await _repository.getPlants();

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
      add(PlantsLoadRequested());
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
      latitude: event.latitude,
      longitude: event.longitude,
    );

    result.when(
      success: (plant) {
        final plants = [plant, ...state.plants];
        emit(state.copyWith(
          plants: plants,
          status: PlantsStatus.loaded,
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
}
