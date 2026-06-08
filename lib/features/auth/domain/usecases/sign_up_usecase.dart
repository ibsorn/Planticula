import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/auth/domain/entities/user.dart';
import 'package:planticula/features/auth/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository _repository;

  SignUpUseCase(this._repository);

  Future<Result<User>> call({
    required String email,
    required String password,
    required String displayName,
  }) async {
    return _repository.signUpWithEmailAndPassword(
      email: email,
      password: password,
      displayName: displayName,
    );
  }
}
