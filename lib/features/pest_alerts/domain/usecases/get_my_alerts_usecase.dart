import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/pest_alerts/domain/entities/pest_alert.dart';
import 'package:planticula/features/pest_alerts/domain/repositories/pest_alert_repository.dart';

class GetMyAlertsUseCase {
  final PestAlertRepository _repository;
  GetMyAlertsUseCase(this._repository);

  Future<Result<List<PestAlert>>> call({
    int limit = 50,
    int offset = 0,
  }) => _repository.getMyAlerts(
    limit: limit,
    offset: offset,
  );
}
