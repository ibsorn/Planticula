part of 'pest_alerts_bloc.dart';

abstract class PestAlertsEvent extends Equatable {
  const PestAlertsEvent();

  @override
  List<Object?> get props => [];
}

/// Cargar alertas cercanas a la ubicación del usuario
class PestAlertsLoadNearby extends PestAlertsEvent {}

/// Cargar alertas reportadas por el usuario
class PestAlertsLoadMyAlerts extends PestAlertsEvent {}

/// Recargar datos (según tab activo)
class PestAlertsRefresh extends PestAlertsEvent {}

/// Seleccionar foto desde galería
class PestAlertsPhotoPickRequested extends PestAlertsEvent {}

/// Capturar foto desde cámara
class PestAlertsPhotoCaptureRequested extends PestAlertsEvent {}

/// Limpiar foto seleccionada
class PestAlertsClearPhoto extends PestAlertsEvent {}

/// Enviar reporte de plaga
class PestAlertsReportSubmitted extends PestAlertsEvent {
  final PestType pestType;
  final String? customPestName;
  final Severity severity;
  final double latitude;
  final double longitude;
  final String? locationName;
  final String? notes;

  const PestAlertsReportSubmitted({
    required this.pestType,
    this.customPestName,
    required this.severity,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.notes,
  });

  @override
  List<Object?> get props => [
        pestType,
        customPestName,
        severity,
        latitude,
        longitude,
        locationName,
        notes,
      ];
}

/// Cambiar filtros de búsqueda
class PestAlertsFilterChanged extends PestAlertsEvent {
  final double? radiusKm;
  final int? daysLimit;
  final List<PestType>? pestTypes;
  final List<Severity>? severities;
  final bool? includeResolved;

  const PestAlertsFilterChanged({
    this.radiusKm,
    this.daysLimit,
    this.pestTypes,
    this.severities,
    this.includeResolved,
  });

  @override
  List<Object?> get props => [
        radiusKm,
        daysLimit,
        pestTypes,
        severities,
        includeResolved,
      ];
}

/// Seleccionar una alerta para ver detalle
class PestAlertsAlertSelected extends PestAlertsEvent {
  final String alertId;

  const PestAlertsAlertSelected(this.alertId);

  @override
  List<Object?> get props => [alertId];
}

/// Marcar alerta como resuelta
class PestAlertsMarkResolved extends PestAlertsEvent {
  final String alertId;

  const PestAlertsMarkResolved(this.alertId);

  @override
  List<Object?> get props => [alertId];
}

/// Eliminar alerta
class PestAlertsDeleteAlert extends PestAlertsEvent {
  final String alertId;

  const PestAlertsDeleteAlert(this.alertId);

  @override
  List<Object?> get props => [alertId];
}

/// Confirmar alerta (otro usuario vio la misma plaga)
class PestAlertsConfirmAlert extends PestAlertsEvent {
  final String alertId;

  const PestAlertsConfirmAlert(this.alertId);

  @override
  List<Object?> get props => [alertId];
}

/// Limpiar mensajes de error
class PestAlertsClearError extends PestAlertsEvent {}

/// Actualizar ubicación del usuario
class PestAlertsUpdateUserLocation extends PestAlertsEvent {
  final double latitude;
  final double longitude;

  const PestAlertsUpdateUserLocation({
    required this.latitude,
    required this.longitude,
  });

  @override
  List<Object?> get props => [latitude, longitude];
}
