import 'package:equatable/equatable.dart';

/// Tipos de jardín — determina el icono y contexto por defecto.
enum GardenType {
  personal,
  balcony,
  terrace,
  greenhouse,
  indoor,
  outdoor,
  allotment,
  other;

  String get displayName => switch (this) {
        GardenType.personal   => 'Personal',
        GardenType.balcony    => 'Balcón',
        GardenType.terrace    => 'Terraza',
        GardenType.greenhouse => 'Invernadero',
        GardenType.indoor     => 'Interior',
        GardenType.outdoor    => 'Exterior',
        GardenType.allotment  => 'Huerto',
        GardenType.other      => 'Otro',
      };

  /// Icono Material por defecto para cada tipo (cuando el usuario no elige uno).
  String get defaultIcon => switch (this) {
        GardenType.personal   => 'garden',
        GardenType.balcony    => 'balcony',
        GardenType.terrace    => 'terrace',
        GardenType.greenhouse => 'greenhouse',
        GardenType.indoor     => 'indoor',
        GardenType.outdoor    => 'garden',
        GardenType.allotment  => 'vegetable',
        GardenType.other      => 'other',
      };

  static GardenType fromString(String? s) =>
      GardenType.values.firstWhere(
        (e) => e.name == s,
        orElse: () => GardenType.personal,
      );
}

/// Iconos disponibles para jardines.
/// Cada valor corresponde a un clave conocida por la UI (se mapea a IconData).
enum GardenIcon {
  garden,
  balcony,
  terrace,
  greenhouse,
  indoor,
  potted,
  vegetable,
  flower,
  herb,
  forest,
  other;

  static GardenIcon fromString(String? s) =>
      GardenIcon.values.firstWhere(
        (e) => e.name == s,
        orElse: () => GardenIcon.garden,
      );
}

/// Entidad de dominio que representa un Jardín del usuario.
///
/// Jerarquía:  Usuario → Jardín → Grupo → Planta
///
/// Un usuario puede tener varios jardines (balcón, invernadero, interior…).
/// Cada jardín puede tener grupos opcionales para organizar las plantas.
class Garden extends Equatable {
  final String id;
  final String userId;

  final String name;
  final String? description;

  /// Clave de icono (ver [GardenIcon])
  final String icon;

  /// Color hexadecimal (#RRGGBB) para identificar visualmente el jardín
  final String color;

  final GardenType type;

  /// El jardín por defecto se crea automáticamente; no se puede eliminar
  final bool isDefault;

  /// Orden de visualización entre jardines del usuario
  final int sortOrder;

  /// Número de plantas en este jardín (calculado en cliente, no almacenado en DB)
  final int plantCount;

  /// Número de grupos en este jardín (calculado en cliente, no almacenado en DB)
  final int groupCount;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Garden({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.icon = 'garden',
    this.color = '#4CAF50',
    this.type = GardenType.personal,
    this.isDefault = false,
    this.sortOrder = 0,
    this.plantCount = 0,
    this.groupCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Nombre a mostrar (siempre hay nombre, pero por comodidad)
  String get displayName => name;

  /// Color parseado como int para Color(value)
  int get colorValue {
    final hex = color.replaceFirst('#', '');
    return int.parse('FF$hex', radix: 16);
  }

  /// Icono parseado
  GardenIcon get gardenIcon => GardenIcon.fromString(icon);

  Garden copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? icon,
    String? color,
    GardenType? type,
    bool? isDefault,
    int? sortOrder,
    int? plantCount,
    int? groupCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Garden(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      plantCount: plantCount ?? this.plantCount,
      groupCount: groupCount ?? this.groupCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, userId, name, description, icon, color, type,
        isDefault, sortOrder, plantCount, groupCount, createdAt, updatedAt,
      ];
}
