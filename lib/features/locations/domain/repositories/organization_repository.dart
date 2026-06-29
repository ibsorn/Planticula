import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/locations/domain/entities/organization.dart';

/// Contrato del repositorio de organizaciones (multi-tenant).
abstract class OrganizationRepository {
  /// Devuelve las organizaciones de las que el usuario es miembro.
  Future<Result<List<Organization>>> getMyOrganizations();

  /// Devuelve (o crea) la organización personal del usuario.
  /// Garantiza que siempre hay al menos una organización disponible.
  Future<Result<Organization>> getOrCreateDefaultOrganization();
}
