import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';
import 'package:planticula/features/plants/domain/repositories/plants_repository.dart';

class CreatePlantUseCase {
  final PlantsRepository _repository;
  CreatePlantUseCase(this._repository);

  Future<Result<Plant>> call({
    required String name,
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
  }) => _repository.createPlant(
    name: name,
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
  );
}
