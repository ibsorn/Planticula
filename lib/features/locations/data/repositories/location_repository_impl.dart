import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/locations/data/datasources/location_remote_datasource.dart';
import 'package:planticula/features/locations/data/models/location_model.dart';
import 'package:planticula/features/locations/domain/entities/location.dart';
import 'package:planticula/features/locations/domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationRemoteDataSource _ds;

  LocationRepositoryImpl(this._ds);

  @override
  Future<Result<List<Location>>> getLocations(String organizationId) =>
      _ds.getLocations(organizationId);

  @override
  Future<Result<Location>> createLocation({
    required String organizationId,
    String? parentId,
    required LocationKind kind,
    required String name,
    String? description,
    String icon = 'garden',
    String color = '#4CAF50',
    Map<String, dynamic>? metadata,
  }) {
    final data = <String, dynamic>{
      'organization_id': organizationId,
      'parent_id': parentId,
      'kind': kind.name,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'metadata': metadata ?? const {},
      'sort_order': 0,
    };
    return _ds.createLocation(data);
  }

  @override
  Future<Result<Location>> updateLocation(Location location) =>
      _ds.updateLocation(LocationModel.fromDomain(location));

  @override
  Future<Result<void>> deleteLocation(String id) => _ds.deleteLocation(id);
}
