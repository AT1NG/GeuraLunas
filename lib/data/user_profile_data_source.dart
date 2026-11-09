import 'package:cloud_firestore/cloud_firestore.dart';

/// Thin wrapper over the `users/{uid}` Firestore document.
class UserProfileDataSource {
  /// Creates a data source backed by the given Firestore instance.
  UserProfileDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, Object?>> _doc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// Whether the profile document exists on the server or in cache.
  Future<bool> exists(String uid) async => (await _doc(uid).get()).exists;

  /// Sets only the display name, leaving the rest of the profile untouched.
  Future<void> setDisplayName(String uid, String displayName) =>
      _doc(uid).set({'displayName': displayName}, SetOptions(merge: true));

  /// Writes the profile document.
  Future<void> create(String uid, Map<String, Object?> data) =>
      _doc(uid).set(data);
}
