import 'package:flutter/material.dart';
import 'package:geuralunas/app/theme/spacing.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/features/debts/widgets/debt_status.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';
import 'package:geuralunas/shared/widgets/progress_bar.dart';
import 'package:geuralunas/shared/widgets/status_chip.dart';

/// One debt in the list.
class DebtCard extends StatelessWidget {
  /// Creates a card for [debt]; [today] decides overdue and due-soon.
  const DebtCard({
    required this.debt,
    required this.today,
    required this.onTap,
    super.key,
  });

  /// The debt to show.
  final Debt debt;

  /// The current date.
  final DateTime today;

  /// Called when the card is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final due = debt.nextDueDate;
    final dueText = due == null
        ? l10n.debtCardNoDue
        : l10n.debtCardDue(formatDate(due));
    final total = debt.totalPayable.rupiah;
    final progress = total == 0 ? 0.0 : debt.paidTotal.rupiah / total;

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: l10n.debtCardSemantics(
        debt.counterpartyName,
        formatRupiah(debt.remaining),
        dueText,
      ),
      onTap: onTap,
      child: Card(
        key: Key('debt-card-${debt.id}'),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Spacing.md),
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.counterpartyName,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: Spacing.xs),
                StatusChip(statusKindOf(debt, today)),
                const SizedBox(height: Spacing.sm),
                Text(
                  l10n.debtCardRemaining(formatRupiah(debt.remaining)),
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: Spacing.sm),
                ProgressBar(value: progress),
                const SizedBox(height: Spacing.sm),
                Text(dueText, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
