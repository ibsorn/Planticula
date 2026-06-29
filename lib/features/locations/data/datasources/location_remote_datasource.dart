import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/locations/data/models/location_model.dart';

abstract class LocationRemoteDataSource {
  Future<Result<List<LocationModel>>> getLocations(String organizationId);
  Future<Result<LocationModel>>       createLocation(Map<String, dynamic> data);
  Future<Result<LocationModel>>       updateLocation(LocationModel location);
  Future<Result<void>>                deleteLocation(String id);
}
