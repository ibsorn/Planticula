import 'package:planticula/features/gardens/domain/entities/garden.dart';

/// Modelo de datos para [Garden] — mapeo con Supabase.
class GardenModel extends Garden {
  const GardenModel({
    required super.id,
    required super.userId,
    required super.name,
    super.description,
    super.icon,
    super.color,
    super.type,
    super.isDefault,
    super.sortOrder,
    super.plantCount,
    super.groupCount,
    super.createdAt,
    super.updatedAt,
  });

  factory GardenModel.fromJson(Map<String, dynamic> json) {
    return GardenModel(
      id:          json['id']          as String,
      userId:      json['user_id']     as String,
      name:        json['name']        as String,
      description: json['description'] as String?,
      icon:        json['icon']        as String? ?? 'garden',
      color:       json['color']       as String? ?? '#4CAF50',
      type:        GardenType.fromString(json['type'] as String?),
      isDefault:   json['is_default']  as bool? ?? false,
      sortOrder:   json['sort_order']  as int?  ?? 0,
      // plant_count / group_count son campos calculados devueltos por
      // queries con agregados (no forman parte de la tabla base).
      plantCount:  json['plant_count'] as int?  ?? 0,
      groupCount:  json['group_count'] as int?  ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id':          id,
        'user_id':     userId,
        'name':        name,
        'description': description,
        'icon':        icon,
        'color':       color,
        'type':        type.name,
        'is_default':  isDefault,
        'sort_order':  sortOrder,
        'created_at':  createdAt?.toIso8601String(),
        'updated_at':  updatedAt?.toIso8601String(),
      };

  factory GardenModel.fromDomain(Garden g) => GardenModel(
        id: g.id, userId: g.userId, name: g.name,
        description: g.description, icon: g.icon, color: g.color,
        type: g.type, isDefault: g.isDefault, sortOrder: g.sortOrder,
        plantCount: g.plantCount, groupCount: g.groupCount,
        createdAt: g.createdAt, updatedAt: g.updatedAt,
      );

  /// Crea el JSON de inserción para un nuevo jardín (sin id ni timestamps).
  static Map<String, dynamic> createJson({
    required String userId,
    required String name,
    String? description,
    String icon = 'garden',
    String color = '#4CAF50',
    GardenType type = GardenType.personal,
    bool isDefault = false,
    int sortOrder = 0,
  }) =>
      {
        'user_id':     userId,
        'name':        name,
        'description': description,
        'icon':        icon,
        'color':       color,
        'type':        type.name,
        'is_default':  isDefault,
        'sort_order':  sortOrder,
      };
}
