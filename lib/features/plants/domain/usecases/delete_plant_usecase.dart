import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/plants/domain/repositories/plants_repository.dart';

class DeletePlantUseCase {
  final PlantsRepository _repository;
  DeletePlantUseCase(this._repository);
  Future<Result<void>> call(String id) => _repository.deletePlant(id);
}
