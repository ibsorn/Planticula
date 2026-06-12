part of 'auth_bloc.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthState extends Equatable {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;
  final String? successMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.successMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
  bool get hasError => status == AuthStatus.error;

  /// [FIX-1] copyWith usa sentinel object para distinguir entre
  /// "no pasé el campo" (mantener actual) y "quiero borrarlo" (null explícito).
  /// Sin esto, errorMessage/successMessage nunca se podían limpiar a null.
  static const _keep = Object();

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    Object? errorMessage = _keep,
    Object? successMessage = _keep,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage == _keep
          ? this.errorMessage
          : errorMessage as String?,
      successMessage: successMessage == _keep
          ? this.successMessage
          : successMessage as String?,
    );
  }

  /// Limpia mensajes de error y éxito (útil al retipear en el formulario).
  AuthState clearMessages() => copyWith(
        errorMessage: null,
        successMessage: null,
      );

  @override
  List<Object?> get props => [status, user, errorMessage, successMessage];
}
