import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  /// Check if user is authenticated
  bool get isAuthenticated;

  /// Get current user
  User? get currentUser;

  /// Sign in with email and password
  Future<Result<User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<Result<User>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  });

  /// Sign out
  Future<Result<void>> signOut();

  /// Listen to auth state changes
  Stream<User?> get onAuthStateChanged;

  /// Reset password
  Future<Result<void>> resetPassword(String email);
}
