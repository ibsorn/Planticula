import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:planticula/core/constants/app_strings.dart';
import 'package:planticula/core/network/result.dart';
import 'package:planticula/features/auth/domain/entities/user.dart';
import 'package:planticula/features/auth/domain/repositories/auth_repository.dart';
import 'package:planticula/features/auth/presentation/bloc/auth_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  const testUser = User(
    id: 'test-user-id',
    email: 'test@example.com',
    displayName: 'Test User',
  );

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    // Return an empty stream for onAuthStateChanged to avoid issues
    when(() => mockAuthRepository.onAuthStateChanged)
        .thenAnswer((_) => const Stream<User?>.empty());
  });

  tearDown(() {
    reset(mockAuthRepository);
  });

  group('AuthBloc', () {
    test('initial state is AuthStatus.initial', () {
      when(() => mockAuthRepository.currentUser).thenReturn(null);

      final bloc = AuthBloc(mockAuthRepository);
      // The bloc starts with initial state
      expect(bloc.state.status, AuthStatus.initial);
      bloc.close();
    });

    blocTest<AuthBloc, AuthState>(
      'AuthCheckRequested with authenticated user emits [loading, authenticated]',
      setUp: () {
        when(() => mockAuthRepository.currentUser).thenReturn(testUser);
      },
      build: () => AuthBloc(mockAuthRepository),
      // Skip the initial AuthCheckRequested from _init()
      skip: 2,
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [
        // The user is already in state from initial check, so loading carries it forward
        const AuthState(status: AuthStatus.loading, user: testUser),
        const AuthState(status: AuthStatus.authenticated, user: testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthCheckRequested with no user emits [loading, unauthenticated]',
      setUp: () {
        when(() => mockAuthRepository.currentUser).thenReturn(null);
      },
      build: () => AuthBloc(mockAuthRepository),
      // Skip the initial AuthCheckRequested from _init()
      skip: 2,
      act: (bloc) => bloc.add(AuthCheckRequested()),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.unauthenticated),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthSignInRequested success emits [loading, authenticated]',
      setUp: () {
        when(() => mockAuthRepository.currentUser).thenReturn(null);
        when(() => mockAuthRepository.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => const Success(testUser));
      },
      build: () => AuthBloc(mockAuthRepository),
      // Skip the initial AuthCheckRequested from _init()
      skip: 2,
      act: (bloc) => bloc.add(const AuthSignInRequested(
        email: 'test@example.com',
        password: 'password123',
      )),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.authenticated, user: testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthSignInRequested failure emits [loading, error] with errorMessage',
      setUp: () {
        when(() => mockAuthRepository.currentUser).thenReturn(null);
        when(() => mockAuthRepository.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => const Failure('Invalid credentials'));
      },
      build: () => AuthBloc(mockAuthRepository),
      // Skip the initial AuthCheckRequested from _init()
      skip: 2,
      act: (bloc) => bloc.add(const AuthSignInRequested(
        email: 'test@example.com',
        password: 'wrongpassword',
      )),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(
          status: AuthStatus.error,
          errorMessage: 'Invalid credentials',
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthSignUpRequested success emits [loading, authenticated]',
      setUp: () {
        when(() => mockAuthRepository.currentUser).thenReturn(null);
        when(() => mockAuthRepository.signUpWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
              displayName: any(named: 'displayName'),
            )).thenAnswer((_) async => const Success(testUser));
      },
      build: () => AuthBloc(mockAuthRepository),
      // Skip the initial AuthCheckRequested from _init()
      skip: 2,
      act: (bloc) => bloc.add(const AuthSignUpRequested(
        email: 'test@example.com',
        password: 'password123',
        displayName: 'Test User',
      )),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(status: AuthStatus.authenticated, user: testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthSignUpRequested failure emits [loading, error]',
      setUp: () {
        when(() => mockAuthRepository.currentUser).thenReturn(null);
        when(() => mockAuthRepository.signUpWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
              displayName: any(named: 'displayName'),
            )).thenAnswer((_) async => const Failure('User already registered'));
      },
      build: () => AuthBloc(mockAuthRepository),
      // Skip the initial AuthCheckRequested from _init()
      skip: 2,
      act: (bloc) => bloc.add(const AuthSignUpRequested(
        email: 'existing@example.com',
        password: 'password123',
        displayName: 'Test User',
      )),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(
          status: AuthStatus.error,
          errorMessage: AppStrings.authErrorEmailAlreadyInUse,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthSignOutRequested success emits [loading, unauthenticated]',
      setUp: () {
        when(() => mockAuthRepository.currentUser).thenReturn(testUser);
        when(() => mockAuthRepository.signOut())
            .thenAnswer((_) async => const Success(null));
      },
      build: () => AuthBloc(mockAuthRepository),
      // Skip the initial AuthCheckRequested from _init()
      skip: 2,
      act: (bloc) => bloc.add(AuthSignOutRequested()),
      expect: () => [
        const AuthState(status: AuthStatus.loading, user: testUser),
        const AuthState(status: AuthStatus.unauthenticated),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthUserChanged(null) emits unauthenticated state',
      setUp: () {
        when(() => mockAuthRepository.currentUser).thenReturn(testUser);
      },
      build: () => AuthBloc(mockAuthRepository),
      // Skip the initial AuthCheckRequested from _init()
      skip: 2,
      act: (bloc) => bloc.add(const AuthUserChanged(null)),
      expect: () => [
        const AuthState(status: AuthStatus.unauthenticated),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthUserChanged(user) emits authenticated state with user',
      setUp: () {
        when(() => mockAuthRepository.currentUser).thenReturn(null);
      },
      build: () => AuthBloc(mockAuthRepository),
      // Skip the initial AuthCheckRequested from _init()
      skip: 2,
      act: (bloc) => bloc.add(const AuthUserChanged(testUser)),
      expect: () => [
        const AuthState(status: AuthStatus.authenticated, user: testUser),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthResetPasswordRequested success emits [loading, unauthenticated] with successMessage',
      setUp: () {
        when(() => mockAuthRepository.currentUser).thenReturn(null);
        when(() => mockAuthRepository.resetPassword(any()))
            .thenAnswer((_) async => const Success(null));
      },
      build: () => AuthBloc(mockAuthRepository),
      // Skip the initial AuthCheckRequested from _init()
      skip: 2,
      act: (bloc) => bloc.add(const AuthResetPasswordRequested(
        email: 'test@example.com',
      )),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(
          status: AuthStatus.unauthenticated,
          successMessage: AppStrings.resetPasswordEmailSent,
        ),
      ],
    );

    blocTest<AuthBloc, AuthState>(
      'AuthResetPasswordRequested failure emits [loading, error]',
      setUp: () {
        when(() => mockAuthRepository.currentUser).thenReturn(null);
        when(() => mockAuthRepository.resetPassword(any()))
            .thenAnswer((_) async => const Failure('user not found', code: '404'));
      },
      build: () => AuthBloc(mockAuthRepository),
      // Skip the initial AuthCheckRequested from _init()
      skip: 2,
      act: (bloc) => bloc.add(const AuthResetPasswordRequested(
        email: 'nonexistent@example.com',
      )),
      expect: () => [
        const AuthState(status: AuthStatus.loading),
        const AuthState(
          status: AuthStatus.error,
          errorMessage: AppStrings.authErrorUserNotFound,
        ),
      ],
    );
  });
}
