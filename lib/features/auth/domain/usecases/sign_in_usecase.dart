import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/auth/domain/entities/user.dart';
import 'package:planticula/features/auth/domain/repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository _repository;

  SignInUseCase(this._repository);

  Future<Result<User>> call({
    required String email,
    required String password,
  }) async {
    return _repository.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }
}
