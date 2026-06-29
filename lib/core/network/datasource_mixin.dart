import 'package:planticula/core/network/result.dart';
import 'package:planticula/core/network/supabase_client.dart';
import 'package:planticula/core/utils/logger.dart';

/// Mixin providing common datasource boilerplate: auth checks and error handling.
///
/// Classes using this mixin must provide [client].
mixin DatasourceMixin {
  AppSupabaseClient get client;

  String? get userId => client.currentUser?.id;

  /// Returns a [Failure] if the user is not authenticated, otherwise null.
  Failure<T>? requireAuth<T>() {
    if (userId == null) {
      return const Failure('Usuario no autenticado');
    }
    return null;
  }

  /// Wraps an async operation with auth-check and error handling.
  ///
  /// [operation] receives the authenticated userId.
  /// [errorPrefix] is prepended to the error message on failure.
  Future<Result<T>> guardedCall<T>({
    required Future<T> Function(String userId) operation,
    required String errorPrefix,
  }) async {
    try {
      final authFailure = requireAuth<T>();
      if (authFailure != null) return authFailure;

      final result = await operation(userId!);
      return Success(result);
    } catch (e, st) {
      Logger.e('❌ $errorPrefix', error: e, stackTrace: st);
      return Failure('$errorPrefix: $e');
    }
  }
}
