import 'package:equatable/equatable.dart';

/// Tipo de evento de cuidado registrado en el historial de una planta.
enum CareLogType {
  watering,
  transplant,
  fertilize,
  prune,
  note;

  String get displayName => switch (this) {
        CareLogType.watering   => 'Riego',
        CareLogType.transplant => 'Trasplante',
        CareLogType.fertilize  => 'Abonado',
        CareLogType.prune      => 'Poda',
        CareLogType.note       => 'Nota',
      };

  static CareLogType fromString(String? s) => CareLogType.values.firstWhere(
        (e) => e.name == s,
        orElse: () => CareLogType.note,
      );
}

/// Un evento del historial de cuidados de una planta (append-only).
class CareLog extends Equatable {
  final String id;
  final String plantId;
  final String userId;
  final String? organizationId;
  final CareLogType type;

  /// Cuándo ocurrió el evento (puede ser retroactivo).
  final DateTime eventDate;

  final String? note;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  const CareLog({
    required this.id,
    required this.plantId,
    required this.userId,
    this.organizationId,
    required this.type,
    required this.eventDate,
    this.note,
    this.metadata = const {},
    this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, plantId, userId, organizationId, type, eventDate, note, metadata, createdAt];
}
