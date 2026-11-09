import 'dart:async';
import 'dart:developer' as developer;

import 'package:geuralunas/data/notification_data_source.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/debt/payments.dart';
import 'package:geuralunas/domain/reminder/reminder_plan.dart';
import 'package:geuralunas/repositories/debt_repository.dart';
import 'package:geuralunas/repositories/user_profile_repository.dart';

export 'package:geuralunas/data/notification_data_source.dart'
    show ReminderPermissions;

abstract interface class ReminderRepository {
  /// Replaces every scheduled reminder with the ones the current debts call
  /// for, and returns how many were planned. Never throws; a failure gives 0
  /// and the next call tries again.
  Future<int> rescheduleAll();

  /// Removes every scheduled reminder, after any running reschedule.
  Future<void> cancelAll();

  Future<ReminderPermissions> permissions();

  /// Asks for notification permission and returns the new state.
  Future<ReminderPermissions> requestPermissions();

  /// Opens the system screen for exact alarms.
  Future<void> openAlarmSettings();

  /// Debt ids of notifications tapped while the app runs.
  Stream<String> get taps;

  /// Debt id of the notification that started the app, if any.
  String? get launchDebtId;
}

class ReminderRepositoryImpl implements ReminderRepository {
  ReminderRepositoryImpl({
    required DebtRepository debts,
    required UserProfileRepository profiles,
    required NotificationDataSource notifications,
    required String? Function() currentUid,
  }) : _debts = debts,
       _profiles = profiles,
       _notifications = notifications,
       _currentUid = currentUid;

  final DebtRepository _debts;
  final UserProfileRepository _profiles;
  final NotificationDataSource _notifications;
  final String? Function() _currentUid;

  // Cancel-then-schedule must never interleave with another run, or a stale
  // plan could land after a fresh one.
  Future<void> _queue = Future<void>.value();

  Future<T> _serial<T>(Future<T> Function() job) {
    final run = _queue.then((_) => job());
    _queue = run.then((_) {}, onError: (Object _) {});
    return run;
  }

  @override
  Future<int> rescheduleAll() => _serial(_reschedule);

  Future<int> _reschedule() async {
    final uid = _currentUid();
    if (uid == null) return 0;
    try {
      final settings = await _profiles.watchReminderSettings(uid).first;
      final debts = await _debts.watchDebts().first;
      final states = <DebtState>[];
      for (final debt in debts) {
        if (debt.direction != DebtDirection.owe ||
            debt.status != DebtStatus.active) {
          continue;
        }
        final installments = await _debts.watchInstallments(debt.id).first;
        states.add(DebtState(debt: debt, installments: installments));
      }
      final plans = planReminders(
        debts: states,
        settings: settings,
        now: _notifications.wallClockNow(),
      );
      await _notifications.cancelAll();
      await _notifications.schedule(plans);
      return plans.length;
    } on Object catch (e) {
      // Reminders are a convenience: a failure must not reach the user's
      // flow. No names or amounts in the log.
      developer.log('Rescheduling reminders failed: ${e.runtimeType}');
      return 0;
    }
  }

  @override
  Future<void> cancelAll() => _serial(() async {
    try {
      await _notifications.cancelAll();
    } on Object catch (e) {
      developer.log('Cancelling reminders failed: ${e.runtimeType}');
    }
  });

  @override
  Future<ReminderPermissions> permissions() => _notifications.permissions();

  @override
  Future<ReminderPermissions> requestPermissions() =>
      _notifications.requestPermissions();

  @override
  Future<void> openAlarmSettings() => _notifications.openAlarmSettings();

  @override
  Stream<String> get taps => _notifications.taps;

  @override
  String? get launchDebtId => _notifications.launchDebtId;
}
