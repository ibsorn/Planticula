import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
import 'package:planticula/features/plants/domain/repositories/plants_repository.dart';

class GetPlantsUseCase {
  final PlantsRepository _repository;
  GetPlantsUseCase(this._repository);
  Future<Result<List<Plant>>> call() => _repository.getPlants();
}
