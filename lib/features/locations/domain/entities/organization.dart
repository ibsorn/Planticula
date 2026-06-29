import 'package:equatable/equatable.dart';

/// Entidad de dominio que representa una Organización (cliente B2B / tenant).
///
/// La organización es la raíz del modelo multi-tenant: agrupa miembros y
/// localizaciones. Cada usuario tiene además una organización "personal"
/// (`isPersonal == true`) creada automáticamente, equivalente al antiguo
/// jardín por defecto del modelo B2C.
class Organization extends Equatable {
  final String id;
  final String name;
  final bool isPersonal;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Organization({
    required this.id,
    required this.name,
    this.isPersonal = false,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  Organization copyWith({
    String? id,
    String? name,
    bool? isPersonal,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      isPersonal: isPersonal ?? this.isPersonal,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, name, isPersonal, createdBy, createdAt, updatedAt];
}
