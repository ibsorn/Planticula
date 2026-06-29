import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/locations/data/datasources/organization_remote_datasource.dart';
import 'package:planticula/features/locations/domain/entities/organization.dart';
import 'package:planticula/features/locations/domain/repositories/organization_repository.dart';

class OrganizationRepositoryImpl implements OrganizationRepository {
  final OrganizationRemoteDataSource _ds;

  OrganizationRepositoryImpl(this._ds);

  @override
  Future<Result<List<Organization>>> getMyOrganizations() =>
      _ds.getMyOrganizations();

  @override
  Future<Result<Organization>> getOrCreateDefaultOrganization() =>
      _ds.getOrCreateDefaultOrganization();
}
