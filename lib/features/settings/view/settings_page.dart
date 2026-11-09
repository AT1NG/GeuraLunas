import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/app/theme/spacing.dart';
import 'package:geuralunas/domain/auth/app_user.dart';
import 'package:geuralunas/features/auth/bloc/auth_bloc.dart';
import 'package:geuralunas/l10n/l10n.dart';

/// Account info and sign-out.
class SettingsPage extends StatelessWidget {
  /// Creates the settings page.
  const SettingsPage({super.key});

  Future<void> _confirmSignOut(BuildContext context) async {
    final l10n = context.l10n;
    final bloc = context.read<AuthBloc>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.settingsSignOutConfirmTitle),
        content: Text(l10n.settingsSignOutConfirmBody),
        actions: [
          TextButton(
            key: const Key('settings-sign-out-cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const Key('settings-sign-out-confirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.settingsSignOut),
          ),
        ],
      ),
    );
    if (confirmed ?? false) bloc.add(const AuthSignOutRequested());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final user = context.select<AuthBloc, AppUser?>((b) => b.state.user);
    final name = user?.displayName;
    return Scaffold(
      key: const Key('settings-page'),
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Spacing.md),
          children: [
            Card(
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person_outline)),
                title: Text(
                  name == null || name.isEmpty ? l10n.settingsNoName : name,
                ),
                subtitle: Text(user?.email ?? ''),
              ),
            ),
            const SizedBox(height: Spacing.md),
            OutlinedButton.icon(
              key: const Key('settings-sign-out'),
              onPressed: () => _confirmSignOut(context),
              icon: const Icon(Icons.logout),
              label: Text(l10n.settingsSignOut),
            ),
          ],
        ),
      ),
    );
  }
}
