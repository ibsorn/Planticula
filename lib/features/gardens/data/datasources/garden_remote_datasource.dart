import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/gardens/data/models/garden_model.dart';
import 'package:planticula/features/gardens/data/models/garden_group_model.dart';

abstract class GardenRemoteDataSource {
  Future<Result<List<GardenModel>>>      getGardens();
  Future<Result<GardenModel>>            getGardenById(String id);
  Future<Result<GardenModel>>            createGarden(Map<String, dynamic> data);
  Future<Result<GardenModel>>            updateGarden(GardenModel garden);
  Future<Result<void>>                   deleteGarden(String id);
  Future<Result<GardenModel>>            getOrCreateDefaultGarden();

  Future<Result<List<GardenGroupModel>>> getGroupsByGarden(String gardenId);
  Future<Result<GardenGroupModel>>       createGroup(Map<String, dynamic> data);
  Future<Result<GardenGroupModel>>       updateGroup(GardenGroupModel group);
  Future<Result<void>>                   deleteGroup(String id);
}
