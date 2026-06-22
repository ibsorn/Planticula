import 'package:planticula/features/gardens/domain/entities/garden_group.dart';

/// Modelo de datos para [GardenGroup] — mapeo con Supabase.
class GardenGroupModel extends GardenGroup {
  const GardenGroupModel({
    required super.id,
    required super.gardenId,
    required super.userId,
    required super.name,
    super.description,
    super.icon,
    super.color,
    super.sortOrder,
    super.plantCount,
    super.createdAt,
    super.updatedAt,
  });

  factory GardenGroupModel.fromJson(Map<String, dynamic> json) {
    return GardenGroupModel(
      id:          json['id']          as String,
      gardenId:    json['garden_id']   as String,
      userId:      json['user_id']     as String,
      name:        json['name']        as String,
      description: json['description'] as String?,
      icon:        json['icon']        as String?,
      color:       json['color']       as String?,
      sortOrder:   json['sort_order']  as int?  ?? 0,
      plantCount:  json['plant_count'] as int?  ?? 0,
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
        'garden_id':   gardenId,
        'user_id':     userId,
        'name':        name,
        'description': description,
        'icon':        icon,
        'color':       color,
        'sort_order':  sortOrder,
        'created_at':  createdAt?.toIso8601String(),
        'updated_at':  updatedAt?.toIso8601String(),
      };

  factory GardenGroupModel.fromDomain(GardenGroup g) => GardenGroupModel(
        id: g.id, gardenId: g.gardenId, userId: g.userId, name: g.name,
        description: g.description, icon: g.icon, color: g.color,
        sortOrder: g.sortOrder, plantCount: g.plantCount,
        createdAt: g.createdAt, updatedAt: g.updatedAt,
      );

  static Map<String, dynamic> createJson({
    required String userId,
    required String gardenId,
    required String name,
    String? description,
    String? icon,
    String? color,
    int sortOrder = 0,
  }) =>
      {
        'user_id':     userId,
        'garden_id':   gardenId,
        'name':        name,
        'description': description,
        'icon':        icon,
        'color':       color,
        'sort_order':  sortOrder,
      };
}
