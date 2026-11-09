import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/auth/app_user.dart';
import 'package:geuralunas/features/auth/bloc/auth_bloc.dart';
import 'package:geuralunas/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

const _user = AppUser(uid: 'u1', email: 'rani@mail.com');

void main() {
  late _MockRepo repo;
  setUp(() => repo = _MockRepo());

  test('starts as unknown', () {
    expect(AuthBloc(repo).state.status, AuthStatus.unknown);
  });

  blocTest<AuthBloc, AuthState>(
    'emits authenticated when stream emits user',
    setUp: () => when(
      () => repo.authStateChanges,
    ).thenAnswer((_) => Stream.value(_user)),
    build: () => AuthBloc(repo),
    act: (b) => b.add(const AuthStarted()),
    expect: () => [
      const AuthState(status: AuthStatus.authenticated, user: _user),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'emits unauthenticated when stream emits null',
    setUp: () =>
        when(() => repo.authStateChanges).thenAnswer((_) => Stream.value(null)),
    build: () => AuthBloc(repo),
    act: (b) => b.add(const AuthStarted()),
    expect: () => [const AuthState(status: AuthStatus.unauthenticated)],
  );

  blocTest<AuthBloc, AuthState>(
    'sign out calls repository',
    setUp: () => when(() => repo.signOut()).thenAnswer((_) async {}),
    build: () => AuthBloc(repo),
    act: (b) => b.add(const AuthSignOutRequested()),
    verify: (_) => verify(() => repo.signOut()).called(1),
  );
}
