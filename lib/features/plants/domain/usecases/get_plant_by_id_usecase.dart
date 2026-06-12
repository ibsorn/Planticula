import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
import 'package:planticula/features/plants/domain/repositories/plants_repository.dart';

class GetPlantByIdUseCase {
  final PlantsRepository _repository;
  GetPlantByIdUseCase(this._repository);
  Future<Result<Plant>> call(String id) => _repository.getPlantById(id);
}
