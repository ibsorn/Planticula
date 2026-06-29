import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/locations/data/models/organization_model.dart';

abstract class OrganizationRemoteDataSource {
  Future<Result<List<OrganizationModel>>> getMyOrganizations();
  Future<Result<OrganizationModel>>       getOrCreateDefaultOrganization();
}
