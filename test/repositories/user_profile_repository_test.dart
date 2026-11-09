import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/data/user_profile_data_source.dart';
import 'package:geuralunas/domain/auth/app_user.dart';
import 'package:geuralunas/repositories/user_profile_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockDataSource extends Mock implements UserProfileDataSource {}

const _user = AppUser(uid: 'u1', email: 'rani@mail.com', displayName: 'Rani');

void main() {
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
}
