import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/app/reminder_coordinator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeReminderRepository reminders;
  late StreamController<bool> signedIn;
  late StreamController<Object?> debtChanges;
  late SharedPreferences prefs;
  late List<String> opened;
  late ReminderCoordinator coordinator;
  var debtSubscriptions = 0;

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 80));

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    reminders = FakeReminderRepository();
    signedIn = StreamController<bool>.broadcast();
    debtChanges = StreamController<Object?>.broadcast();
    opened = [];
    debtSubscriptions = 0;
    coordinator = ReminderCoordinator(
      reminders: reminders,
      signedIn: signedIn.stream,
      debtChanges: () {
        debtSubscriptions++;
        return debtChanges.stream;
      },
      prefs: prefs,
      openDebt: opened.add,
      debounce: const Duration(milliseconds: 20),
    )..start();
  });

  tearDown(() async {
    await coordinator.dispose();
    await signedIn.close();
    await debtChanges.close();
  });

  test('signing in reschedules once', () async {
    signedIn.add(true);
    await settle();
    expect(reminders.calls.where((c) => c == 'reschedule'), hasLength(1));
  });

  test('signing out cancels, and the next account reschedules', () async {
    signedIn.add(true);
    await settle();
    reminders.calls.clear();

    signedIn.add(false);
    await settle();
    signedIn.add(true);
    await settle();

    expect(reminders.calls, ['cancel', 'reschedule']);
  });

  test('repeated signed-in events do not reschedule again', () async {
    signedIn
      ..add(true)
      ..add(true);
    await settle();
    expect(reminders.calls.where((c) => c == 'reschedule'), hasLength(1));
  });

  test('a burst of debt changes reschedules once', () async {
    await prefs.setBool('reminderPermissionAsked', true);
    signedIn.add(true);
    await settle();
    reminders.calls.clear();

    debtChanges
      ..add(1)
      ..add(2)
      ..add(3);
    await settle();

    expect(reminders.calls, ['reschedule']);
  });

  test('debt changes are ignored while signed out', () async {
    debtChanges.add(1);
    await settle();
    expect(reminders.calls, isEmpty);
    expect(debtSubscriptions, 0);
  });

  test('an error on the debt stream does not stop later reschedules', () async {
    await prefs.setBool('reminderPermissionAsked', true);
    signedIn.add(true);
    await settle();
    reminders.calls.clear();

    debtChanges.addError(Exception('offline'));
    await settle();
    debtChanges.add(1);
    await settle();

    expect(reminders.calls, ['reschedule']);
  });

  test('onResumed reschedules only when signed in', () async {
    coordinator.onResumed();
    await settle();
    expect(reminders.calls, isEmpty);

    signedIn.add(true);
    await settle();
    reminders.calls.clear();
    coordinator.onResumed();
    await settle();
    expect(reminders.calls, ['reschedule']);
  });

  test('never asks for permission just because the app opened', () async {
    signedIn.add(true);
    await settle();
    debtChanges.add(0); // the first snapshot of existing debts
    await settle();
    coordinator.onResumed();
    await settle();

    expect(reminders.calls, isNot(contains('request')));
    expect(prefs.getBool('reminderPermissionAsked'), isNull);
  });

  test('asks once, when a debt changes and reminders exist', () async {
    signedIn.add(true);
    await settle();
    debtChanges.add(0);
    await settle();
    reminders.calls.clear();

    debtChanges.add(1);
    await settle();
    expect(reminders.calls, ['reschedule', 'request']);
    expect(prefs.getBool('reminderPermissionAsked'), isTrue);

    reminders.calls.clear();
    debtChanges.add(2);
    await settle();
    expect(reminders.calls, ['reschedule']);
  });

  test('is not marked as asked when the request fails', () async {
    reminders.requestError = StateError('no activity');
    signedIn.add(true);
    await settle();
    debtChanges
      ..add(0)
      ..add(1);
    await settle();
    debtChanges.add(2);
    await settle();

    expect(prefs.getBool('reminderPermissionAsked'), isNull);
    expect(reminders.calls.where((c) => c == 'request'), hasLength(2));
  });

  test('does not ask for permission when nothing is planned', () async {
    reminders.planned = 0;
    signedIn.add(true);
    await settle();
    debtChanges
      ..add(0)
      ..add(1);
    await settle();
    expect(reminders.calls.where((c) => c == 'request'), isEmpty);
    expect(prefs.getBool('reminderPermissionAsked'), isNull);
  });

  test('a tapped notification opens its debt', () async {
    signedIn.add(true);
    await settle();
    reminders.tap('d1');
    await settle();
    expect(opened, ['d1']);
  });

  test('the notification that started the app opens once signed in', () async {
    reminders.launchDebtId = 'dLaunch';
    final late = ReminderCoordinator(
      reminders: reminders,
      signedIn: signedIn.stream,
      debtChanges: () => debtChanges.stream,
      prefs: prefs,
      openDebt: opened.add,
      debounce: const Duration(milliseconds: 20),
    )..start();
    await settle();
    expect(opened, isEmpty);

    signedIn.add(true);
    await settle();
    expect(opened, ['dLaunch']);

    signedIn
      ..add(false)
      ..add(true);
    await settle();
    expect(opened, ['dLaunch']);
    await late.dispose();
  });
}
