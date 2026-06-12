import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
import 'package:planticula/features/plants/domain/repositories/plants_repository.dart';

class TransplantPlantUseCase {
  final PlantsRepository _repository;
  TransplantPlantUseCase(this._repository);
  Future<Result<Plant>> call(String id, String newPotSize) =>
      _repository.transplantPlant(id, newPotSize);
}
