import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/gardens/domain/entities/garden.dart';
import 'package:planticula/features/gardens/domain/entities/garden_group.dart';

/// Contrato del repositorio de jardines y grupos.
///
/// Cubre las operaciones CRUD de [Garden] y [GardenGroup], además de
/// la RPC de Supabase para garantizar la existencia del jardín por defecto.
abstract class GardenRepository {
  // ── Jardines ─────────────────────────────────────────────────────────────

  /// Devuelve todos los jardines del usuario, ordenados por [sortOrder].
  Future<Result<List<Garden>>> getGardens();

  /// Devuelve un jardín por su ID.
  Future<Result<Garden>> getGardenById(String id);

  /// Crea un nuevo jardín.
  Future<Result<Garden>> createGarden({
    required String name,
    String? description,
    String icon,
    String color,
    GardenType type,
  });

  /// Actualiza un jardín existente.
  Future<Result<Garden>> updateGarden(Garden garden);

  /// Elimina un jardín (las plantas quedan con garden_id = NULL).
  /// No se puede eliminar el jardín por defecto.
  Future<Result<void>> deleteGarden(String id);

  /// Llama a la RPC `get_or_create_default_garden`.
  /// Garantiza que el usuario siempre tiene al menos un jardín.
  Future<Result<Garden>> getOrCreateDefaultGarden();

  // ── Grupos ───────────────────────────────────────────────────────────────

  /// Devuelve todos los grupos de un jardín, ordenados por [sortOrder].
  Future<Result<List<GardenGroup>>> getGroupsByGarden(String gardenId);

  /// Crea un grupo dentro de un jardín.
  Future<Result<GardenGroup>> createGroup({
    required String gardenId,
    required String name,
    String? description,
    String? icon,
    String? color,
  });

  /// Actualiza un grupo existente.
  Future<Result<GardenGroup>> updateGroup(GardenGroup group);

  /// Elimina un grupo (las plantas quedan con group_id = NULL).
  Future<Result<void>> deleteGroup(String id);
}
