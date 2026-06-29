import 'package:planticula/features/plants/domain/entities/care_log.dart';

/// Modelo de datos para [CareLog] — mapeo con Supabase (tabla care_logs).
class CareLogModel extends CareLog {
  const CareLogModel({
    required super.id,
    required super.plantId,
    required super.userId,
    super.organizationId,
    required super.type,
    required super.eventDate,
    super.note,
    super.metadata,
    super.createdAt,
  });

  factory CareLogModel.fromJson(Map<String, dynamic> json) {
    return CareLogModel(
      id:             json['id']              as String,
      plantId:        json['plant_id']        as String,
      userId:         json['user_id']         as String,
      organizationId: json['organization_id'] as String?,
      type:           CareLogType.fromString(json['type'] as String?),
      eventDate:      DateTime.parse(json['event_date'] as String),
      note:           json['note']            as String?,
      metadata:       (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
