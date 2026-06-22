import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/gardens/data/datasources/garden_remote_datasource.dart';
import 'package:planticula/features/gardens/data/models/garden_group_model.dart';
import 'package:planticula/features/gardens/data/models/garden_model.dart';
import 'package:planticula/features/gardens/domain/entities/garden.dart';
import 'package:planticula/features/gardens/domain/entities/garden_group.dart';
import 'package:planticula/features/gardens/domain/repositories/garden_repository.dart';

class GardenRepositoryImpl implements GardenRepository {
  final GardenRemoteDataSource _ds;

  GardenRepositoryImpl(this._ds);

  // ── Jardines ─────────────────────────────────────────────────────────────

  @override
  Future<Result<List<Garden>>> getGardens() => _ds.getGardens();

  @override
  Future<Result<Garden>> getGardenById(String id) => _ds.getGardenById(id);

  @override
  Future<Result<Garden>> createGarden({
    required String name,
    String? description,
    String icon = 'garden',
    String color = '#4CAF50',
    GardenType type = GardenType.personal,
  }) {
    // user_id es inyectado por el datasource usando la sesión activa
    final data = {
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'type': type.name,
      'is_default': false,
      'sort_order': 0,
    };
    return _ds.createGarden(data);
  }

  @override
  Future<Result<Garden>> updateGarden(Garden garden) {
    return _ds.updateGarden(GardenModel.fromDomain(garden));
  }

  @override
  Future<Result<void>> deleteGarden(String id) => _ds.deleteGarden(id);

  @override
  Future<Result<Garden>> getOrCreateDefaultGarden() =>
      _ds.getOrCreateDefaultGarden();

  // ── Grupos ───────────────────────────────────────────────────────────────

  @override
  Future<Result<List<GardenGroup>>> getGroupsByGarden(String gardenId) =>
      _ds.getGroupsByGarden(gardenId);

  @override
  Future<Result<GardenGroup>> createGroup({
    required String gardenId,
    required String name,
    String? description,
    String? icon,
    String? color,
  }) {
    // user_id es inyectado por el datasource
    final data = {
      'garden_id': gardenId,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'sort_order': 0,
    };
    return _ds.createGroup(data);
  }

  @override
  Future<Result<GardenGroup>> updateGroup(GardenGroup group) {
    return _ds.updateGroup(GardenGroupModel.fromDomain(group));
  }

  @override
  Future<Result<void>> deleteGroup(String id) => _ds.deleteGroup(id);

}
