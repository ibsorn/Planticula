import 'dart:typed_data';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/pest_alerts/data/models/pest_alert_model.dart';

/// Contrato para la fuente de datos de alertas de plagas
abstract class PestAlertRemoteDataSource {
  /// Crea una nueva alerta de plaga
  Future<Result<PestAlertModel>> createAlert(CreatePestAlertRequest request);

  /// Obtiene una alerta por su ID
  Future<Result<PestAlertModel>> getAlertById(String id);

  /// Obtiene alertas cercanas a una ubicación ordenadas por distancia
  /// Usa consulta SQL con cálculo Haversine
  Future<Result<List<PestAlertModel>>> getNearbyAlerts({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int? daysLimit,
    List<String>? pestTypes,
    List<String>? severities,
    bool includeResolved = false,
    int limit = 50,
    int offset = 0,
  });

  /// Obtiene alertas reportadas por el usuario
  Future<Result<List<PestAlertModel>>> getMyAlerts({
    int limit = 50,
    int offset = 0,
  });

  /// Actualiza una alerta existente
  Future<Result<PestAlertModel>> updateAlert(PestAlertModel alert);

  /// Marca una alerta como resuelta
  Future<Result<PestAlertModel>> markAsResolved(String id);

  /// Elimina una alerta
  Future<Result<void>> deleteAlert(String id);

  /// Sube foto de la plaga a Storage
  Future<Result<String>> uploadPhoto(Uint8List imageBytes, String fileName);

  /// Elimina foto de Storage
  Future<Result<void>> deletePhoto(String filePath);

  /// Confirma una alerta (otro usuario vio la misma plaga)
  Future<Result<void>> confirmAlert(String alertId);

  /// Obtiene estadísticas de alertas en un área
  Future<Result<Map<String, dynamic>>> getAreaStatistics({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int? daysLimit,
  });
}
