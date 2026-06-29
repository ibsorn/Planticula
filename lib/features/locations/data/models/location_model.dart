import 'package:planticula/features/locations/domain/entities/location.dart';

/// Modelo de datos para [Location] — mapeo con Supabase.
class LocationModel extends Location {
  const LocationModel({
    required super.id,
    required super.organizationId,
    super.parentId,
    super.kind,
    required super.name,
    super.description,
    super.icon,
    super.color,
    super.metadata,
    super.isDefault,
    super.sortOrder,
    super.plantCount,
    super.createdAt,
    super.updatedAt,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      id:             json['id']              as String,
      organizationId: json['organization_id'] as String,
      parentId:       json['parent_id']       as String?,
      kind:           LocationKind.fromString(json['kind'] as String?),
      name:           json['name']            as String,
      description:    json['description']     as String?,
      icon:           json['icon']            as String? ?? 'garden',
      color:          json['color']           as String? ?? '#4CAF50',
      metadata:       (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
      isDefault:      json['is_default']      as bool? ?? false,
      sortOrder:      json['sort_order']      as int?  ?? 0,
      // plant_count es un campo calculado opcional (no parte de la tabla base).
      plantCount:     json['plant_count']     as int?  ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id':              id,
        'organization_id': organizationId,
        'parent_id':       parentId,
        'kind':            kind.name,
        'name':            name,
        'description':     description,
        'icon':            icon,
        'color':           color,
        'metadata':        metadata,
        'is_default':      isDefault,
        'sort_order':      sortOrder,
        'created_at':      createdAt?.toIso8601String(),
        'updated_at':      updatedAt?.toIso8601String(),
      };

  factory LocationModel.fromDomain(Location l) => LocationModel(
        id: l.id, organizationId: l.organizationId, parentId: l.parentId,
        kind: l.kind, name: l.name, description: l.description, icon: l.icon,
        color: l.color, metadata: l.metadata, isDefault: l.isDefault,
        sortOrder: l.sortOrder, plantCount: l.plantCount,
        createdAt: l.createdAt, updatedAt: l.updatedAt,
      );
}
