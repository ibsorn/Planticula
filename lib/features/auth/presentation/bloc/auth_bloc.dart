import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
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

    _init();
  }

  void _init() {
    _authRepository.onAuthStateChanged.listen((user) {
      add(AuthUserChanged(user));
    });
    add(AuthCheckRequested());
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
      ));
    } else {
      emit(state.copyWith(status: AuthStatus.unauthenticated));
    }
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _signInUseCase(
      email: event.email,
      password: event.password,
    );

    result.when(
      success: (user) {
        emit(state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
        ));
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onSignUpRequested(
    AuthSignUpRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

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
        ));
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: message,
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
          errorMessage: message,
        ));
      },
    );
  }

  Future<void> _onResetPasswordRequested(
    AuthResetPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(status: AuthStatus.loading));

    final result = await _authRepository.resetPassword(event.email);

    result.when(
      success: (_) {
        emit(state.copyWith(
          status: AuthStatus.unauthenticated,
          successMessage: 'Se ha enviado un correo para restablecer tu contrasena',
        ));
      },
      failure: (message, code, error) {
        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: message,
        ));
      },
    );
  }

  void _onUserChanged(
    AuthUserChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user != null) {
      emit(state.copyWith(
        status: AuthStatus.authenticated,
        user: event.user,
      ));
    } else {
      emit(const AuthState(status: AuthStatus.unauthenticated));
    }
  }
}
