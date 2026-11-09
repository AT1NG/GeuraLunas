import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/features/settings/view/reminder_settings_section.dart';
import 'package:geuralunas/repositories/reminder_repository.dart';
import 'package:geuralunas/repositories/user_profile_repository.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  late FakeUserProfileRepository profiles;
  late FakeReminderRepository reminders;

  setUp(() {
    profiles = FakeUserProfileRepository();
    reminders = FakeReminderRepository();
  });

  Future<void> pump(WidgetTester tester, {double textScale = 1}) async {
    await pumpApp(
      tester,
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(
          body: SingleChildScrollView(
            child: MultiRepositoryProvider(
              providers: [
                RepositoryProvider<UserProfileRepository>.value(
                  value: profiles,
                ),
                RepositoryProvider<ReminderRepository>.value(value: reminders),
              ],
              child: const ReminderSettingsSection(uid: 'u1'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool selected(WidgetTester tester, int n) =>
      tester.widget<FilterChip>(find.byKey(Key('reminder-day-$n'))).selected;

  testWidgets('shows the day chips with the defaults selected', (
    tester,
  ) async {
    await pump(tester);

    for (final n in [0, 1, 2, 3, 5, 7]) {
      expect(find.byKey(Key('reminder-day-$n')), findsOneWidget);
    }
    expect(find.text('H-5'), findsOneWidget);
    expect([0, 1, 3].every((n) => selected(tester, n)), isTrue);
    expect([2, 5, 7].any((n) => selected(tester, n)), isFalse);
    expect(find.text('09:00'), findsOneWidget);
  });

  testWidgets('tapping a chip saves the new days', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('reminder-day-5')));
    await tester.pumpAndSettle();

    expect(selected(tester, 5), isTrue);
    expect(profiles.saved.single.daysBefore, [5, 3, 1, 0]);
  });

  testWidgets('the last selected chip stays selected', (tester) async {
    await pump(tester);
    for (final n in [3, 1]) {
      await tester.tap(find.byKey(Key('reminder-day-$n')));
      await tester.pumpAndSettle();
    }

    await tester.tap(find.byKey(const Key('reminder-day-0')));
    await tester.pumpAndSettle();

    expect(selected(tester, 0), isTrue);
  });

  testWidgets('picking a time saves it', (tester) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('reminder-time')));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(TimePickerDialog),
            matching: find.byType(TextButton),
          )
          .last,
    );
    await tester.pumpAndSettle();

    expect(find.byType(TimePickerDialog), findsNothing);
    expect(profiles.saved.single.hour, 9);
  });

  testWidgets('offers to allow notifications when they are off', (
    tester,
  ) async {
    reminders.state = const ReminderPermissions(
      notifications: false,
      exactAlarms: true,
    );
    await pump(tester);

    expect(find.text('Izinkan'), findsOneWidget);
    await tester.tap(find.text('Izinkan'));
    await tester.pumpAndSettle();
    expect(reminders.calls, contains('request'));
  });

  testWidgets('hides the permission rows when everything is allowed', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text('Izinkan'), findsNothing);
    expect(find.text('Pengingat bisa meleset beberapa menit.'), findsNothing);
  });

  testWidgets('explains drifting reminders when exact alarms are off', (
    tester,
  ) async {
    reminders.state = const ReminderPermissions(
      notifications: true,
      exactAlarms: false,
    );
    await pump(tester);

    expect(find.text('Pengingat bisa meleset beberapa menit.'), findsOneWidget);
    await tester.tap(find.text('Buka pengaturan'));
    await tester.pumpAndSettle();
    expect(reminders.calls, contains('alarm-settings'));
  });

  testWidgets('always shows the battery tip', (tester) async {
    await pump(tester);

    expect(
      find.text(
        'Kalau notifikasi tidak muncul, matikan penghemat baterai untuk '
        'GeuraLunas.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('does not overflow at 2x text size', (tester) async {
    reminders.state = const ReminderPermissions(
      notifications: false,
      exactAlarms: false,
    );
    await pump(tester, textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
