import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/data/user_profile_data_source.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late UserProfileDataSource ds;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    ds = UserProfileDataSource(firestore);
  });

  test('watchSettings emits the settings map', () async {
    await firestore.collection('users').doc('u1').set({
      'displayName': 'Rani',
      'settings': {
        'reminderTime': '07:30',
        'reminderDaysBefore': [2, 0],
      },
    });
    expect(await ds.watchSettings('u1').first, {
      'reminderTime': '07:30',
      'reminderDaysBefore': [2, 0],
    });
  });

  test('watchSettings emits null when the document is missing', () async {
    expect(await ds.watchSettings('nobody').first, isNull);
  });

  test('updateReminderSettings changes only the two reminder fields', () async {
    final created = Timestamp.fromDate(DateTime(2026, 11));
    await firestore.collection('users').doc('u1').set({
      'displayName': 'Rani',
      'createdAt': created,
      'settings': {
        'reminderTime': '09:00',
        'reminderDaysBefore': [3, 1, 0],
        'budgetCycleStartDay': 5,
        'timezone': 'Asia/Jakarta',
      },
    });

    await ds.updateReminderSettings(
      'u1',
      time: '06:15',
      daysBefore: [7, 0],
    );

    final data = (await firestore.collection('users').doc('u1').get()).data()!;
    expect(data['displayName'], 'Rani');
    expect(data['createdAt'], created);
    expect(data['settings'], {
      'reminderTime': '06:15',
      'reminderDaysBefore': [7, 0],
      'budgetCycleStartDay': 5,
      'timezone': 'Asia/Jakarta',
    });
  });
}
