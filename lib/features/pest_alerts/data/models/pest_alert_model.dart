import 'package:planticula/features/pest_alerts/domain/entities/pest_alert.dart' as domain;

/// Modelo de datos para PestAlert - Mapeo con tabla Supabase
///
/// Tabla: pest_alerts
class PestAlertModel extends domain.PestAlert {
  const PestAlertModel({
    required super.id,
    required super.userId,
    super.photoUrl,
    required super.pestType,
    super.customPestName,
    required super.severity,
    required super.latitude,
    required super.longitude,
    super.locationName,
    super.notes,
    required super.reportedAt,
    super.updatedAt,
    super.status = domain.AlertStatus.active,
    super.confirmedByCount,
    super.isResolved = false,
    super.resolvedAt,
    super.distanceKm,
  });

  /// Crea un modelo desde JSON de Supabase
  factory PestAlertModel.fromJson(Map<String, dynamic> json) {
    return PestAlertModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      photoUrl: json['photo_url'] as String?,
      pestType: (json['pest_type'] as String?)?.toPestType() ?? domain.PestType.other,
      customPestName: json['custom_pest_name'] as String?,
      severity: (json['severity'] as String?)?.toSeverity() ?? domain.Severity.medium,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      locationName: json['location_name'] as String?,
      notes: json['notes'] as String?,
      reportedAt: json['reported_at'] != null
          ? DateTime.parse(json['reported_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      status: (json['status'] as String?)?.toAlertStatus() ?? domain.AlertStatus.active,
      confirmedByCount: json['confirmed_by_count'] as int?,
      isResolved: json['is_resolved'] as bool? ?? false,
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      distanceKm: json['distance_km'] != null
          ? (json['distance_km'] as num).toDouble()
          : null,
    );
  }

  /// Convierte a JSON para enviar a Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'photo_url': photoUrl,
      'pest_type': pestType.name,
      'custom_pest_name': customPestName,
      'severity': severity.name,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'notes': notes,
      'reported_at': reportedAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'status': status.name,
      'confirmed_by_count': confirmedByCount ?? 0,
      'is_resolved': isResolved,
      'resolved_at': resolvedAt?.toIso8601String(),
    };
  }

  /// Crea un modelo desde la entidad de dominio
  factory PestAlertModel.fromDomain(domain.PestAlert alert) {
    return PestAlertModel(
      id: alert.id,
      userId: alert.userId,
      photoUrl: alert.photoUrl,
      pestType: alert.pestType,
      customPestName: alert.customPestName,
      severity: alert.severity,
      latitude: alert.latitude,
      longitude: alert.longitude,
      locationName: alert.locationName,
      notes: alert.notes,
      reportedAt: alert.reportedAt,
      updatedAt: alert.updatedAt,
      status: alert.status,
      confirmedByCount: alert.confirmedByCount,
      isResolved: alert.isResolved,
      resolvedAt: alert.resolvedAt,
      distanceKm: alert.distanceKm,
    );
  }

  /// Crea modelo para nuevo reporte (sin ID, timestamps se generan en DB)
  factory PestAlertModel.create({
    required String userId,
    String? photoUrl,
    required domain.PestType pestType,
    String? customPestName,
    required domain.Severity severity,
    required double latitude,
    required double longitude,
    String? locationName,
    String? notes,
  }) {
    return PestAlertModel(
      id: '', // Se genera en Supabase
      userId: userId,
      photoUrl: photoUrl,
      pestType: pestType,
      customPestName: customPestName,
      severity: severity,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      notes: notes,
      reportedAt: DateTime.now(),
    );
  }

  /// Crea una copia con modificaciones
  PestAlertModel copyWithModel({
    String? id,
    String? userId,
    String? photoUrl,
    domain.PestType? pestType,
    String? customPestName,
    domain.Severity? severity,
    double? latitude,
    double? longitude,
    String? locationName,
    String? notes,
    DateTime? reportedAt,
    DateTime? updatedAt,
    domain.AlertStatus? status,
    int? confirmedByCount,
    bool? isResolved,
    DateTime? resolvedAt,
    double? distanceKm,
  }) {
    return PestAlertModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      photoUrl: photoUrl ?? this.photoUrl,
      pestType: pestType ?? this.pestType,
      customPestName: customPestName ?? this.customPestName,
      severity: severity ?? this.severity,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      notes: notes ?? this.notes,
      reportedAt: reportedAt ?? this.reportedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      confirmedByCount: confirmedByCount ?? this.confirmedByCount,
      isResolved: isResolved ?? this.isResolved,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      distanceKm: distanceKm ?? this.distanceKm,
    );
  }

  /// Marca como resuelta
  PestAlertModel markAsResolved() {
    return copyWithModel(
      status: domain.AlertStatus.resolved,
      isResolved: true,
      resolvedAt: DateTime.now(),
    );
  }

  /// Incrementa contador de confirmaciones
  PestAlertModel incrementConfirmations() {
    return copyWithModel(
      confirmedByCount: (confirmedByCount ?? 0) + 1,
    );
  }
}

/// Request para crear alerta
class CreatePestAlertRequest {
  final String? photoUrl;
  final domain.PestType pestType;
  final String? customPestName;
  final domain.Severity severity;
  final double latitude;
  final double longitude;
  final String? locationName;
  final String? notes;

  const CreatePestAlertRequest({
    this.photoUrl,
    required this.pestType,
    this.customPestName,
    required this.severity,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.notes,
  });

  Map<String, dynamic> toJson(String userId) {
    return {
      'user_id': userId,
      'photo_url': photoUrl,
      'pest_type': pestType.name,
      'custom_pest_name': customPestName,
      'severity': severity.name,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'notes': notes,
      'status': domain.AlertStatus.active.name,
      'confirmed_by_count': 0,
      'is_resolved': false,
    };
  }
}

/// Filtros para consultar alertas cercanas
class NearbyAlertsFilter {
  final double latitude;
  final double longitude;
  final double radiusKm; // Radio de búsqueda en kilómetros
  final int? daysLimit; // Solo alertas de los últimos X días
  final List<domain.PestType>? pestTypes; // Filtrar por tipos específicos
  final List<domain.Severity>? severities; // Filtrar por severidad
  final bool includeResolved; // Incluir alertas resueltas
  final int limit; // Máximo de resultados
  final int offset; // Para paginación

  const NearbyAlertsFilter({
    required this.latitude,
    required this.longitude,
    this.radiusKm = 10.0, // Default 10km
    this.daysLimit = 30, // Default últimos 30 días
    this.pestTypes,
    this.severities,
    this.includeResolved = false,
    this.limit = 50,
    this.offset = 0,
  });

  /// Valida que los parámetros sean correctos
  bool get isValid {
    return latitude >= -90 && latitude <= 90 &&
           longitude >= -180 && longitude <= 180 &&
           radiusKm > 0 &&
           limit > 0 && limit <= 100;
  }

  Map<String, dynamic> toQueryParams() {
    return {
      'lat': latitude,
      'lng': longitude,
      'radius_km': radiusKm,
      if (daysLimit != null) 'days': daysLimit,
      if (pestTypes != null && pestTypes!.isNotEmpty)
        'pest_types': pestTypes!.map((e) => e.name).toList(),
      if (severities != null && severities!.isNotEmpty)
        'severities': severities!.map((e) => e.name).toList(),
      'include_resolved': includeResolved,
      'limit': limit,
      'offset': offset,
    };
  }
}
