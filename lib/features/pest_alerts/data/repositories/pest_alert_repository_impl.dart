import 'dart:typed_data';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/pest_alerts/data/datasources/pest_alert_remote_datasource.dart';
import 'package:planticula/features/pest_alerts/data/models/pest_alert_model.dart';
import 'package:planticula/features/pest_alerts/domain/entities/pest_alert.dart';
import 'package:planticula/features/pest_alerts/domain/repositories/pest_alert_repository.dart';

/// Implementación del repositorio de alertas de plagas
class PestAlertRepositoryImpl implements PestAlertRepository {
  final PestAlertRemoteDataSource _dataSource;

  PestAlertRepositoryImpl(this._dataSource);

  @override
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
  }) async {
    String? photoUrl;

    // 1. Subir foto si existe
    if (photoBytes != null && fileName != null) {
      final uploadResult = await _dataSource.uploadPhoto(photoBytes, fileName);
      if (uploadResult is Failure<String>) {
        return Failure(uploadResult.message,
            code: uploadResult.code, error: uploadResult.error);
      }
      photoUrl = (uploadResult as Success<String>).data;
    }

    // 2. Crear request
    final request = CreatePestAlertRequest(
      photoUrl: photoUrl,
      pestType: pestType,
      customPestName: customPestName,
      severity: severity,
      latitude: latitude,
      longitude: longitude,
      locationName: locationName,
      notes: notes,
    );

    // 3. Crear alerta
    return await _dataSource.createAlert(request);
  }

  @override
  Future<Result<List<PestAlert>>> getNearbyAlerts({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int? daysLimit,
    List<PestType>? pestTypes,
    List<Severity>? severities,
    bool includeResolved = false,
    int limit = 50,
    int offset = 0,
  }) async {
    return await _dataSource.getNearbyAlerts(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      daysLimit: daysLimit,
      pestTypes: pestTypes?.map((e) => e.name).toList(),
      severities: severities?.map((e) => e.name).toList(),
      includeResolved: includeResolved,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<Result<List<PestAlert>>> getMyAlerts({
    int limit = 50,
    int offset = 0,
  }) async {
    return await _dataSource.getMyAlerts(limit: limit, offset: offset);
  }

  @override
  Future<Result<PestAlert>> getAlertById(String id) async {
    return await _dataSource.getAlertById(id);
  }

  @override
  Future<Result<PestAlert>> updateAlert(PestAlert alert) async {
    final model = PestAlertModel.fromDomain(alert);
    return await _dataSource.updateAlert(model);
  }

  @override
  Future<Result<PestAlert>> markAsResolved(String id) async {
    return await _dataSource.markAsResolved(id);
  }

  @override
  Future<Result<void>> deleteAlert(String id) async {
    return await _dataSource.deleteAlert(id);
  }

  @override
  Future<Result<void>> confirmAlert(String alertId) async {
    return await _dataSource.confirmAlert(alertId);
  }

  @override
  Future<Result<Map<String, dynamic>>> getAreaStatistics({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int? daysLimit,
  }) async {
    return await _dataSource.getAreaStatistics(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      daysLimit: daysLimit,
    );
  }
}
