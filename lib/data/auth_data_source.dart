import 'dart:developer' as developer;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper over [FirebaseAuth] and [GoogleSignIn]. No logic here.
class AuthDataSource {
  AuthDataSource({FirebaseAuth? auth, GoogleSignIn? googleSignIn})
    : _auth = auth ?? FirebaseAuth.instance,
      _google = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  Future<void>? _googleInit;

  /// Also fires when the profile changes (for example the display name set
  /// right after sign-up), not only on sign-in and sign-out.
  Stream<User?> authStateChanges() => _auth.userChanges();

  Future<void> signInWithEmail(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user?.updateDisplayName(displayName);
  }

  /// Returns `false` when the user dismissed the Google account picker.
  Future<bool> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    try {
      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw FirebaseAuthException(code: 'missing-id-token');
      }
      await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // A wrong SHA-1 or OAuth setup can also surface as "canceled".
        developer.log(
          'Google sign-in canceled: ${e.description}',
          name: 'AuthDataSource',
        );
        return false;
      }
      rethrow;
    }
  }

  Future<void> _ensureGoogleInitialized() async {
    final init = _googleInit ??= _google.initialize();
    try {
      await init;
    } on Object {
      // Do not cache a failed initialization: allow the next attempt to retry.
      _googleInit = null;
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _google.signOut();
    } on Object catch (error) {
      // Firebase sign-out already succeeded; clearing Google's cached account
      // is best effort (it may not be initialized for email-only users).
      developer.log(
        'Google signOut failed',
        name: 'AuthDataSource',
        error: error,
      );
    }
  }
}
