import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/features/auth/bloc/forgot_password_cubit.dart';
import 'package:geuralunas/features/auth/bloc/submit_status.dart';
import 'package:geuralunas/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  late _MockRepo repo;
  setUp(() => repo = _MockRepo());

  TypeMatcher<ForgotPasswordState> status(SubmitStatus s) =>
      isA<ForgotPasswordState>().having((x) => x.status, 'status', s);

  blocTest<ForgotPasswordCubit, ForgotPasswordState>(
    'emits [submitting, success]',
    setUp: () =>
        when(() => repo.sendPasswordReset(any())).thenAnswer((_) async {}),
    build: () => ForgotPasswordCubit(repo)..emailChanged('rani@mail.com'),
    act: (c) => c.submit(),
    expect: () => [
      status(SubmitStatus.submitting),
      status(SubmitStatus.success),
    ],
  );
}
