import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/pest_alerts/domain/repositories/pest_alert_repository.dart';

class DeleteAlertUseCase {
  final PestAlertRepository _repository;
  DeleteAlertUseCase(this._repository);

  Future<Result<void>> call(String id) => _repository.deleteAlert(id);
}
