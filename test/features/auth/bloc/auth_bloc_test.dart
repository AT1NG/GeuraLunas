import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/auth/app_user.dart';
import 'package:geuralunas/features/auth/bloc/auth_bloc.dart';
import 'package:geuralunas/repositories/auth_repository.dart';
import 'package:geuralunas/repositories/user_profile_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

class _MockProfiles extends Mock implements UserProfileRepository {}

const _user = AppUser(uid: 'u1', email: 'rani@mail.com');

void main() {
  late _MockRepo repo;
  late _MockProfiles profiles;
  setUpAll(() => registerFallbackValue(_user));
  setUp(() {
    repo = _MockRepo();
    profiles = _MockProfiles();
    when(() => profiles.ensureProfile(any())).thenAnswer((_) async {});
  });

  test('starts as unknown', () {
    expect(AuthBloc(repo, profiles).state.status, AuthStatus.unknown);
  });

  blocTest<AuthBloc, AuthState>(
    'emits authenticated when stream emits user',
    setUp: () => when(
      () => repo.authStateChanges,
    ).thenAnswer((_) => Stream.value(_user)),
    build: () => AuthBloc(repo, profiles),
    act: (b) => b.add(const AuthStarted()),
    expect: () => [
      const AuthState(status: AuthStatus.authenticated, user: _user),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits unauthenticated when stream emits null',
    setUp: () =>
        when(() => repo.authStateChanges).thenAnswer((_) => Stream.value(null)),
    build: () => AuthBloc(repo, profiles),
    act: (b) => b.add(const AuthStarted()),
    expect: () => [const AuthState(status: AuthStatus.unauthenticated)],
    verify: (_) => verifyNever(() => profiles.ensureProfile(any())),
  );

  blocTest<AuthBloc, AuthState>(
    'sign out calls repository',
    setUp: () => when(() => repo.signOut()).thenAnswer((_) async {}),
    build: () => AuthBloc(repo, profiles),
    act: (b) => b.add(const AuthSignOutRequested()),
    verify: (_) => verify(() => repo.signOut()).called(1),
  );

  blocTest<AuthBloc, AuthState>(
    'calls ensureProfile once when authenticated',
    setUp: () => when(
      () => repo.authStateChanges,
    ).thenAnswer((_) => Stream.fromIterable([_user, _user])),
    build: () => AuthBloc(repo, profiles),
    act: (b) => b.add(const AuthStarted()),
    verify: (_) => verify(() => profiles.ensureProfile(_user)).called(1),
  );

  blocTest<AuthBloc, AuthState>(
    'login still succeeds when ensureProfile throws',
    setUp: () {
      when(
        () => repo.authStateChanges,
      ).thenAnswer((_) => Stream.value(_user));
      when(() => profiles.ensureProfile(any())).thenThrow(Exception('offline'));
    },
    build: () => AuthBloc(repo, profiles),
    act: (b) => b.add(const AuthStarted()),
    expect: () => [
      const AuthState(status: AuthStatus.authenticated, user: _user),
    ],
  );
}
