import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:planticula/features/gardens/domain/entities/garden.dart';
import 'package:planticula/features/gardens/domain/entities/garden_group.dart';
import 'package:planticula/features/gardens/domain/repositories/garden_repository.dart';

part 'garden_event.dart';
part 'garden_state.dart';

class GardenBloc extends Bloc<GardenEvent, GardenState> {
  final GardenRepository _repo;

  GardenBloc(this._repo) : super(const GardenState()) {
    on<GardensLoadRequested>(_onLoad);
    on<GardenGroupsLoadRequested>(_onGroupsLoad);
    on<GardenCreateRequested>(_onCreate);
    on<GardenUpdateRequested>(_onUpdate);
    on<GardenDeleteRequested>(_onDelete);
    on<GardenSelectRequested>(_onSelect);
    on<GardenGroupCreateRequested>(_onGroupCreate);
    on<GardenGroupUpdateRequested>(_onGroupUpdate);
    on<GardenGroupDeleteRequested>(_onGroupDelete);
    on<GardenClearError>(_onClearError);
  }

  // ── Jardines ─────────────────────────────────────────────────────────────

  Future<void> _onLoad(
    GardensLoadRequested event,
    Emitter<GardenState> emit,
  ) async {
    emit(state.copyWith(status: GardenStatus.loading));

    // Garantiza que siempre existe al menos el jardín por defecto
    await _repo.getOrCreateDefaultGarden();

    final result = await _repo.getGardens();
    result.when(
      success: (gardens) => emit(state.copyWith(
        status: gardens.isEmpty ? GardenStatus.empty : GardenStatus.loaded,
        gardens: gardens,
        // No auto-seleccionamos ningún jardín: el estado "Todas" (selectedGarden
        // == null) es el filtro por defecto en la PlantsScreen. El usuario
        // selecciona explícitamente un jardín desde la GardenFilterBar.
      )),
      failure: (msg, _, __) => emit(state.copyWith(
        status: GardenStatus.error,
        errorMessage: msg,
      )),
    );
  }

  Future<void> _onGroupsLoad(
    GardenGroupsLoadRequested event,
    Emitter<GardenState> emit,
  ) async {
    final result = await _repo.getGroupsByGarden(event.gardenId);
    result.when(
      success: (groups) => emit(state.copyWith(groups: groups)),
      failure: (msg, _, __) =>
          emit(state.copyWith(errorMessage: msg)),
    );
  }

  Future<void> _onCreate(
    GardenCreateRequested event,
    Emitter<GardenState> emit,
  ) async {
    emit(state.copyWith(opStatus: GardenOpStatus.loading));
    final result = await _repo.createGarden(
      name: event.name,
      description: event.description,
      icon: event.icon,
      color: event.color,
      type: event.type,
    );
    result.when(
      success: (garden) => emit(state.copyWith(
        gardens: [garden, ...state.gardens],
        status: GardenStatus.loaded,
        opStatus: GardenOpStatus.success,
      )),
      failure: (msg, _, __) => emit(state.copyWith(
        opStatus: GardenOpStatus.error,
        errorMessage: msg,
      )),
    );
  }

  Future<void> _onUpdate(
    GardenUpdateRequested event,
    Emitter<GardenState> emit,
  ) async {
    emit(state.copyWith(opStatus: GardenOpStatus.loading));
    final result = await _repo.updateGarden(event.garden);
    result.when(
      success: (updated) => emit(state.copyWith(
        gardens: state.gardens.map((g) => g.id == updated.id ? updated : g).toList(),
        selectedGarden: state.selectedGarden?.id == updated.id ? updated : state.selectedGarden,
        opStatus: GardenOpStatus.success,
      )),
      failure: (msg, _, __) => emit(state.copyWith(
        opStatus: GardenOpStatus.error,
        errorMessage: msg,
      )),
    );
  }

  Future<void> _onDelete(
    GardenDeleteRequested event,
    Emitter<GardenState> emit,
  ) async {
    // No permitir borrar el jardín por defecto
    final garden = state.gardens.where((g) => g.id == event.id).firstOrNull;
    if (garden?.isDefault == true) {
      emit(state.copyWith(
        opStatus: GardenOpStatus.error,
        errorMessage: 'No se puede eliminar el jardín por defecto',
      ));
      return;
    }

    emit(state.copyWith(opStatus: GardenOpStatus.loading));
    final result = await _repo.deleteGarden(event.id);
    result.when(
      success: (_) {
        final remaining = state.gardens.where((g) => g.id != event.id).toList();
        emit(state.copyWith(
          gardens: remaining,
          status: remaining.isEmpty ? GardenStatus.empty : GardenStatus.loaded,
          opStatus: GardenOpStatus.success,
          clearSelectedGarden:
              state.selectedGarden?.id == event.id,
        ));
      },
      failure: (msg, _, __) => emit(state.copyWith(
        opStatus: GardenOpStatus.error,
        errorMessage: msg,
      )),
    );
  }

  void _onSelect(GardenSelectRequested event, Emitter<GardenState> emit) {
    emit(state.copyWith(
      selectedGarden: event.garden,
      clearSelectedGarden: event.garden == null,
      groups: const [], // limpiar grupos al cambiar de jardín
    ));
    // Cargar grupos del jardín seleccionado
    if (event.garden != null) {
      add(GardenGroupsLoadRequested(event.garden!.id));
    }
  }

  // ── Grupos ───────────────────────────────────────────────────────────────

  Future<void> _onGroupCreate(
    GardenGroupCreateRequested event,
    Emitter<GardenState> emit,
  ) async {
    emit(state.copyWith(opStatus: GardenOpStatus.loading));
    final result = await _repo.createGroup(
      gardenId: event.gardenId,
      name: event.name,
      description: event.description,
      icon: event.icon,
      color: event.color,
    );
    result.when(
      success: (group) => emit(state.copyWith(
        groups: [...state.groups, group],
        opStatus: GardenOpStatus.success,
      )),
      failure: (msg, _, __) => emit(state.copyWith(
        opStatus: GardenOpStatus.error,
        errorMessage: msg,
      )),
    );
  }

  Future<void> _onGroupUpdate(
    GardenGroupUpdateRequested event,
    Emitter<GardenState> emit,
  ) async {
    emit(state.copyWith(opStatus: GardenOpStatus.loading));
    final result = await _repo.updateGroup(event.group);
    result.when(
      success: (updated) => emit(state.copyWith(
        groups: state.groups.map((g) => g.id == updated.id ? updated : g).toList(),
        opStatus: GardenOpStatus.success,
      )),
      failure: (msg, _, __) => emit(state.copyWith(
        opStatus: GardenOpStatus.error,
        errorMessage: msg,
      )),
    );
  }

  Future<void> _onGroupDelete(
    GardenGroupDeleteRequested event,
    Emitter<GardenState> emit,
  ) async {
    emit(state.copyWith(opStatus: GardenOpStatus.loading));
    final result = await _repo.deleteGroup(event.id);
    result.when(
      success: (_) => emit(state.copyWith(
        groups: state.groups.where((g) => g.id != event.id).toList(),
        opStatus: GardenOpStatus.success,
      )),
      failure: (msg, _, __) => emit(state.copyWith(
        opStatus: GardenOpStatus.error,
        errorMessage: msg,
      )),
    );
  }

  void _onClearError(GardenClearError event, Emitter<GardenState> emit) {
    emit(state.copyWith(clearError: true, opStatus: GardenOpStatus.initial));
  }
}
