import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/plants/data/datasources/plant_remote_datasource.dart';
import 'package:planticula/features/plants/data/models/plant_model.dart';
import 'package:planticula/features/plants/domain/entities/care_log.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
import 'package:planticula/features/plants/domain/repositories/plants_repository.dart';

/// Implementación del repositorio de plantas
/// Delega operaciones de datos al datasource
class PlantsRepositoryImpl implements PlantsRepository {
  final PlantRemoteDataSource _dataSource;

  PlantsRepositoryImpl(this._dataSource);

  @override
  Future<Result<List<Plant>>> getPlants() async {
    final result = await _dataSource.getPlants();
    return result; // Result<PlantModel> es compatible con Result<Plant> por herencia
  }

  @override
  Future<Result<Plant>> getPlantById(String id) async {
    return await _dataSource.getPlantById(id);
  }

  @override
  Future<Result<Plant>> createPlant({
    required String name,
    String? customName,
    String? scientificName,
    String? speciesId,
    String? speciesCategory,
    String? imageUrl,
    String? location,
    String? notes,
    int? wateringFrequency,
    DateTime? acquiredDate,
    String? environment,
    String? growthStage,
    String? potSize,
    double? latitude,
    double? longitude,
    String? organizationId,
    String? locationId,
  }) async {
    final plantModel = PlantModel.create(
      name: name,
      customName: customName,
      scientificName: scientificName,
      speciesId: speciesId,
      speciesCategory: speciesCategory,
      imageUrl: imageUrl,
      location: location,
      notes: notes,
      wateringFrequency: wateringFrequency,
      acquiredDate: acquiredDate,
      environment: environment,
      growthStage: growthStage,
      potSize: potSize,
      latitude: latitude,
      longitude: longitude,
      organizationId: organizationId,
      locationId: locationId,
    );

    return await _dataSource.createPlant(plantModel);
  }

  @override
  Future<Result<Plant>> updatePlant(Plant plant) async {
    final plantModel = PlantModel.fromDomain(plant);
    return await _dataSource.updatePlant(plantModel);
  }

  @override
  Future<Result<void>> deletePlant(String id) async {
    return await _dataSource.deletePlant(id);
  }

  @override
  Future<Result<List<Plant>>> searchPlants(String query) async {
    return await _dataSource.searchPlants(query);
  }

  @override
  Future<Result<Plant>> waterPlant(String id) async {
    return await _dataSource.waterPlant(id);
  }

  @override
  Future<Result<Plant>> waterPlantWithDate(String id, int daysAgo) async {
    return await _dataSource.waterPlantWithDate(id, daysAgo);
  }

  @override
  Future<Result<Plant>> transplantPlant(String id, String newPotSize) async {
    return await _dataSource.transplantPlant(id, newPotSize);
  }

  @override
  Future<Result<List<Plant>>> getPlantsByLocationIds(List<String> locationIds) =>
      _dataSource.getPlantsByLocationIds(locationIds);

  @override
  Future<Result<Plant>> assignPlantToLocation(
    String plantId, {
    String? locationId,
  }) =>
      _dataSource.assignPlantToLocation(plantId, locationId: locationId);

  @override
  Future<Result<List<CareLog>>> getCareLogs(String plantId) =>
      _dataSource.getCareLogs(plantId);

  @override
  Future<Result<CareLog>> addCareLog({
    required String plantId,
    required CareLogType type,
    DateTime? eventDate,
    String? note,
    Map<String, dynamic>? metadata,
  }) =>
      _dataSource.addCareLog(
        plantId: plantId,
        type: type,
        eventDate: eventDate,
        note: note,
        metadata: metadata,
      );

  @override
  Future<Result<void>> deleteCareLog(String id) =>
      _dataSource.deleteCareLog(id);

  @override
  Future<Result<List<Plant>>> getPlantsNeedingWater() async {
    final result = await _dataSource.getPlants();

    return result.when(
      success: (plants) {
        final needingWater = plants.where((plant) {
          if (plant.nextWatering == null) return false;
          return DateTime.now().isAfter(plant.nextWatering!) ||
              DateTime.now().isAtSameMomentAs(plant.nextWatering!);
        }).toList();
        return Success(needingWater);
      },
      failure: (message, code, error) => Failure(message, code: code, error: error),
    );
  }
}
