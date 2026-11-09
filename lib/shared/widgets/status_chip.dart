import 'package:flutter/material.dart';
import 'package:geuralunas/l10n/l10n.dart';

/// What state a debt is in, for display.
enum DebtStatusKind {
  /// Past its due date.
  overdue,

  /// Due within the next few days.
  dueSoon,

  /// Fully paid.
  settled,

  /// Running normally.
  active,
}

/// A label with an icon, so status never relies on colour alone.
class StatusChip extends StatelessWidget {
  /// Creates a chip for [kind].
  const StatusChip(this.kind, {super.key});

  /// The state to show.
  final DebtStatusKind kind;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final (label, icon, background, foreground) = switch (kind) {
      DebtStatusKind.overdue => (
        l10n.statusOverdue,
        Icons.warning_amber_rounded,
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      DebtStatusKind.dueSoon => (
        l10n.statusDueSoon,
        Icons.schedule,
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      DebtStatusKind.settled => (
        l10n.statusSettled,
        Icons.check_circle_outline,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      DebtStatusKind.active => (
        l10n.statusActive,
        Icons.circle_outlined,
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
      ),
    };
    return Chip(
      avatar: Icon(icon, color: foreground),
      label: Text(label, style: TextStyle(color: foreground)),
      backgroundColor: background,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
