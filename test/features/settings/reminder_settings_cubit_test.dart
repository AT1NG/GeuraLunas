import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/data/notification_data_source.dart';
import 'package:geuralunas/domain/reminder/reminder_settings.dart';
import 'package:geuralunas/features/settings/bloc/reminder_settings_cubit.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeUserProfileRepository profiles;
  late FakeReminderRepository reminders;
  late ReminderSettingsCubit cubit;

  setUp(() async {
    profiles = FakeUserProfileRepository();
    reminders = FakeReminderRepository();
    cubit = ReminderSettingsCubit(profiles, reminders, uid: 'u1');
    await pumpEventQueue();
  });

  tearDown(() => cubit.close());

  test('loads settings and permissions at the start', () async {
    expect(cubit.state.settings, ReminderSettings.defaults);
    expect(cubit.state.permissions, reminders.state);
  });

  test('follows settings that change elsewhere', () async {
    profiles.setSettings(
      ReminderSettings.defaults.copyWith(hour: 6, daysBefore: [1]),
    );
    await pumpEventQueue();
    expect(cubit.state.settings.hour, 6);
    expect(cubit.state.settings.daysBefore, [1]);
  });

  test('setTime saves and reschedules', () async {
    cubit.setTime(7, 30);
    await pumpEventQueue();

    expect(cubit.state.settings.hour, 7);
    expect(cubit.state.settings.minute, 30);
    expect(profiles.saved.single.hour, 7);
    expect(reminders.calls, contains('reschedule'));
  });

  test('toggleDay adds a day and keeps the list from late to soon', () async {
    cubit.toggleDay(5);
    await pumpEventQueue();
    expect(cubit.state.settings.daysBefore, [5, 3, 1, 0]);
    expect(profiles.saved.single.daysBefore, [5, 3, 1, 0]);
  });

  test('toggleDay removes a selected day', () async {
    cubit.toggleDay(3);
    await pumpEventQueue();
    expect(cubit.state.settings.daysBefore, [1, 0]);
  });

  test('the last day cannot be removed', () async {
    profiles.setSettings(ReminderSettings.defaults.copyWith(daysBefore: [2]));
    await pumpEventQueue();
    profiles.saved.clear();
    reminders.calls.clear();

    cubit.toggleDay(2);
    await pumpEventQueue();

    expect(cubit.state.settings.daysBefore, [2]);
    expect(profiles.saved, isEmpty);
    expect(reminders.calls, isNot(contains('reschedule')));
  });

  test('requestPermissions updates the state', () async {
    reminders.state = const ReminderPermissions(
      notifications: false,
      exactAlarms: true,
    );
    await cubit.requestPermissions();
    expect(cubit.state.permissions.notifications, isFalse);
    expect(reminders.calls, contains('request'));
  });

  test('refreshPermissions reads the current state', () async {
    reminders.state = const ReminderPermissions(
      notifications: true,
      exactAlarms: false,
    );
    await cubit.refreshPermissions();
    expect(cubit.state.permissions.exactAlarms, isFalse);
  });

  test('openAlarmSettings goes to the system screen', () async {
    await cubit.openAlarmSettings();
    expect(reminders.calls, contains('alarm-settings'));
  });
}
