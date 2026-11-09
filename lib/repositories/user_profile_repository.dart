import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geuralunas/data/user_profile_data_source.dart';
import 'package:geuralunas/domain/auth/app_user.dart';
import 'package:geuralunas/domain/reminder/reminder_settings.dart';

abstract interface class UserProfileRepository {
  /// Creates `users/{uid}` with default settings if it does not exist yet.
  Future<void> ensureProfile(AppUser user);

  /// The reminder settings of [uid], following changes. Falls back to
  /// [ReminderSettings.defaults] while the profile or a field is missing or
  /// invalid.
  Stream<ReminderSettings> watchReminderSettings(String uid);

  /// Saves the reminder time and days. Does not wait for the server.
  ///
  /// Throws [ArgumentError] when `daysBefore` is not valid.
  Future<void> saveReminderSettings(String uid, ReminderSettings settings);
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

  @override
  Stream<ReminderSettings> watchReminderSettings(String uid) =>
      _dataSource.watchSettings(uid).map(_parseSettings);

  @override
  Future<void> saveReminderSettings(String uid, ReminderSettings settings) {
    if (!ReminderSettings.validDaysBefore(settings.daysBefore)) {
      throw ArgumentError.value(
        settings.daysBefore,
        'settings.daysBefore',
        'must be 1 to 8 distinct days from 0 to 7',
      );
    }
    String two(int v) => v.toString().padLeft(2, '0');
    return _dataSource.updateReminderSettings(
      uid,
      time: '${two(settings.hour)}:${two(settings.minute)}',
      daysBefore: settings.daysBefore,
    );
  }
}

final _time = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$');

ReminderSettings _parseSettings(Map<String, Object?>? m) {
  if (m == null) return ReminderSettings.defaults;
  final match = _time.firstMatch('${m['reminderTime']}');
  final raw = m['reminderDaysBefore'];
  final days = raw is List && raw.every((e) => e is int)
      ? raw.cast<int>().toList()
      : null;
  if (match == null ||
      days == null ||
      !ReminderSettings.validDaysBefore(days)) {
    return ReminderSettings.defaults;
  }
  final zone = m['timezone'];
  return ReminderSettings(
    hour: int.parse(match.group(1)!),
    minute: int.parse(match.group(2)!),
    daysBefore: days,
    timezone: zone is String && zone.isNotEmpty
        ? zone
        : ReminderSettings.defaults.timezone,
  );
}
