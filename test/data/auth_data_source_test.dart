import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/data/auth_data_source.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements FirebaseAuth {}

class _MockGoogle extends Mock implements GoogleSignIn {}

void main() {
  late _MockAuth auth;
  late _MockGoogle google;
  late AuthDataSource ds;

  setUpAll(
    () => registerFallbackValue(
      const AuthCredential(
        providerId: 'google.com',
        signInMethod: 'google.com',
      ),
    ),
  );

  setUp(() {
    auth = _MockAuth();
    google = _MockGoogle();
    ds = AuthDataSource(auth: auth, googleSignIn: google);
  });

  test('Google canceled returns false', () async {
    when(() => google.initialize()).thenAnswer((_) async {});
    when(() => google.authenticate()).thenThrow(
      const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
    );

    expect(await ds.signInWithGoogle(), isFalse);
    verifyNever(() => auth.signInWithCredential(any()));
  });

  test('other Google errors are rethrown', () async {
    when(() => google.initialize()).thenAnswer((_) async {});
    when(() => google.authenticate()).thenThrow(
      const GoogleSignInException(code: GoogleSignInExceptionCode.unknownError),
    );

    await expectLater(
      ds.signInWithGoogle(),
      throwsA(isA<GoogleSignInException>()),
    );
  });

  test('a failed initialize is retried on the next attempt', () async {
    var calls = 0;
    when(() => google.initialize()).thenAnswer((_) async {
      calls++;
      if (calls == 1) throw StateError('init failed');
    });
    when(() => google.authenticate()).thenThrow(
      const GoogleSignInException(code: GoogleSignInExceptionCode.canceled),
    );

    await expectLater(ds.signInWithGoogle(), throwsStateError);
    expect(await ds.signInWithGoogle(), isFalse);
    expect(calls, 2);
  });
}
