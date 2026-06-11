import 'dart:async';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/features/auth/data/models/user_model.dart';
import 'package:planticula/features/auth/domain/entities/user.dart';
import 'package:planticula/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase show AuthException, AuthState;

class AuthRepositoryImpl implements AuthRepository {
  final AppSupabaseClient _supabaseClient;

  AuthRepositoryImpl(this._supabaseClient);

  @override
  bool get isAuthenticated => _supabaseClient.isAuthenticated;

  @override
  User? get currentUser {
    final supabaseUser = _supabaseClient.currentUser;
    return supabaseUser != null ? UserModel.fromSupabase(supabaseUser) : null;
  }

  @override
  Future<Result<User>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return const Failure('Authentication failed');
      }

      final user = UserModel.fromSupabase(response.user!);
      return Success(user);
    } on supabase.AuthException catch (e) {
      return Failure(e.message, code: e.statusCode?.toString());
    } catch (e) {
      return Failure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<Result<User>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: {'display_name': displayName},
      );

      if (response.user == null) {
        return const Failure('Registration failed');
      }

      final user = UserModel.fromSupabase(response.user!);
      return Success(user);
    } on supabase.AuthException catch (e) {
      return Failure(e.message, code: e.statusCode?.toString());
    } catch (e) {
      return Failure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _supabaseClient.signOut();
      return const Success(null);
    } on supabase.AuthException catch (e) {
      return Failure(e.message, code: e.statusCode?.toString());
    } catch (e) {
      return Failure('Unexpected error: ${e.toString()}');
    }
  }

  @override
  Stream<User?> get onAuthStateChanged {
    return _supabaseClient.onAuthStateChange.map((supabase.AuthState event) {
      final supabaseUser = event.session?.user;
      return supabaseUser != null
          ? UserModel.fromSupabase(supabaseUser)
          : null;
    });
  }

  @override
  Future<Result<void>> resetPassword(String email) async {
    try {
      await _supabaseClient.auth.resetPasswordForEmail(email);
      return const Success(null);
    } on supabase.AuthException catch (e) {
      return Failure(e.message, code: e.statusCode?.toString());
    } catch (e) {
      return Failure('Unexpected error: ${e.toString()}');
    }
  }
}
