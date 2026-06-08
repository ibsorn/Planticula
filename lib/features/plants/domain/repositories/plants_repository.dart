import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/plants/domain/entities/plant.dart';

/// Contrato para el repositorio de plantas
/// Define las operaciones de negocio disponibles
abstract class PlantsRepository {
  /// Obtiene todas las plantas del usuario
  Future<Result<List<Plant>>> getPlants();

  /// Obtiene una planta por su ID
  Future<Result<Plant>> getPlantById(String id);

  /// Crea una nueva planta
  Future<Result<Plant>> createPlant({
    required String name,
    String? scientificName,
    String? speciesId,
    String? imageUrl,
    String? location,
    String? notes,
    int? wateringFrequency,
    DateTime? acquiredDate,
  });

  /// Actualiza una planta existente
  Future<Result<Plant>> updatePlant(Plant plant);

  /// Elimina una planta
  Future<Result<void>> deletePlant(String id);

  /// Busca plantas por nombre
  Future<Result<List<Plant>>> searchPlants(String query);

  /// Marca una planta como regada y actualiza fechas
  Future<Result<Plant>> waterPlant(String id);

  /// Obtiene plantas que necesitan riego
  Future<Result<List<Plant>>> getPlantsNeedingWater();
}
