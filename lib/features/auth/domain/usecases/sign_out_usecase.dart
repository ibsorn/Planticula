import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/auth/domain/repositories/auth_repository.dart';

class SignOutUseCase {
  final AuthRepository _repository;

  SignOutUseCase(this._repository);

  Future<Result<void>> call() async {
    return _repository.signOut();
  }
}
