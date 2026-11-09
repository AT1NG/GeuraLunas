import 'dart:async';
import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/domain/reminder/reminder_settings.dart';
import 'package:geuralunas/repositories/reminder_repository.dart';
import 'package:geuralunas/repositories/user_profile_repository.dart';

final class ReminderSettingsState extends Equatable {
  const ReminderSettingsState({
    this.settings = ReminderSettings.defaults,
    this.permissions = const ReminderPermissions(
      notifications: true,
      exactAlarms: true,
    ),
  });

  final ReminderSettings settings;
  final ReminderPermissions permissions;

  ReminderSettingsState copyWith({
    ReminderSettings? settings,
    ReminderPermissions? permissions,
  }) => ReminderSettingsState(
    settings: settings ?? this.settings,
    permissions: permissions ?? this.permissions,
  );

  @override
  List<Object?> get props => [settings, permissions];
}

class ReminderSettingsCubit extends Cubit<ReminderSettingsState> {
  ReminderSettingsCubit(this._profiles, this._reminders, {required this.uid})
    : super(const ReminderSettingsState()) {
    _sub = _profiles
        .watchReminderSettings(uid)
        .listen((s) => emit(state.copyWith(settings: s)));
    unawaited(refreshPermissions());
  }

  final UserProfileRepository _profiles;
  final ReminderRepository _reminders;
  final String uid;
  late final StreamSubscription<ReminderSettings> _sub;

  void setTime(int hour, int minute) =>
      _save(state.settings.copyWith(hour: hour, minute: minute));

  /// Adds or removes the reminder [n] days before the due date. The last
  /// remaining day cannot be removed.
  void toggleDay(int n) {
    final days = {...state.settings.daysBefore};
    if (!days.remove(n)) {
      days.add(n);
    } else if (days.isEmpty) {
      return;
    }
    final sorted = days.toList()..sort((a, b) => b.compareTo(a));
    _save(state.settings.copyWith(daysBefore: sorted));
  }

  // The write is not awaited: offline it only completes once the server
  // confirms (ADR-013).
  void _save(ReminderSettings settings) {
    emit(state.copyWith(settings: settings));
    unawaited(
      _profiles
          .saveReminderSettings(uid, settings)
          .catchError(
            (Object e) =>
                developer.log('Saving reminders failed: ${e.runtimeType}'),
          ),
    );
    unawaited(_reminders.rescheduleAll());
  }

  Future<void> refreshPermissions() async =>
      _setPermissions(await _reminders.permissions());

  Future<void> requestPermissions() async =>
      _setPermissions(await _reminders.requestPermissions());

  void _setPermissions(ReminderPermissions permissions) {
    if (!isClosed) emit(state.copyWith(permissions: permissions));
  }

  Future<void> openAlarmSettings() => _reminders.openAlarmSettings();

  @override
  Future<void> close() async {
    await _sub.cancel();
    return super.close();
  }
}
