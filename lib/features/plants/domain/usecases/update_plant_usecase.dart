import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
import 'package:planticula/features/plants/domain/repositories/plants_repository.dart';

class UpdatePlantUseCase {
  final PlantsRepository _repository;
  UpdatePlantUseCase(this._repository);
  Future<Result<Plant>> call(Plant plant) => _repository.updatePlant(plant);
}
