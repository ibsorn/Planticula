import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:planticula/features/plants/domain/entities/care_log.dart';
import 'package:planticula/features/plants/domain/repositories/plants_repository.dart';

enum CareLogStatus { initial, loading, loaded, error }

class CareLogState extends Equatable {
  final CareLogStatus status;
  final List<CareLog> logs;
  final String? errorMessage;

  const CareLogState({
    this.status = CareLogStatus.initial,
    this.logs = const [],
    this.errorMessage,
  });

  /// Nº total de riegos registrados.
  int get wateringCount =>
      logs.where((l) => l.type == CareLogType.watering).length;

  /// Racha de riegos "a tiempo": riegos consecutivos (del más reciente hacia
  /// atrás) cuyo intervalo no superó [frequency] + 2 días de tolerancia.
  int streak(int? frequency) {
    if (frequency == null || frequency <= 0) return 0;
    final waterings = logs
        .where((l) => l.type == CareLogType.watering)
        .toList()
      ..sort((a, b) => b.eventDate.compareTo(a.eventDate));
    if (waterings.isEmpty) return 0;
    var count = 1;
    for (var i = 0; i < waterings.length - 1; i++) {
      final gap = waterings[i].eventDate.difference(waterings[i + 1].eventDate).inDays;
      if (gap <= frequency + 2) {
        count++;
      } else {
        break;
      }
    }
    return count;
  }

  CareLogState copyWith({
    CareLogStatus? status,
    List<CareLog>? logs,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CareLogState(
      status: status ?? this.status,
      logs: logs ?? this.logs,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, logs, errorMessage];
}

/// Cubit del historial de cuidados de UNA planta. Se provee localmente en
/// [PlantDetailScreen].
class CareLogCubit extends Cubit<CareLogState> {
  final PlantsRepository _repo;

  CareLogCubit(this._repo) : super(const CareLogState());

  Future<void> load(String plantId) async {
    emit(state.copyWith(status: CareLogStatus.loading));
    final result = await _repo.getCareLogs(plantId);
    result.when(
      success: (logs) =>
          emit(state.copyWith(status: CareLogStatus.loaded, logs: logs)),
      failure: (msg, _, __) =>
          emit(state.copyWith(status: CareLogStatus.error, errorMessage: msg)),
    );
  }

  Future<void> addNote(String plantId, String note) async {
    final result = await _repo.addCareLog(
      plantId: plantId,
      type: CareLogType.note,
      note: note,
    );
    result.when(
      success: (log) => emit(state.copyWith(logs: [log, ...state.logs])),
      failure: (msg, _, __) => emit(state.copyWith(errorMessage: msg)),
    );
  }

  Future<void> delete(String id) async {
    final result = await _repo.deleteCareLog(id);
    result.when(
      success: (_) => emit(
        state.copyWith(logs: state.logs.where((l) => l.id != id).toList()),
      ),
      failure: (msg, _, __) => emit(state.copyWith(errorMessage: msg)),
    );
  }
}
