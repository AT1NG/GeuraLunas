import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/data/user_profile_data_source.dart';
import 'package:geuralunas/domain/auth/app_user.dart';
import 'package:geuralunas/domain/reminder/reminder_settings.dart';
import 'package:geuralunas/repositories/user_profile_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements UserProfileDataSource {}

const _user = AppUser(uid: 'u1', email: 'rani@mail.com', displayName: 'Rani');

void main() {
  settingsTests();
  late _MockDataSource ds;
  late UserProfileRepositoryImpl repo;

  setUp(() {
    ds = _MockDataSource();
    repo = UserProfileRepositoryImpl(ds);
  });

  test('creates profile with default settings when missing', () async {
    when(() => ds.exists('u1')).thenAnswer((_) async => false);
    when(() => ds.create(any(), any())).thenAnswer((_) async {});

    await repo.ensureProfile(_user);

    final captured =
        verify(() => ds.create('u1', captureAny())).captured.single
            as Map<String, Object?>;
    expect(captured['displayName'], 'Rani');
    expect(captured['email'], 'rani@mail.com');
    expect(captured['createdAt'], isA<FieldValue>());
    expect(captured['settings'], {
      'reminderTime': '09:00',
      'reminderDaysBefore': [3, 1, 0],
      'budgetCycleStartDay': 1,
      'timezone': 'Asia/Jakarta',
    });
    expect(captured.keys.toSet(), {
      'displayName',
      'email',
      'createdAt',
      'settings',
    });
  });

  test('does not overwrite existing profile', () async {
    when(() => ds.exists('u1')).thenAnswer((_) async => true);
    when(() => ds.setDisplayName(any(), any())).thenAnswer((_) async {});

    await repo.ensureProfile(_user);

    verifyNever(() => ds.create(any(), any()));
  });

  test('fills in displayName on an existing profile', () async {
    when(() => ds.exists('u1')).thenAnswer((_) async => true);
    when(() => ds.setDisplayName(any(), any())).thenAnswer((_) async {});

    await repo.ensureProfile(_user);

    verify(() => ds.setDisplayName('u1', 'Rani')).called(1);
    verifyNever(() => ds.create(any(), any()));
  });

  test('leaves existing profile alone when user has no displayName', () async {
    when(() => ds.exists('u2')).thenAnswer((_) async => true);

    await repo.ensureProfile(const AppUser(uid: 'u2', email: 'a@b.co'));

    verifyNever(() => ds.setDisplayName(any(), any()));
  });

  test('omits displayName when user has none', () async {
    when(() => ds.exists('u2')).thenAnswer((_) async => false);
    when(() => ds.create(any(), any())).thenAnswer((_) async {});

    await repo.ensureProfile(const AppUser(uid: 'u2', email: 'a@b.co'));

    final captured =
        verify(() => ds.create('u2', captureAny())).captured.single
            as Map<String, Object?>;
    expect(captured.containsKey('displayName'), isFalse);
  });

  test('concurrent calls never create the profile twice', () async {
    var created = false;
    when(() => ds.exists('u1')).thenAnswer((_) async {
      final seen = created;
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return seen;
    });
    when(() => ds.create(any(), any())).thenAnswer((_) async {
      created = true;
    });
    when(() => ds.setDisplayName(any(), any())).thenAnswer((_) async {});

    await Future.wait([
      repo.ensureProfile(const AppUser(uid: 'u1', email: 'rani@mail.com')),
      repo.ensureProfile(_user),
    ]);

    verify(() => ds.create('u1', any())).called(1);
    verify(() => ds.setDisplayName('u1', 'Rani')).called(1);
  });
}

class _SettingsHarness {
  _SettingsHarness() {
    ds = _MockDataSource();
    repo = UserProfileRepositoryImpl(ds);
  }

  late final _MockDataSource ds;
  late final UserProfileRepositoryImpl repo;

  Future<ReminderSettings> read(Map<String, Object?>? settings) {
    when(
      () => ds.watchSettings('u1'),
    ).thenAnswer((_) => Stream.value(settings));
    return repo.watchReminderSettings('u1').first;
  }
}

void settingsTests() {
  group('reminder settings', () {
    test('reads stored time, days and zone', () async {
      final s = await _SettingsHarness().read({
        'reminderTime': '07:30',
        'reminderDaysBefore': [2, 0],
      });
      expect(
        s,
        const ReminderSettings(
          hour: 7,
          minute: 30,
          daysBefore: [2, 0],
          timezone: 'Asia/Jakarta',
        ),
      );
    });

    test('reads a stored timezone', () async {
      final s = await _SettingsHarness().read({
        'reminderTime': '07:30',
        'reminderDaysBefore': [2, 0],
        'timezone': 'Asia/Makassar',
      });
      expect(s.timezone, 'Asia/Makassar');
    });

    test('falls back to defaults when missing or empty', () async {
      expect(await _SettingsHarness().read(null), ReminderSettings.defaults);
      expect(await _SettingsHarness().read({}), ReminderSettings.defaults);
    });

    test('falls back to defaults for a malformed time', () async {
      final s = await _SettingsHarness().read({
        'reminderTime': 'xx',
        'reminderDaysBefore': [2, 0],
      });
      expect(s, ReminderSettings.defaults);
    });

    test('falls back to defaults for invalid days', () async {
      final s = await _SettingsHarness().read({
        'reminderTime': '07:30',
        'reminderDaysBefore': [9],
      });
      expect(s, ReminderSettings.defaults);
    });

    test('saves time as HH:mm', () async {
      final h = _SettingsHarness();
      when(
        () => h.ds.updateReminderSettings(
          any(),
          time: any(named: 'time'),
          daysBefore: any(named: 'daysBefore'),
        ),
      ).thenAnswer((_) async {});

      await h.repo.saveReminderSettings(
        'u1',
        const ReminderSettings(
          hour: 7,
          minute: 5,
          daysBefore: [1],
          timezone: 'Asia/Jakarta',
        ),
      );

      verify(
        () => h.ds.updateReminderSettings(
          'u1',
          time: '07:05',
          daysBefore: [1],
        ),
      ).called(1);
    });

    test('refuses invalid days without touching the data source', () {
      final h = _SettingsHarness();
      expect(
        () => h.repo.saveReminderSettings(
          'u1',
          ReminderSettings.defaults.copyWith(daysBefore: []),
        ),
        throwsArgumentError,
      );
      verifyZeroInteractions(h.ds);
    });
  });
}
