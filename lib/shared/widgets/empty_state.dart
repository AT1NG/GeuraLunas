import 'package:flutter/material.dart';
import 'package:geuralunas/app/theme/spacing.dart';

/// A friendly placeholder for a list with nothing in it.
class EmptyState extends StatelessWidget {
  /// Creates an empty state with an optional action button.
  const EmptyState({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  /// Illustration icon.
  final IconData icon;

  /// What to tell the user.
  final String message;

  /// Label of the action button; no button when null.
  final String? actionLabel;

  /// Called when the action button is pressed.
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: Spacing.xl * 2,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: Spacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge,
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: Spacing.md),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}
