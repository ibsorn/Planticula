import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/plants/data/models/care_log_model.dart';
import 'package:planticula/features/plants/data/models/plant_model.dart';
import 'package:planticula/features/plants/domain/entities/care_log.dart';

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

  /// Marca una planta como regada en una fecha específica (para riegos pasados)
  /// [daysAgo]: días atrás desde hoy (0 = hoy, 1 = ayer, etc.)
  Future<Result<PlantModel>> waterPlantWithDate(String id, int daysAgo);

  /// Registra un trasplante (actualiza pot_size y last_transplanted)
  Future<Result<PlantModel>> transplantPlant(String id, String newPotSize);

  /// Obtiene plantas cuyo location_id está dentro de [locationIds]
  /// (un nodo y sus descendientes).
  Future<Result<List<PlantModel>>> getPlantsByLocationIds(
    List<String> locationIds,
  );

  /// Asigna una planta a una localización (null = sin clasificar).
  Future<Result<PlantModel>> assignPlantToLocation(
    String plantId, {
    String? locationId,
  });

  /// Devuelve el historial de cuidados de una planta (más reciente primero).
  Future<Result<List<CareLogModel>>> getCareLogs(String plantId);

  /// Añade una entrada manual al historial (nota, abonado, poda…).
  Future<Result<CareLogModel>> addCareLog({
    required String plantId,
    required CareLogType type,
    DateTime? eventDate,
    String? note,
    Map<String, dynamic>? metadata,
  });

  /// Elimina una entrada del historial.
  Future<Result<void>> deleteCareLog(String id);
}
