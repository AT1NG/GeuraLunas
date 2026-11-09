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

  Stream<User?> authStateChanges() => _auth.authStateChanges();

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
    await (_googleInit ??= _google.initialize());
    try {
      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
      return true;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return false;
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);

  Future<void> signOut() async {
    await _auth.signOut();
    await _google.signOut();
  }
}
