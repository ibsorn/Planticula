import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
import 'package:planticula/features/plants/domain/repositories/plants_repository.dart';

class SearchPlantsUseCase {
  final PlantsRepository _repository;
  SearchPlantsUseCase(this._repository);
  Future<Result<List<Plant>>> call(String query) => _repository.searchPlants(query);
}
