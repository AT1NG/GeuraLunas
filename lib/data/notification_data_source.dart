import 'dart:async';
import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geuralunas/domain/reminder/reminder_plan.dart';
import 'package:geuralunas/l10n/gen/app_localizations.dart';
import 'package:geuralunas/shared/reminder_text.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// What the user has allowed for reminders.
final class ReminderPermissions extends Equatable {
  const ReminderPermissions({
    required this.notifications,
    required this.exactAlarms,
  });

  /// Notifications may be shown.
  final bool notifications;

  /// Alarms may fire at the exact minute. Without it they can drift.
  final bool exactAlarms;

  @override
  List<Object?> get props => [notifications, exactAlarms];
}

/// The few plugin calls the app needs, so tests can stand in for the plugin.
abstract interface class NotificationsPlatform {
  /// Prepares the plugin. [onTap] gets the payload of a tapped notification.
  Future<void> initialize({required void Function(String? payload) onTap});

  /// Payload of the notification that started the app, if any.
  Future<String?> launchPayload();

  Future<void> cancelAll();

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required String payload,
    required tz.TZDateTime at,
    required bool exact,
  });

  Future<bool> notificationsEnabled();

  Future<bool> canScheduleExact();

  Future<bool> requestNotifications();

  /// Opens the system screen where exact alarms can be allowed.
  Future<bool> requestExactAlarms();
}

/// Schedules and cancels local notifications for payment reminders.
class NotificationDataSource {
  NotificationDataSource(this._platform);

  final NotificationsPlatform _platform;
  final _taps = StreamController<String>.broadcast();

  /// Debt id of the notification that started the app, set by [init].
  String? launchDebtId;

  /// Debt ids of notifications tapped while the app runs.
  Stream<String> get taps => _taps.stream;

  AppLocalizations get _l10n => lookupAppLocalizations(const Locale('id'));

  Future<void> init() async {
    tzdata.initializeTimeZones();
    await _platform.initialize(
      onTap: (payload) {
        if (payload != null) _taps.add(payload);
      },
    );
    launchDebtId = await _platform.launchPayload();
  }

  Future<void> cancelAll() => _platform.cancelAll();

  tz.Location? _location(String name) {
    try {
      return tz.getLocation(name);
    } on Object {
      return null;
    }
  }

  /// The wall clock in [timezone]; the device clock when the name is unknown.
  DateTime wallClockNow(String timezone) {
    final location = _location(timezone);
    if (location == null) return DateTime.now();
    final n = tz.TZDateTime.now(location);
    return DateTime(n.year, n.month, n.day, n.hour, n.minute, n.second);
  }

  /// Schedules [plans], whose times are wall-clock times in [timezone].
  ///
  /// A notification that cannot be scheduled is logged and skipped; the rest
  /// still go out.
  Future<void> schedule(
    List<ReminderPlan> plans, {
    required String timezone,
  }) async {
    final location = _location(timezone);
    final exact = await _canScheduleExact();
    final l10n = _l10n;
    for (final p in plans) {
      try {
        // Without a known zone the time is read on the device clock.
        final at = location == null
            ? tz.TZDateTime.from(p.at, tz.UTC)
            : tz.TZDateTime(
                location,
                p.at.year,
                p.at.month,
                p.at.day,
                p.at.hour,
                p.at.minute,
              );
        await _platform.schedule(
          id: p.id,
          title: reminderTitle(l10n),
          body: reminderBody(p, l10n),
          payload: p.debtId,
          at: at,
          exact: exact,
        );
      } on Object catch (e) {
        developer.log('Could not schedule a reminder: ${e.runtimeType}');
      }
    }
  }

  Future<bool> _canScheduleExact() async {
    try {
      return await _platform.canScheduleExact();
    } on Object {
      return false;
    }
  }

  Future<ReminderPermissions> permissions() async {
    try {
      return ReminderPermissions(
        notifications: await _platform.notificationsEnabled(),
        exactAlarms: await _platform.canScheduleExact(),
      );
    } on Object {
      return const ReminderPermissions(
        notifications: false,
        exactAlarms: false,
      );
    }
  }

  /// Asks for notification permission. Exact alarms are not asked here because
  /// that opens a system screen; see [openAlarmSettings].
  Future<ReminderPermissions> requestPermissions() async {
    try {
      await _platform.requestNotifications();
    } on Object catch (e) {
      developer.log('Notification permission request failed: ${e.runtimeType}');
    }
    return permissions();
  }

  Future<void> openAlarmSettings() async {
    try {
      await _platform.requestExactAlarms();
    } on Object catch (e) {
      developer.log('Could not open alarm settings: ${e.runtimeType}');
    }
  }
}

/// The real plugin behind [NotificationsPlatform]. Checked on a device.
class PluginNotificationsPlatform implements NotificationsPlatform {
  PluginNotificationsPlatform([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> initialize({
    required void Function(String? payload) onTap,
  }) async {
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (r) => onTap(r.payload),
    );
  }

  @override
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp ?? false) {
      return details?.notificationResponse?.payload;
    }
    return null;
  }

  @override
  Future<void> cancelAll() => _plugin.cancelAll();

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required String payload,
    required tz.TZDateTime at,
    required bool exact,
  }) => _plugin.zonedSchedule(
    id: id,
    title: title,
    body: body,
    payload: payload,
    scheduledDate: at,
    notificationDetails: const NotificationDetails(
      android: AndroidNotificationDetails(
        'reminders',
        'Pengingat bayar',
        channelDescription: 'Pengingat sebelum cicilan jatuh tempo',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    androidScheduleMode: exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle,
  );

  @override
  Future<bool> notificationsEnabled() async =>
      await _android?.areNotificationsEnabled() ?? false;

  @override
  Future<bool> canScheduleExact() async =>
      await _android?.canScheduleExactNotifications() ?? false;

  @override
  Future<bool> requestNotifications() async =>
      await _android?.requestNotificationsPermission() ?? false;

  @override
  Future<bool> requestExactAlarms() async =>
      await _android?.requestExactAlarmsPermission() ?? false;
}
