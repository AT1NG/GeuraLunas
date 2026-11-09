import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/data/auth_data_source.dart';
import 'package:geuralunas/domain/auth/app_user.dart';
import 'package:geuralunas/repositories/auth_failure.dart';
import 'package:geuralunas/repositories/auth_repository.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements AuthDataSource {}

class _MockUser extends Mock implements User {}

void main() {
  late _MockDataSource ds;
  late AuthRepositoryImpl repo;

  setUp(() {
    ds = _MockDataSource();
    repo = AuthRepositoryImpl(ds);
  });

  test('normalizes email before sign in', () async {
    when(() => ds.signInWithEmail(any(), any())).thenAnswer((_) async {});
    await repo.signInWithEmail(email: ' Rani@Mail.COM ', password: 'x');
    verify(() => ds.signInWithEmail('rani@mail.com', 'x')).called(1);
  });

  test('normalizes email before sign up', () async {
    when(
      () => ds.signUpWithEmail(any(), any(), any()),
    ).thenAnswer((_) async {});
    await repo.signUpWithEmail(
      email: ' Rani@Mail.COM ',
      password: 'secret123',
      displayName: 'Rani',
    );
    verify(
      () => ds.signUpWithEmail('rani@mail.com', 'secret123', 'Rani'),
    ).called(1);
  });

  group('maps firebase code to failure', () {
    final cases = <String, Matcher>{
      'invalid-credential': isA<InvalidCredentials>(),
      'wrong-password': isA<InvalidCredentials>(),
      'user-not-found': isA<InvalidCredentials>(),
      'invalid-email': isA<InvalidEmail>(),
      'email-already-in-use': isA<EmailInUse>(),
      'weak-password': isA<WeakPassword>(),
      'too-many-requests': isA<TooManyRequests>(),
      'network-request-failed': isA<NetworkFailure>(),
      'account-exists-with-different-credential':
          isA<AccountExistsWithDifferentCredential>(),
      'something-else': isA<UnknownAuthFailure>(),
    };
    for (final MapEntry(key: code, value: matcher) in cases.entries) {
      test(code, () async {
        when(
          () => ds.signInWithEmail(any(), any()),
        ).thenThrow(FirebaseAuthException(code: code));
        await expectLater(
          repo.signInWithEmail(email: 'a@b.co', password: 'x'),
          throwsA(matcher),
        );
      });
    }
  });

  test('maps failure on password reset', () async {
    when(
      () => ds.sendPasswordReset(any()),
    ).thenThrow(FirebaseAuthException(code: 'invalid-email'));
    await expectLater(
      repo.sendPasswordReset('bad'),
      throwsA(isA<InvalidEmail>()),
    );
  });

  test('google cancelled returns false and does not throw', () async {
    when(() => ds.signInWithGoogle()).thenAnswer((_) async => false);
    expect(await repo.signInWithGoogle(), isFalse);
  });

  test('google failure is mapped', () async {
    when(
      () => ds.signInWithGoogle(),
    ).thenThrow(FirebaseAuthException(code: 'network-request-failed'));
    await expectLater(repo.signInWithGoogle(), throwsA(isA<NetworkFailure>()));
  });

  test('non-cancel Google error maps to UnknownAuthFailure', () async {
    when(() => ds.signInWithGoogle()).thenThrow(
      const GoogleSignInException(code: GoogleSignInExceptionCode.unknownError),
    );
    await expectLater(
      repo.signInWithGoogle(),
      throwsA(isA<UnknownAuthFailure>()),
    );
  });

  test('platform error maps to UnknownAuthFailure', () async {
    when(() => ds.signInWithGoogle()).thenThrow(PlatformException(code: 'x'));
    await expectLater(
      repo.signInWithGoogle(),
      throwsA(isA<UnknownAuthFailure>()),
    );
  });

  test('maps firebase user to AppUser', () async {
    final user = _MockUser();
    when(() => user.uid).thenReturn('u1');
    when(() => user.email).thenReturn('rani@mail.com');
    when(() => user.displayName).thenReturn('Rani');
    when(
      () => ds.authStateChanges(),
    ).thenAnswer((_) => Stream<User?>.fromIterable([user, null]));
    await expectLater(
      repo.authStateChanges,
      emitsInOrder([
        const AppUser(uid: 'u1', email: 'rani@mail.com', displayName: 'Rani'),
        null,
      ]),
    );
  });
}
