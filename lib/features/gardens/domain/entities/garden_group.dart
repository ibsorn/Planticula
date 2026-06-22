import 'package:equatable/equatable.dart';

/// Entidad de dominio que representa un Grupo dentro de un Jardín.
///
/// Jerarquía:  Usuario → Jardín → Grupo → Planta
///
/// Los grupos son opcionales. Una planta puede pertenecer a un jardín
/// sin pertenecer a ningún grupo (directamente en la raíz del jardín).
///
/// Ejemplos de grupos:  "Tomates", "Suculentas", "Zona de sombra", "Semillero"
class GardenGroup extends Equatable {
  final String id;

  /// Jardín al que pertenece este grupo
  final String gardenId;

  final String userId;

  final String name;
  final String? description;

  /// Icono opcional (hereda del jardín padre en la UI si es null)
  final String? icon;

  /// Color opcional en formato #RRGGBB (hereda del jardín padre si es null)
  final String? color;

  /// Orden dentro del jardín
  final int sortOrder;

  /// Número de plantas en este grupo (calculado en cliente)
  final int plantCount;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GardenGroup({
    required this.id,
    required this.gardenId,
    required this.userId,
    required this.name,
    this.description,
    this.icon,
    this.color,
    this.sortOrder = 0,
    this.plantCount = 0,
    this.createdAt,
    this.updatedAt,
  });

  String get displayName => name;

  /// Color parseado como int para Color(value).
  /// Si no tiene color propio retorna null (la UI usa el color del jardín padre).
  int? get colorValue {
    if (color == null) return null;
    final hex = color!.replaceFirst('#', '');
    return int.parse('FF$hex', radix: 16);
  }

  GardenGroup copyWith({
    String? id,
    String? gardenId,
    String? userId,
    String? name,
    String? description,
    String? icon,
    String? color,
    int? sortOrder,
    int? plantCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GardenGroup(
      id: id ?? this.id,
      gardenId: gardenId ?? this.gardenId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      plantCount: plantCount ?? this.plantCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id, gardenId, userId, name, description, icon, color,
        sortOrder, plantCount, createdAt, updatedAt,
      ];
}
