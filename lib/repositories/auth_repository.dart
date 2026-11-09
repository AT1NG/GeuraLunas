import 'package:firebase_auth/firebase_auth.dart';
import 'package:geuralunas/data/auth_data_source.dart';
import 'package:geuralunas/domain/auth/app_user.dart';
import 'package:geuralunas/repositories/auth_failure.dart';
import 'package:geuralunas/shared/validators.dart';

abstract interface class AuthRepository {
  Stream<AppUser?> get authStateChanges;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  });

  /// Returns `false` when the user cancelled.
  Future<bool> signInWithGoogle();

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._dataSource);

  final AuthDataSource _dataSource;

  static String _normalize(String email) => normalizeEmail(email);

  @override
  Stream<AppUser?> get authStateChanges =>
      _dataSource.authStateChanges().map(_toAppUser);

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) => _guard(() => _dataSource.signInWithEmail(_normalize(email), password));

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) => _guard(
    () => _dataSource.signUpWithEmail(
      _normalize(email),
      password,
      displayName.trim(),
    ),
  );

  @override
  Future<bool> signInWithGoogle() => _guard(_dataSource.signInWithGoogle);

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _dataSource.sendPasswordReset(_normalize(email)));

  @override
  Future<void> signOut() => _guard(_dataSource.signOut);

  static AppUser? _toAppUser(User? user) {
    if (user == null) return null;
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
    );
  }

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw _mapFailure(e.code);
    }
  }

  static AuthFailure _mapFailure(String code) => switch (code) {
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => const InvalidCredentials(),
    'invalid-email' => const InvalidEmail(),
    'email-already-in-use' => const EmailInUse(),
    'weak-password' => const WeakPassword(),
    'too-many-requests' => const TooManyRequests(),
    'network-request-failed' => const NetworkFailure(),
    'account-exists-with-different-credential' =>
      const AccountExistsWithDifferentCredential(),
    _ => const UnknownAuthFailure(),
  };
}
