import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/plants/data/models/plant_model.dart';

/// Contrato para la fuente de datos de plantas
/// Define las operaciones disponibles sin importar la implementación
abstract class PlantRemoteDataSource {
  /// Obtiene todas las plantas del usuario actual
  Future<Result<List<PlantModel>>> getPlants();

  /// Obtiene una planta por su ID
  Future<Result<PlantModel>> getPlantById(String id);

  /// Crea una nueva planta
  Future<Result<PlantModel>> createPlant(PlantModel plant);

  /// Actualiza una planta existente
  Future<Result<PlantModel>> updatePlant(PlantModel plant);

  /// Elimina una planta
  Future<Result<void>> deletePlant(String id);

  /// Busca plantas por nombre
  Future<Result<List<PlantModel>>> searchPlants(String query);

  /// Marca una planta como regada (actualiza last_watered y next_watering)
  Future<Result<PlantModel>> waterPlant(String id);
}
