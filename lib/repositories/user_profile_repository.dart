import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geuralunas/data/user_profile_data_source.dart';
import 'package:geuralunas/domain/auth/app_user.dart';

// ignore: one_member_abstracts // interface boundary, mocked in tests
abstract interface class UserProfileRepository {
  /// Creates `users/{uid}` with default settings if it does not exist yet.
  Future<void> ensureProfile(AppUser user);
}

class UserProfileRepositoryImpl implements UserProfileRepository {
  UserProfileRepositoryImpl(this._dataSource);

  final UserProfileDataSource _dataSource;

  // Sign-up emits the user twice (before and after the display name). Two
  // overlapping runs would both see no profile and both create it; the second
  // create is then an update that the rules reject (createdAt changes).
  Future<void> _queue = Future<void>.value();

  @override
  Future<void> ensureProfile(AppUser user) {
    final run = _queue.then((_) => _ensure(user));
    _queue = run.then((_) {}, onError: (Object _) {});
    return run;
  }

  Future<void> _ensure(AppUser user) async {
    if (await _dataSource.exists(user.uid)) {
      // Sign-up creates the account before the display name is set, so the
      // first profile may have been written without it.
      final name = user.displayName;
      if (name != null && name.isNotEmpty) {
        await _dataSource.setDisplayName(user.uid, name);
      }
      return;
    }
    await _dataSource.create(user.uid, {
      if (user.displayName != null) 'displayName': user.displayName,
      'email': user.email,
      'createdAt': FieldValue.serverTimestamp(),
      'settings': {
        'reminderTime': '09:00',
        'reminderDaysBefore': [3, 1, 0],
        'budgetCycleStartDay': 1,
        'timezone': 'Asia/Jakarta',
      },
    });
  }
}
