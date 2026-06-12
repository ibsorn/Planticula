import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/pest_alerts/domain/entities/pest_alert.dart';
import 'package:planticula/features/pest_alerts/domain/repositories/pest_alert_repository.dart';

class MarkResolvedUseCase {
  final PestAlertRepository _repository;
  MarkResolvedUseCase(this._repository);

  Future<Result<PestAlert>> call(String id) => _repository.markAsResolved(id);
}
