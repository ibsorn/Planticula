import 'dart:typed_data';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/pest_alerts/domain/entities/pest_alert.dart';

/// Contrato para el repositorio de alertas de plagas
abstract class PestAlertRepository {
  /// Reporta una nueva plaga (sube foto si existe y crea alerta)
  Future<Result<PestAlert>> reportPest({
    Uint8List? photoBytes,
    String? fileName,
    required PestType pestType,
    String? customPestName,
    required Severity severity,
    required double latitude,
    required double longitude,
    String? locationName,
    String? notes,
  });

  /// Obtiene alertas cercanas a una ubicación
  /// Ordenadas por distancia (más cercanas primero)
  Future<Result<List<PestAlert>>> getNearbyAlerts({
    required double latitude,
    required double longitude,
    double radiusKm,
    int? daysLimit,
    List<PestType>? pestTypes,
    List<Severity>? severities,
    bool includeResolved,
    int limit,
    int offset,
  });

  /// Obtiene las alertas reportadas por el usuario actual
  Future<Result<List<PestAlert>>> getMyAlerts({
    int limit,
    int offset,
  });

  /// Obtiene una alerta específica por ID
  Future<Result<PestAlert>> getAlertById(String id);

  /// Actualiza una alerta existente
  Future<Result<PestAlert>> updateAlert(PestAlert alert);

  /// Marca una alerta como resuelta (plaga tratada)
  Future<Result<PestAlert>> markAsResolved(String id);

  /// Elimina una alerta y su foto asociada
  Future<Result<void>> deleteAlert(String id);

  /// Confirma una alerta (otro usuario vio la misma plaga)
  Future<Result<void>> confirmAlert(String alertId);

  /// Obtiene estadísticas de plagas en un área
  Future<Result<Map<String, dynamic>>> getAreaStatistics({
    required double latitude,
    required double longitude,
    double radiusKm,
    int? daysLimit,
  });
}
