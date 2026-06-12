import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
import 'package:planticula/features/plants/domain/repositories/plants_repository.dart';

class GetPlantsNeedingWaterUseCase {
  final PlantsRepository _repository;
  GetPlantsNeedingWaterUseCase(this._repository);
  Future<Result<List<Plant>>> call() => _repository.getPlantsNeedingWater();
}
