import 'package:equatable/equatable.dart';

/// Entidad PestAlert - Representa una alerta de plaga reportada
///
/// Flujo:
/// 1. Usuario detecta plaga y toma foto
/// 2. Selecciona tipo de plaga y gravedad
/// 3. Obtiene ubicación GPS automática o manual
/// 4. Sube foto a Storage y crea registro en pest_alerts
/// 5. Otros usuarios pueden ver alertas cercanas ordenadas por distancia
class PestAlert extends Equatable {
  final String id;
  final String userId;

  // Información de la plaga
  final String? photoUrl; // URL en Supabase Storage (opcional pero recomendado)
  final PestType pestType; // Tipo de plaga identificada
  final String? customPestName; // Si elige "otro", nombre personalizado
  final Severity severity; // Gravedad de la infestación

  // Ubicación (requerida para alertas geográficas)
  final double latitude;
  final double longitude;
  final String? locationName; // Nombre descriptivo opcional (ej: "Mi jardín")

  // Metadata
  final String? notes; // Notas adicionales del usuario
  final DateTime reportedAt;
  final DateTime? updatedAt;

  // Estado de la alerta
  final AlertStatus status;
  final int? confirmedByCount; // Cuántos usuarios confirmaron ver la misma plaga
  final bool isResolved; // Si la plaga fue tratada/eliminada
  final DateTime? resolvedAt;

  // Datos calculados (no se guardan en BD, se calculan en queries)
  final double? distanceKm; // Distancia desde la ubicación del usuario

  const PestAlert({
    required this.id,
    required this.userId,
    this.photoUrl,
    required this.pestType,
    this.customPestName,
    required this.severity,
    required this.latitude,
    required this.longitude,
    this.locationName,
    this.notes,
    required this.reportedAt,
    this.updatedAt,
    this.status = AlertStatus.active,
    this.confirmedByCount,
    this.isResolved = false,
    this.resolvedAt,
    this.distanceKm,
  });

  PestAlert copyWith({
    String? id,
    String? userId,
    String? photoUrl,
    PestType? pestType,
    String? customPestName,
    Severity? severity,
    double? latitude,
    double? longitude,
    String? locationName,
    String? notes,
    DateTime? reportedAt,
    DateTime? updatedAt,
    AlertStatus? status,
    int? confirmedByCount,
    bool? isResolved,
    DateTime? resolvedAt,
    double? distanceKm,
  }) {
    return PestAlert(
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

  /// Crea una alerta para nuevo reporte (sin ID)
  factory PestAlert.create({
    required String userId,
    String? photoUrl,
    required PestType pestType,
    String? customPestName,
    required Severity severity,
    required double latitude,
    required double longitude,
    String? locationName,
    String? notes,
  }) {
    return PestAlert(
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

  /// Formato legible del tipo de plaga
  String get pestTypeDisplay {
    if (pestType == PestType.other && customPestName != null) {
      return customPestName!;
    }
    return pestType.displayName;
  }

  /// Formato legible de la ubicación
  String get locationDisplay {
    if (locationName != null && locationName!.isNotEmpty) {
      return locationName!;
    }
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  /// Formato legible de distancia
  String? get distanceDisplay {
    if (distanceKm == null) return null;
    if (distanceKm! < 1) {
      return '${(distanceKm! * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  /// Indica si la alerta es del usuario actual
  bool isOwnedBy(String userId) => this.userId == userId;

  /// Indica si se puede confirmar (no es del usuario y está activa)
  bool canBeConfirmedBy(String userId) =>
      !isOwnedBy(userId) && status == AlertStatus.active && !isResolved;

  @override
  List<Object?> get props => [
        id,
        userId,
        photoUrl,
        pestType,
        customPestName,
        severity,
        latitude,
        longitude,
        locationName,
        notes,
        reportedAt,
        updatedAt,
        status,
        confirmedByCount,
        isResolved,
        resolvedAt,
        distanceKm,
      ];
}

/// Tipos de plagas comunes en plantas
enum PestType {
  aphids('Pulgón', 'Pequeños insectos verdes/negros que chupan savia'),
  spiderMites('Ácaro Rojo', 'Ácaros diminutos que causan decoloración'),
  mealybugs('Cochinilla Algodonosa', 'Insectos blancos algodonosos'),
  scale('Cochinilla Escama', 'Escamas marrones en tallos y hojas'),
  whiteflies('Mosca Blanca', 'Pequeñas moscas blancas que vuelan'),
  thrips('Trips', 'Insectos alargados que dañan flores y hojas'),
  fungusGnats('Mosquito del Mantillo', 'Pequeñas moscas en sustrato húmedo'),
  caterpillars('Oruga', 'Larvas que mastican hojas'),
  snails('Caracol/Babosa', 'Moluscos que comen hojas y tallos'),
  mold('Hongo/Moho', 'Crecimiento fungoso en hojas o sustrato'),
  rootRot('Pudrición de Raíces', 'Raíces marrones y blandás por exceso de agua'),
  leafMiner('Minador de Hojas', 'Larvas que crean túneles en hojas'),
  other('Otra', 'Especificar en nombre personalizado');

  final String displayName;
  final String description;

  const PestType(this.displayName, this.description);
}

/// Niveles de severidad/gravedad
enum Severity {
  low('Baja', 'Pocas plagas, planta saludable', 0xFF4CAF50),
  medium('Media', 'Infestación moderada, requiere atención', 0xFFFF9800),
  high('Alta', 'Infestación severa, riesgo para planta', 0xFFF44336),
  critical('Crítica', 'Emergencia, planta puede morir', 0xFF9C27B0);

  final String displayName;
  final String description;
  final int colorValue;

  const Severity(this.displayName, this.description, this.colorValue);
}

/// Estados de la alerta
enum AlertStatus {
  active('Activa', 'Alerta visible para todos'),
  underReview('En Revisión', 'Verificando información'),
  resolved('Resuelta', 'Plaga tratada/eliminada'),
  falsePositive('Falso Positivo', 'No era una plaga'),
  duplicate('Duplicada', 'Alerta repetida');

  final String displayName;
  final String description;

  const AlertStatus(this.displayName, this.description);
}

/// Extensiones para parsear enums
extension PestTypeExtension on String {
  PestType? toPestType() {
    return PestType.values.firstWhere(
      (e) => e.name == this,
      orElse: () => PestType.other,
    );
  }
}

extension SeverityExtension on String {
  Severity? toSeverity() {
    return Severity.values.firstWhere(
      (e) => e.name == this,
      orElse: () => Severity.medium,
    );
  }
}

extension AlertStatusExtension on String {
  AlertStatus? toAlertStatus() {
    return AlertStatus.values.firstWhere(
      (e) => e.name == this,
      orElse: () => AlertStatus.active,
    );
  }
}
