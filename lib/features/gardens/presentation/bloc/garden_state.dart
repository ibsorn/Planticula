part of 'garden_bloc.dart';

enum GardenStatus { initial, loading, loaded, empty, error }
enum GardenOpStatus { initial, loading, success, error }

class GardenState extends Equatable {
  final GardenStatus status;
  final GardenOpStatus opStatus;

  /// Lista de jardines del usuario
  final List<Garden> gardens;

  /// Grupos del jardín seleccionado actualmente
  final List<GardenGroup> groups;

  /// Jardín activo en la UI (puede ser null si no se ha seleccionado ninguno)
  final Garden? selectedGarden;

  final String? errorMessage;

  const GardenState({
    this.status    = GardenStatus.initial,
    this.opStatus  = GardenOpStatus.initial,
    this.gardens   = const [],
    this.groups    = const [],
    this.selectedGarden,
    this.errorMessage,
  });

  bool get isLoading        => status   == GardenStatus.loading;
  bool get isEmpty          => status   == GardenStatus.empty;
  bool get hasError         => status   == GardenStatus.error;
  bool get isOpLoading      => opStatus == GardenOpStatus.loading;
  bool get isOpSuccess      => opStatus == GardenOpStatus.success;

  /// Jardín por defecto (el primero con is_default = true, o el primero de la lista)
  Garden? get defaultGarden =>
      gardens.where((g) => g.isDefault).firstOrNull ?? gardens.firstOrNull;

  GardenState copyWith({
    GardenStatus? status,
    GardenOpStatus? opStatus,
    List<Garden>? gardens,
    List<GardenGroup>? groups,
    Garden? selectedGarden,
    bool clearSelectedGarden = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return GardenState(
      status:         status         ?? this.status,
      opStatus:       opStatus       ?? this.opStatus,
      gardens:        gardens        ?? this.gardens,
      groups:         groups         ?? this.groups,
      selectedGarden: clearSelectedGarden ? null : (selectedGarden ?? this.selectedGarden),
      errorMessage:   clearError     ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [status, opStatus, gardens, groups, selectedGarden, errorMessage];
}
