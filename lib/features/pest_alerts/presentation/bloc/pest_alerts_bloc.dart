import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';
import 'package:planticula/core/utils/image_picker_helper.dart';
import 'package:planticula/features/pest_alerts/domain/entities/pest_alert.dart';
import 'package:planticula/features/pest_alerts/domain/repositories/pest_alert_repository.dart';

part 'pest_alerts_event.dart';
part 'pest_alerts_state.dart';

class PestAlertsBloc extends Bloc<PestAlertsEvent, PestAlertsState> {
  final PestAlertRepository _repository;
  final ImagePickerHelper _imagePickerHelper;

  PestAlertsBloc(this._repository)
      : _imagePickerHelper = ImagePickerHelper(),
        super(const PestAlertsState()) {
    on<PestAlertsLoadNearby>(_onLoadNearby);
    on<PestAlertsLoadMyAlerts>(_onLoadMyAlerts);
    on<PestAlertsRefresh>(_onRefresh);
    on<PestAlertsPhotoPickRequested>(_onPhotoPickRequested);
    on<PestAlertsPhotoCaptureRequested>(_onPhotoCaptureRequested);
    on<PestAlertsClearPhoto>(_onClearPhoto);
    on<PestAlertsReportSubmitted>(_onReportSubmitted);
    on<PestAlertsFilterChanged>(_onFilterChanged);
    on<PestAlertsAlertSelected>(_onAlertSelected);
    on<PestAlertsMarkResolved>(_onMarkResolved);
    on<PestAlertsDeleteAlert>(_onDeleteAlert);
    on<PestAlertsConfirmAlert>(_onConfirmAlert);
    on<PestAlertsClearError>(_onClearError);
    on<PestAlertsUpdateUserLocation>(_onUpdateUserLocation);
  }

  Future<void> _onLoadNearby(
    PestAlertsLoadNearby event,
    Emitter<PestAlertsState> emit,
  ) async {
    await _loadNearbyAlerts(emit);
  }

  Future<void> _loadNearbyAlerts(Emitter<PestAlertsState> emit) async {
    emit(state.copyWith(
      nearbyStatus: PestAlertsStatus.loading,
    ));

    // Si no tenemos ubicación del usuario, no podemos cargar alertas cercanas
    if (state.userLatitude == null || state.userLongitude == null) {
      emit(state.copyWith(
        nearbyStatus: PestAlertsStatus.error,
        errorMessage: 'Se requiere ubicación para ver alertas cercanas',
      ));
      return;
    }

    final result = await _repository.getNearbyAlerts(
      latitude: state.userLatitude!,
      longitude: state.userLongitude!,
      radiusKm: state.filterRadiusKm,
      daysLimit: state.filterDaysLimit,
      pestTypes: state.filterPestTypes,
      severities: state.filterSeverities,
      includeResolved: state.includeResolved,
      limit: 50,
    );

    result.when(
      success: (alerts) {
        emit(state.copyWith(
          nearbyAlerts: alerts,
          nearbyStatus: alerts.isEmpty
              ? PestAlertsStatus.empty
              : PestAlertsStatus.loaded,
        ));
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          nearbyStatus: PestAlertsStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onLoadMyAlerts(
    PestAlertsLoadMyAlerts event,
    Emitter<PestAlertsState> emit,
  ) async {
    await _loadMyAlerts(emit);
  }

  Future<void> _loadMyAlerts(Emitter<PestAlertsState> emit) async {
    emit(state.copyWith(
      myAlertsStatus: PestAlertsStatus.loading,
    ));

    final result = await _repository.getMyAlerts(limit: 50);

    result.when(
      success: (alerts) {
        emit(state.copyWith(
          myAlerts: alerts,
          myAlertsStatus: alerts.isEmpty
              ? PestAlertsStatus.empty
              : PestAlertsStatus.loaded,
        ));
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          myAlertsStatus: PestAlertsStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onRefresh(
    PestAlertsRefresh event,
    Emitter<PestAlertsState> emit,
  ) async {
    if (state.activeTab == PestAlertsTab.nearby) {
      await _loadNearbyAlerts(emit);
    } else {
      await _loadMyAlerts(emit);
    }
  }

  Future<void> _onPhotoPickRequested(
    PestAlertsPhotoPickRequested event,
    Emitter<PestAlertsState> emit,
  ) async {
    try {
      emit(state.copyWith(photoSelectionStatus: PhotoSelectionStatus.picking));

      final bytes = await _imagePickerHelper.pickSingleImage(
        source: ImageSource.gallery,
      );

      if (bytes != null) {
        emit(state.copyWith(
          selectedPhotoBytes: bytes,
          photoSelectionStatus: PhotoSelectionStatus.selected,
        ));
      } else {
        emit(state.copyWith(photoSelectionStatus: PhotoSelectionStatus.initial));
      }
    } catch (e) {
      emit(state.copyWith(
        photoSelectionStatus: PhotoSelectionStatus.error,
        errorMessage: 'Error al seleccionar foto: ${e.toString()}',
      ));
    }
  }

  Future<void> _onPhotoCaptureRequested(
    PestAlertsPhotoCaptureRequested event,
    Emitter<PestAlertsState> emit,
  ) async {
    try {
      emit(state.copyWith(photoSelectionStatus: PhotoSelectionStatus.picking));

      final bytes = await _imagePickerHelper.pickSingleImage(
        source: ImageSource.camera,
      );

      if (bytes != null) {
        emit(state.copyWith(
          selectedPhotoBytes: bytes,
          photoSelectionStatus: PhotoSelectionStatus.selected,
        ));
      } else {
        emit(state.copyWith(photoSelectionStatus: PhotoSelectionStatus.initial));
      }
    } catch (e) {
      emit(state.copyWith(
        photoSelectionStatus: PhotoSelectionStatus.error,
        errorMessage: 'Error al capturar foto: ${e.toString()}',
      ));
    }
  }

  void _onClearPhoto(
    PestAlertsClearPhoto event,
    Emitter<PestAlertsState> emit,
  ) {
    emit(state.copyWith(
      photoSelectionStatus: PhotoSelectionStatus.initial,
    ));
  }

  Future<void> _onReportSubmitted(
    PestAlertsReportSubmitted event,
    Emitter<PestAlertsState> emit,
  ) async {
    emit(state.copyWith(
      submissionStatus: SubmissionStatus.submitting,
    ));

    final result = await _repository.reportPest(
      photoBytes: state.selectedPhotoBytes,
      fileName: 'pest_${DateTime.now().millisecondsSinceEpoch}.jpg',
      pestType: event.pestType,
      customPestName: event.customPestName,
      severity: event.severity,
      latitude: event.latitude,
      longitude: event.longitude,
      locationName: event.locationName,
      notes: event.notes,
    );

    result.when(
      success: (alert) async {
        emit(state.copyWith(
          submissionStatus: SubmissionStatus.success,
          photoSelectionStatus: PhotoSelectionStatus.initial,
          myAlerts: [alert, ...state.myAlerts],
          lastCreatedAlert: alert,
        ));

        // Recargar alertas cercanas si tenemos ubicación
        if (state.userLatitude != null) {
          await _loadNearbyAlerts(emit);
        }
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          submissionStatus: SubmissionStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onFilterChanged(
    PestAlertsFilterChanged event,
    Emitter<PestAlertsState> emit,
  ) async {
    emit(state.copyWith(
      filterRadiusKm: event.radiusKm ?? state.filterRadiusKm,
      filterDaysLimit: event.daysLimit ?? state.filterDaysLimit,
      filterPestTypes: event.pestTypes ?? state.filterPestTypes,
      filterSeverities: event.severities ?? state.filterSeverities,
      includeResolved: event.includeResolved ?? state.includeResolved,
    ));

    // Recargar con nuevos filtros
    await _loadNearbyAlerts(emit);
  }

  void _onAlertSelected(
    PestAlertsAlertSelected event,
    Emitter<PestAlertsState> emit,
  ) {
    PestAlert? alert = state.nearbyAlerts.cast<PestAlert?>().firstWhere(
      (a) => a?.id == event.alertId,
      orElse: () => null,
    );
    alert ??= state.myAlerts.cast<PestAlert?>().firstWhere(
      (a) => a?.id == event.alertId,
      orElse: () => null,
    );
    if (alert != null) {
      emit(state.copyWith(selectedAlert: alert));
    }
  }

  Future<void> _onMarkResolved(
    PestAlertsMarkResolved event,
    Emitter<PestAlertsState> emit,
  ) async {
    emit(state.copyWith(actionStatus: ActionStatus.processing));

    final result = await _repository.markAsResolved(event.alertId);

    result.when(
      success: (alert) {
        // Actualizar en ambas listas
        final updatedNearby = state.nearbyAlerts
            .map((a) => a.id == alert.id ? alert : a)
            .toList();
        final updatedMy = state.myAlerts
            .map((a) => a.id == alert.id ? alert : a)
            .toList();

        emit(state.copyWith(
          nearbyAlerts: updatedNearby,
          myAlerts: updatedMy,
          selectedAlert: alert.id == state.selectedAlert?.id ? alert : state.selectedAlert,
          actionStatus: ActionStatus.success,
        ));
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          actionStatus: ActionStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onDeleteAlert(
    PestAlertsDeleteAlert event,
    Emitter<PestAlertsState> emit,
  ) async {
    emit(state.copyWith(actionStatus: ActionStatus.processing));

    final result = await _repository.deleteAlert(event.alertId);

    result.when(
      success: (_) {
        final updatedNearby = state.nearbyAlerts
            .where((a) => a.id != event.alertId)
            .toList();
        final updatedMy = state.myAlerts
            .where((a) => a.id != event.alertId)
            .toList();

        emit(state.copyWith(
          nearbyAlerts: updatedNearby,
          myAlerts: updatedMy,
          selectedAlert: state.selectedAlert?.id == event.alertId
              ? null
              : state.selectedAlert,
          actionStatus: ActionStatus.success,
        ));
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          actionStatus: ActionStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onConfirmAlert(
    PestAlertsConfirmAlert event,
    Emitter<PestAlertsState> emit,
  ) async {
    emit(state.copyWith(actionStatus: ActionStatus.processing));

    final result = await _repository.confirmAlert(event.alertId);

    result.when(
      success: (_) {
        // Incrementar contador localmente
        final updatedNearby = state.nearbyAlerts.map((a) {
          if (a.id == event.alertId) {
            return a.copyWith(confirmedByCount: (a.confirmedByCount ?? 0) + 1);
          }
          return a;
        }).toList();

        emit(state.copyWith(
          nearbyAlerts: updatedNearby,
          actionStatus: ActionStatus.success,
        ));
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          actionStatus: ActionStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  void _onClearError(
    PestAlertsClearError event,
    Emitter<PestAlertsState> emit,
  ) {
    emit(state.copyWith(
      submissionStatus: SubmissionStatus.initial,
      actionStatus: ActionStatus.initial,
    ));
  }

  Future<void> _onUpdateUserLocation(
    PestAlertsUpdateUserLocation event,
    Emitter<PestAlertsState> emit,
  ) async {
    emit(state.copyWith(
      userLatitude: event.latitude,
      userLongitude: event.longitude,
    ));

    // Cargar alertas cercanas automáticamente
    await _loadNearbyAlerts(emit);
  }
}
