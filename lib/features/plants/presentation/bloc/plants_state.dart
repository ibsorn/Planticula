part of 'plants_bloc.dart';

enum PlantsStatus {
  initial,
  loading,
  loaded,
  empty,
  error,
}

enum PlantsOperationStatus {
  initial,
  loading,
  success,
  error,
}

class PlantsState extends Equatable {
  final PlantsStatus status;
  final PlantsOperationStatus operationStatus;
  final List<Plant> plants;
  final String? errorMessage;
  final Plant? selectedPlant;

  const PlantsState({
    this.status = PlantsStatus.initial,
    this.operationStatus = PlantsOperationStatus.initial,
    this.plants = const [],
    this.errorMessage,
    this.selectedPlant,
  });

  bool get isLoading => status == PlantsStatus.loading;
  bool get isEmpty => status == PlantsStatus.empty;
  bool get hasError => status == PlantsStatus.error;
  bool get isOperationLoading => operationStatus == PlantsOperationStatus.loading;
  bool get isOperationSuccess => operationStatus == PlantsOperationStatus.success;

  /// Plantas ordenadas por las que necesitan riego primero
  List<Plant> get plantsNeedingWater {
    return plants.where((p) => p.needsWatering).toList();
  }

  PlantsState copyWith({
    PlantsStatus? status,
    PlantsOperationStatus? operationStatus,
    List<Plant>? plants,
    String? errorMessage,
    Plant? selectedPlant,
  }) {
    return PlantsState(
      status: status ?? this.status,
      operationStatus: operationStatus ?? this.operationStatus,
      plants: plants ?? this.plants,
      errorMessage: errorMessage ?? this.errorMessage,
      selectedPlant: selectedPlant ?? this.selectedPlant,
    );
  }

  @override
  List<Object?> get props => [
        status,
        operationStatus,
        plants,
        errorMessage,
        selectedPlant,
      ];
}
