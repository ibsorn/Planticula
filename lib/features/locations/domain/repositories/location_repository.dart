import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/locations/domain/entities/location.dart';

/// Contrato del repositorio del árbol de localización.
abstract class LocationRepository {
  /// Devuelve todos los nodos de localización de una organización
  /// (lista plana; el árbol se construye en cliente vía [parentId]).
  Future<Result<List<Location>>> getLocations(String organizationId);

  /// Crea un nuevo nodo de localización.
  Future<Result<Location>> createLocation({
    required String organizationId,
    String? parentId,
    required LocationKind kind,
    required String name,
    String? description,
    String icon,
    String color,
    Map<String, dynamic>? metadata,
  });

  /// Actualiza un nodo existente.
  Future<Result<Location>> updateLocation(Location location);

  /// Elimina un nodo (sus hijos se eliminan en cascada; las plantas quedan
  /// con location_id = NULL).
  Future<Result<void>> deleteLocation(String id);
}
