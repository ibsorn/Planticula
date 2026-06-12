import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
import 'package:planticula/features/plants/domain/repositories/plants_repository.dart';

class WaterPlantUseCase {
  final PlantsRepository _repository;
  WaterPlantUseCase(this._repository);
  Future<Result<Plant>> call(String id) => _repository.waterPlant(id);
}
