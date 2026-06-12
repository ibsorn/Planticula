import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/pest_alerts/domain/entities/pest_alert.dart';
import 'package:planticula/features/pest_alerts/domain/repositories/pest_alert_repository.dart';

class GetNearbyAlertsUseCase {
  final PestAlertRepository _repository;
  GetNearbyAlertsUseCase(this._repository);

  Future<Result<List<PestAlert>>> call({
    required double latitude,
    required double longitude,
    double radiusKm = 10,
    int? daysLimit,
    List<PestType>? pestTypes,
    List<Severity>? severities,
    bool includeResolved = false,
    int limit = 50,
    int offset = 0,
  }) => _repository.getNearbyAlerts(
    latitude: latitude,
    longitude: longitude,
    radiusKm: radiusKm,
    daysLimit: daysLimit,
    pestTypes: pestTypes,
    severities: severities,
    includeResolved: includeResolved,
    limit: limit,
    offset: offset,
  );
}
