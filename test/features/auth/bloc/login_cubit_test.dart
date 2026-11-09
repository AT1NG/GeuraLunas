import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/features/auth/bloc/login_cubit.dart';
import 'package:geuralunas/features/auth/bloc/submit_status.dart';
import 'package:geuralunas/repositories/auth_failure.dart';
import 'package:geuralunas/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  late _MockRepo repo;
  setUp(() => repo = _MockRepo());

  LoginCubit filled() => LoginCubit(repo)
    ..emailChanged('rani@mail.com')
    ..passwordChanged('12345678');

  TypeMatcher<LoginState> status(SubmitStatus s) =>
      isA<LoginState>().having((x) => x.status, 'status', s);

  blocTest<LoginCubit, LoginState>(
    'submit emits [submitting, success]',
    setUp: () => when(
      () => repo.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {}),
    build: filled,
    act: (c) => c.submit(),
    expect: () => [
      status(SubmitStatus.submitting),
      status(SubmitStatus.success),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'submit failure emits [submitting, failure] with InvalidCredentials',
    setUp: () => when(
      () => repo.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const InvalidCredentials()),
    build: filled,
    act: (c) => c.submit(),
    expect: () => [
      status(SubmitStatus.submitting),
      status(
        SubmitStatus.failure,
      ).having((s) => s.failure, 'failure', isA<InvalidCredentials>()),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'invalid email does not call repository',
    build: () => LoginCubit(repo)
      ..emailChanged('rani@')
      ..passwordChanged('12345678'),
    act: (c) => c.submit(),
    verify: (_) => verifyNever(
      () => repo.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ),
  );

  blocTest<LoginCubit, LoginState>(
    'google cancelled returns to idle without failure',
    setUp: () =>
        when(() => repo.signInWithGoogle()).thenAnswer((_) async => false),
    build: () => LoginCubit(repo),
    act: (c) => c.submitGoogle(),
    expect: () => [
      status(SubmitStatus.submitting),
      status(SubmitStatus.idle).having((s) => s.failure, 'failure', isNull),
    ],
  );
}
