import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:planticula/core/constants/app_strings.dart';
import 'package:planticula/features/auth/domain/entities/user.dart';
import 'package:planticula/features/auth/domain/repositories/auth_repository.dart';
import 'package:planticula/features/auth/domain/usecases/sign_in_usecase.dart';
import 'package:planticula/features/auth/domain/usecases/sign_up_usecase.dart';
import 'package:planticula/features/auth/domain/usecases/sign_out_usecase.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  late final SignInUseCase _signInUseCase;
  late final SignUpUseCase _signUpUseCase;
  late final SignOutUseCase _signOutUseCase;
  late final StreamSubscription<dynamic> _authSubscription;

  AuthBloc(this._authRepository) : super(const AuthState()) {
    _signInUseCase = SignInUseCase(_authRepository);
    _signUpUseCase = SignUpUseCase(_authRepository);
    _signOutUseCase = SignOutUseCase(_authRepository);

    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignUpRequested>(_onSignUpRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthResetPasswordRequested>(_onResetPasswordRequested);
    on<AuthUserChanged>(_onUserChanged);
    on<AuthErrorCleared>(_onErrorCleared);

    _init();
  }

  void _init() {
    _authSubscription = _authRepository.onAuthStateChanged.listen((user) {
      add(AuthUserChanged(user));
    });
    add(AuthCheckRequested());
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));
    final user = _authRepository.currentUser;
    if (user != null) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        errorMessage: null,
        successMessage: null,
      ));
    } else {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: null,
        successMessage: null,
      ));
    }
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Limpiar mensajes previos al intentar login
    emit(state.copyWith(
      status: AuthStatus.loading,
      errorMessage: null,
      successMessage: null,
    ));

    final result = await _signInUseCase(
      email: event.email,
      password: event.password,
    );

    result.when(
      success: (user) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          errorMessage: null,
          successMessage: null,
        ));
      },
      failure: (message, code, error) {
        // [FIX-3] Traducir errores de Supabase al español
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: _translateAuthError(message, code),
          successMessage: null,
        ));
      },
    );
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      errorMessage: null,
      successMessage: null,
    ));

    final result = await _signUpUseCase(
      email: event.email,
      password: event.password,
      displayName: event.displayName,
    );

    result.when(
      success: (user) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          errorMessage: null,
          successMessage: null,
        ));
      },
      failure: (message, code, error) {
        // [FIX-3] Traducir errores de Supabase al español
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: _translateAuthError(message, code),
          successMessage: null,
        ));
      },
    );
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _signOutUseCase();

    result.when(
      success: (_) {
        emit(const AuthState(status: AuthStatus.unauthenticated));
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: _translateAuthError(message, code),
          successMessage: null,
        ));
      },
    );
  }

  Future<void> _onResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(
      status: AuthStatus.loading,
      errorMessage: null,
      successMessage: null,
    ));

    final result = await _authRepository.resetPassword(event.email);

    result.when(
      success: (_) {
        // [FIX-5] Usar AppStrings en lugar de string hardcodeada
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          successMessage: AppStrings.resetPasswordEmailSent,
          errorMessage: null,
        ));
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: _translateAuthError(message, code),
          successMessage: null,
        ));
      },
    );
  }

  /// [FIX-6] _onUserChanged solo actúa si no hay una operación en curso
  /// ni un error activo, para no sobreescribir estados intermedios.
  void _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) {
    // No interrumpir estados de loading o error activos
    if (state.isLoading) return;

    if (event.user != null) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: event.user,
        errorMessage: null,
        successMessage: null,
      ));
    } else {
      // Solo emitir unauthenticated si estábamos autenticados antes
      // (evita limpiar un estado de error al arrancar la app)
      if (state.isAuthenticated) {
        emit(const AuthState(status: AuthStatus.unauthenticated));
      }
    }
  }

  void _onErrorCleared(
    AuthErrorCleared event,
    Emitter<AuthState> emit,
  ) {
    if (state.hasError) {
      emit(state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: null,
      ));
    }
  }

  /// [FIX-3] Traduce los mensajes de error de Supabase Auth al español.
  /// Supabase devuelve mensajes en inglés; los traducimos aquí en la capa
  /// de presentación para no contaminar la capa de datos.
  static String _translateAuthError(String message, String? code) {
    final msg = message.toLowerCase();
    final c = code ?? '';

    // Credenciales incorrectas
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid email or password') ||
        c == '400') {
      return AppStrings.authErrorInvalidCredentials;
    }
    // Email ya en uso
    if (msg.contains('user already registered') ||
        msg.contains('email already in use') ||
        msg.contains('already been registered')) {
      return AppStrings.authErrorEmailAlreadyInUse;
    }
    // Email no confirmado
    if (msg.contains('email not confirmed')) {
      return AppStrings.authErrorEmailNotConfirmed;
    }
    // Too many requests / rate limit
    if (msg.contains('too many requests') ||
        msg.contains('rate limit') ||
        c == '429') {
      return AppStrings.authErrorTooManyRequests;
    }
    // Sin conexión / network
    if (msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('connection')) {
      return AppStrings.authErrorNetwork;
    }
    // Contraseña muy débil
    if (msg.contains('password should be at least') ||
        msg.contains('weak password')) {
      return AppStrings.authErrorWeakPassword;
    }
    // Email inválido
    if (msg.contains('unable to validate email') ||
        msg.contains('invalid email')) {
      return AppStrings.fieldEmailInvalid;
    }
    // Usuario no encontrado (reset password)
    if (msg.contains('user not found') || c == '404') {
      return AppStrings.authErrorUserNotFound;
    }
    // Sesión expirada
    if (msg.contains('token expired') ||
        msg.contains('session expired') ||
        c == '401') {
      return AppStrings.authErrorSessionExpired;
    }
    // Fallback: devolver el mensaje original si no hay traducción
    return message;
  }
}
