import 'package:equatable/equatable.dart';

/// Nivel de una localización dentro del árbol jerárquico.
///
/// Jerarquía:  site (vivero) → zone (invernadero/sector) → bench (mesa/hilera)
enum LocationKind {
  site,
  zone,
  bench;

  String get displayName => switch (this) {
        LocationKind.site  => 'Vivero',
        LocationKind.zone  => 'Zona',
        LocationKind.bench => 'Mesa',
      };

  /// Nivel del hijo permitido por debajo de este (null = no admite hijos).
  LocationKind? get childKind => switch (this) {
        LocationKind.site  => LocationKind.zone,
        LocationKind.zone  => LocationKind.bench,
        LocationKind.bench => null,
      };

  static LocationKind fromString(String? s) => LocationKind.values.firstWhere(
        (e) => e.name == s,
        orElse: () => LocationKind.site,
      );
}

/// Entidad de dominio que representa un nodo del árbol de localización.
///
/// Es una estructura recursiva (adjacency list): cada nodo apunta a su padre
/// vía [parentId]. Un nodo raíz (`kind == site`) tiene [parentId] == null.
class Location extends Equatable {
  final String id;
  final String organizationId;

  /// Nodo padre. Null solo para nodos raíz (kind == site).
  final String? parentId;

  final LocationKind kind;

  final String name;
  final String? description;

  /// Clave de icono (texto libre, mapeada a IconData en la UI).
  final String icon;

  /// Color hexadecimal (#RRGGBB).
  final String color;

  /// Datos extra por nivel (lat/lon, área m², timezone, tipo de invernadero…).
  final Map<String, dynamic> metadata;

  final bool isDefault;
  final int sortOrder;

  /// Número de plantas asignadas a este nodo (calculado en cliente).
  final int plantCount;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Location({
    required this.id,
    required this.organizationId,
    this.parentId,
    this.kind = LocationKind.site,
    required this.name,
    this.description,
    this.icon = 'garden',
    this.color = '#4CAF50',
    this.metadata = const {},
    this.isDefault = false,
    this.sortOrder = 0,
    this.plantCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  String get displayName => name;

  bool get isRoot => parentId == null;

  /// Color parseado como int para Color(value).
  int get colorValue {
    final hex = color.replaceFirst('#', '');
    return int.parse('FF$hex', radix: 16);
  }

  Location copyWith({
    String? id,
    String? organizationId,
    String? parentId,
    LocationKind? kind,
    String? name,
    String? description,
    String? icon,
    String? color,
    Map<String, dynamic>? metadata,
    bool? isDefault,
    int? sortOrder,
    int? plantCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearParentId = false,
  }) {
    return Location(
      id: id ?? this.id,
      organizationId: organizationId ?? this.organizationId,
      parentId: clearParentId ? null : (parentId ?? this.parentId),
      kind: kind ?? this.kind,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      metadata: metadata ?? this.metadata,
      isDefault: isDefault ?? this.isDefault,
      sortOrder: sortOrder ?? this.sortOrder,
      plantCount: plantCount ?? this.plantCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, organizationId, parentId, kind, name, description, icon, color,
        metadata, isDefault, sortOrder, plantCount, createdAt, updatedAt,
      ];
}
