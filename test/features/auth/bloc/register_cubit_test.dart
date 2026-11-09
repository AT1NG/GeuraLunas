import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/features/auth/bloc/register_cubit.dart';
import 'package:geuralunas/features/auth/bloc/submit_status.dart';
import 'package:geuralunas/repositories/auth_failure.dart';
import 'package:geuralunas/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  late _MockRepo repo;
  setUp(() => repo = _MockRepo());

  TypeMatcher<RegisterState> status(SubmitStatus s) =>
      isA<RegisterState>().having((x) => x.status, 'status', s);

  blocTest<RegisterCubit, RegisterState>(
    'EmailInUse becomes failure',
    setUp: () => when(
      () => repo.signUpWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
        displayName: any(named: 'displayName'),
      ),
    ).thenThrow(const EmailInUse()),
    build: () => RegisterCubit(repo)
      ..nameChanged('Rani')
      ..emailChanged('rani@mail.com')
      ..passwordChanged('12345678'),
    act: (c) => c.submit(),
    expect: () => [
      status(SubmitStatus.submitting),
      status(
        SubmitStatus.failure,
      ).having((s) => s.failure, 'failure', isA<EmailInUse>()),
    ],
  );

  blocTest<RegisterCubit, RegisterState>(
    'invalid input does not call repository',
    build: () => RegisterCubit(repo)
      ..nameChanged(' ')
      ..emailChanged('rani@mail.com')
      ..passwordChanged('12345678'),
    act: (c) => c.submit(),
    verify: (_) => verifyNever(
      () => repo.signUpWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
        displayName: any(named: 'displayName'),
      ),
    ),
  );
}
