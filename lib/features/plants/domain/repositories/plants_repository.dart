import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/plants/domain/entities/care_log.dart';
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
    String? customName,
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
    String? organizationId,
    String? locationId,
  });

  /// Actualiza una planta existente
  Future<Result<Plant>> updatePlant(Plant plant);

  /// Elimina una planta
  Future<Result<void>> deletePlant(String id);

  /// Busca plantas por nombre
  Future<Result<List<Plant>>> searchPlants(String query);

  /// Marca una planta como regada y actualiza fechas
  Future<Result<Plant>> waterPlant(String id);

  /// Marca una planta como regada en una fecha específica (para riegos pasados)
  /// [daysAgo]: días atrás desde hoy (0 = hoy, 1 = ayer, etc.)
  Future<Result<Plant>> waterPlantWithDate(String id, int daysAgo);

  /// Registra un trasplante y actualiza el tamaño de maceta
  Future<Result<Plant>> transplantPlant(String id, String newPotSize);

  /// Obtiene plantas que necesitan riego
  Future<Result<List<Plant>>> getPlantsNeedingWater();

  /// Obtiene las plantas cuyo location_id está dentro de [locationIds]
  /// (un nodo y sus descendientes).
  Future<Result<List<Plant>>> getPlantsByLocationIds(List<String> locationIds);

  /// Asigna una planta a una localización (null = sin clasificar).
  Future<Result<Plant>> assignPlantToLocation(
    String plantId, {
    String? locationId,
  });

  /// Historial de cuidados de una planta (más reciente primero).
  Future<Result<List<CareLog>>> getCareLogs(String plantId);

  /// Añade una entrada manual al historial.
  Future<Result<CareLog>> addCareLog({
    required String plantId,
    required CareLogType type,
    DateTime? eventDate,
    String? note,
    Map<String, dynamic>? metadata,
  });

  /// Elimina una entrada del historial.
  Future<Result<void>> deleteCareLog(String id);
}
