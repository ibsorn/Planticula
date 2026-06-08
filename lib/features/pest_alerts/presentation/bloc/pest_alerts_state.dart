part of 'pest_alerts_bloc.dart';

enum PestAlertsStatus {
  initial,
  loading,
  loaded,
  empty,
  error,
}

enum PhotoSelectionStatus {
  initial,
  picking,
  selected,
  error,
}

enum SubmissionStatus {
  initial,
  submitting,
  success,
  error,
}

enum ActionStatus {
  initial,
  processing,
  success,
  error,
}

enum PestAlertsTab {
  nearby,
  myAlerts,
}

class PestAlertsState extends Equatable {
  // Listas de alertas
  final List<PestAlert> nearbyAlerts;
  final List<PestAlert> myAlerts;

  // Estados
  final PestAlertsStatus nearbyStatus;
  final PestAlertsStatus myAlertsStatus;
  final PhotoSelectionStatus photoSelectionStatus;
  final SubmissionStatus submissionStatus;
  final ActionStatus actionStatus;
  final String? errorMessage;

  // Tab seleccionado
  final PestAlertsTab activeTab;

  // Ubicación del usuario
  final double? userLatitude;
  final double? userLongitude;

  // Filtros
  final double filterRadiusKm;
  final int filterDaysLimit;
  final List<PestType> filterPestTypes;
  final List<Severity> filterSeverities;
  final bool includeResolved;

  // Selección
  final PestAlert? selectedAlert;
  final Uint8List? selectedPhotoBytes;
  final PestAlert? lastCreatedAlert;

  const PestAlertsState({
    this.nearbyAlerts = const [],
    this.myAlerts = const [],
    this.nearbyStatus = PestAlertsStatus.initial,
    this.myAlertsStatus = PestAlertsStatus.initial,
    this.photoSelectionStatus = PhotoSelectionStatus.initial,
    this.submissionStatus = SubmissionStatus.initial,
    this.actionStatus = ActionStatus.initial,
    this.errorMessage,
    this.activeTab = PestAlertsTab.nearby,
    this.userLatitude,
    this.userLongitude,
    this.filterRadiusKm = 10.0,
    this.filterDaysLimit = 30,
    this.filterPestTypes = const [],
    this.filterSeverities = const [],
    this.includeResolved = false,
    this.selectedAlert,
    this.selectedPhotoBytes,
    this.lastCreatedAlert,
  });

  // Getters de conveniencia
  bool get isNearbyLoading => nearbyStatus == PestAlertsStatus.loading;
  bool get isMyAlertsLoading => myAlertsStatus == PestAlertsStatus.loading;
  bool get isNearbyEmpty => nearbyStatus == PestAlertsStatus.empty;
  bool get isMyAlertsEmpty => myAlertsStatus == PestAlertsStatus.empty;
  bool get hasError => errorMessage != null;
  bool get hasPhotoSelected => selectedPhotoBytes != null;
  bool get isSubmitting => submissionStatus == SubmissionStatus.submitting;
  bool get isSubmissionSuccess => submissionStatus == SubmissionStatus.success;
  bool get isProcessingAction => actionStatus == ActionStatus.processing;
  bool get hasLocation => userLatitude != null && userLongitude != null;

  /// Alertas cercanas ordenadas por distancia (el backend ya las ordena)
  List<PestAlert> get sortedNearbyAlerts => nearbyAlerts;

  /// Alertas de alta severidad cercanas (para destacar)
  List<PestAlert> get highSeverityNearby => nearbyAlerts
      .where((a) => a.severity == Severity.high || a.severity == Severity.critical)
      .toList();

  /// Filtros activos como texto
  List<String> get activeFilters {
    final filters = <String>[];
    if (filterRadiusKm != 10.0) filters.add('${filterRadiusKm.toStringAsFixed(0)} km');
    if (filterDaysLimit != 30) filters.add('$filterDaysLimit días');
    if (filterPestTypes.isNotEmpty) filters.add('${filterPestTypes.length} tipos');
    if (filterSeverities.isNotEmpty) filters.add('${filterSeverities.length} severidades');
    if (includeResolved) filters.add('Incluye resueltas');
    return filters;
  }

  PestAlertsState copyWith({
    List<PestAlert>? nearbyAlerts,
    List<PestAlert>? myAlerts,
    PestAlertsStatus? nearbyStatus,
    PestAlertsStatus? myAlertsStatus,
    PhotoSelectionStatus? photoSelectionStatus,
    SubmissionStatus? submissionStatus,
    ActionStatus? actionStatus,
    String? errorMessage,
    PestAlertsTab? activeTab,
    double? userLatitude,
    double? userLongitude,
    double? filterRadiusKm,
    int? filterDaysLimit,
    List<PestType>? filterPestTypes,
    List<Severity>? filterSeverities,
    bool? includeResolved,
    PestAlert? selectedAlert,
    Uint8List? selectedPhotoBytes,
    PestAlert? lastCreatedAlert,
  }) {
    return PestAlertsState(
      nearbyAlerts: nearbyAlerts ?? this.nearbyAlerts,
      myAlerts: myAlerts ?? this.myAlerts,
      nearbyStatus: nearbyStatus ?? this.nearbyStatus,
      myAlertsStatus: myAlertsStatus ?? this.myAlertsStatus,
      photoSelectionStatus: photoSelectionStatus ?? this.photoSelectionStatus,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      actionStatus: actionStatus ?? this.actionStatus,
      errorMessage: errorMessage,
      activeTab: activeTab ?? this.activeTab,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
      filterRadiusKm: filterRadiusKm ?? this.filterRadiusKm,
      filterDaysLimit: filterDaysLimit ?? this.filterDaysLimit,
      filterPestTypes: filterPestTypes ?? this.filterPestTypes,
      filterSeverities: filterSeverities ?? this.filterSeverities,
      includeResolved: includeResolved ?? this.includeResolved,
      selectedAlert: selectedAlert ?? this.selectedAlert,
      selectedPhotoBytes: selectedPhotoBytes ?? this.selectedPhotoBytes,
      lastCreatedAlert: lastCreatedAlert ?? this.lastCreatedAlert,
    );
  }

  @override
  List<Object?> get props => [
        nearbyAlerts,
        myAlerts,
        nearbyStatus,
        myAlertsStatus,
        photoSelectionStatus,
        submissionStatus,
        actionStatus,
        errorMessage,
        activeTab,
        userLatitude,
        userLongitude,
        filterRadiusKm,
        filterDaysLimit,
        filterPestTypes,
        filterSeverities,
        includeResolved,
        selectedAlert,
        selectedPhotoBytes,
        lastCreatedAlert,
      ];
}
