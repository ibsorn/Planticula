import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/pest_alerts/domain/repositories/pest_alert_repository.dart';

class ConfirmAlertUseCase {
  final PestAlertRepository _repository;
  ConfirmAlertUseCase(this._repository);

  Future<Result<void>> call(String alertId) => _repository.confirmAlert(alertId);
}
