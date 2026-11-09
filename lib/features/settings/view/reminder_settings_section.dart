import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/app/theme/spacing.dart';
import 'package:geuralunas/features/settings/bloc/reminder_settings_cubit.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/reminder_repository.dart';
import 'package:geuralunas/repositories/user_profile_repository.dart';

const _choices = [0, 1, 2, 3, 5, 7];

/// Reminder time, reminder days and the state of the related permissions.
class ReminderSettingsSection extends StatelessWidget {
  const ReminderSettingsSection({required this.uid, super.key});

  final String uid;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ReminderSettingsCubit(
        context.read<UserProfileRepository>(),
        context.read<ReminderRepository>(),
        uid: uid,
      ),
      child: const _Body(),
    );
  }
}

class _Body extends StatefulWidget {
  const _Body();

  @override
  State<_Body> createState() => _BodyState();
}

class _BodyState extends State<_Body> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // The user may have changed a permission in the system settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(context.read<ReminderSettingsCubit>().refreshPermissions());
    }
  }

  Future<void> _pickTime(BuildContext context, ReminderSettingsState s) async {
    final cubit = context.read<ReminderSettingsCubit>();
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: s.settings.hour,
        minute: s.settings.minute,
      ),
    );
    if (picked != null) cubit.setTime(picked.hour, picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cubit = context.read<ReminderSettingsCubit>();
    return BlocBuilder<ReminderSettingsCubit, ReminderSettingsState>(
      builder: (context, state) {
        final time = _hhmm(state.settings.hour, state.settings.minute);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.settingsReminderTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: Spacing.sm),
                ListTile(
                  key: const Key('reminder-time'),
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.settingsReminderTime),
                  trailing: Text(time, style: theme.textTheme.titleMedium),
                  onTap: () => _pickTime(context, state),
                ),
                Text(
                  l10n.settingsReminderDays,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: Spacing.sm),
                Wrap(
                  spacing: Spacing.sm,
                  children: [
                    for (final n in _choices)
                      FilterChip(
                        key: Key('reminder-day-$n'),
                        label: Text(l10n.settingsReminderDayChip(n)),
                        selected: state.settings.daysBefore.contains(n),
                        onSelected: (_) => cubit.toggleDay(n),
                      ),
                  ],
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  l10n.settingsReminderDaysHint,
                  style: theme.textTheme.bodySmall,
                ),
                if (!state.permissions.notifications)
                  _PermissionRow(
                    message: l10n.settingsNotificationsOff,
                    action: l10n.settingsNotificationsAllow,
                    onPressed: cubit.requestPermissions,
                  ),
                if (state.permissions.notifications &&
                    !state.permissions.exactAlarms)
                  _PermissionRow(
                    message: l10n.settingsExactAlarmsOff,
                    action: l10n.settingsExactAlarmsOpen,
                    onPressed: cubit.openAlarmSettings,
                  ),
                const SizedBox(height: Spacing.md),
                Text(
                  l10n.settingsBatteryHelp,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.message,
    required this.action,
    required this.onPressed,
  });

  final String message;
  final String action;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(message),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: onPressed, child: Text(action)),
          ),
        ],
      ),
    );
  }
}

String _hhmm(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
