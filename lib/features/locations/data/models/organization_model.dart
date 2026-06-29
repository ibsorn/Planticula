import 'package:planticula/features/locations/domain/entities/organization.dart';

/// Modelo de datos para [Organization] — mapeo con Supabase.
class OrganizationModel extends Organization {
  const OrganizationModel({
    required super.id,
    required super.name,
    super.isPersonal,
    super.createdBy,
    super.createdAt,
    super.updatedAt,
  });

  factory OrganizationModel.fromJson(Map<String, dynamic> json) {
    return OrganizationModel(
      id:         json['id']          as String,
      name:       json['name']        as String,
      isPersonal: json['is_personal'] as bool? ?? false,
      createdBy:  json['created_by']  as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id':           id,
        'name':         name,
        'is_personal':  isPersonal,
        'created_by':   createdBy,
        'created_at':   createdAt?.toIso8601String(),
        'updated_at':   updatedAt?.toIso8601String(),
      };
}
