import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/app/theme/spacing.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/debt_repository.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';
import 'package:geuralunas/shared/widgets/empty_state.dart';
import 'package:go_router/go_router.dart';

/// Lets the user pick which debt a payment is for, then opens its form.
Future<void> showDebtPicker(BuildContext context) {
  final router = GoRouter.of(context);
  final repository = context.read<DebtRepository>();
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _DebtPickerSheet(
      repository: repository,
      onPick: (debt) {
        Navigator.of(sheetContext).pop();
        unawaited(router.push('/debts/${debt.id}/pay'));
      },
      onAdd: () {
        Navigator.of(sheetContext).pop();
        unawaited(router.push('/debts/new'));
      },
    ),
  );
}

class _DebtPickerSheet extends StatefulWidget {
  const _DebtPickerSheet({
    required this.repository,
    required this.onPick,
    required this.onAdd,
  });

  final DebtRepository repository;
  final ValueChanged<Debt> onPick;
  final VoidCallback onAdd;

  @override
  State<_DebtPickerSheet> createState() => _DebtPickerSheetState();
}

String _subtitle(AppLocalizations l10n, Debt debt) {
  final direction = debt.direction == DebtDirection.owe
      ? l10n.detailDirectionOwe
      : l10n.detailDirectionLent;
  final remaining = l10n.debtCardRemaining(formatRupiah(debt.remaining));
  return '$direction · $remaining';
}

class _DebtPickerSheetState extends State<_DebtPickerSheet> {
  late final Future<List<Debt>> _debts = widget.repository.watchDebts().first;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SafeArea(
      child: FutureBuilder<List<Debt>>(
        future: _debts,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(Spacing.lg),
              child: Text(l10n.debtsLoadError, textAlign: TextAlign.center),
            );
          }
          if (!snapshot.hasData) {
            return const Padding(
              padding: EdgeInsets.all(Spacing.lg),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final active =
              snapshot.data!
                  .where((d) => d.status == DebtStatus.active)
                  .toList()
                ..sort(
                  (a, b) => a.counterpartyName.toLowerCase().compareTo(
                    b.counterpartyName.toLowerCase(),
                  ),
                );
          if (active.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              message: l10n.pickerEmpty,
              actionLabel: l10n.pickerAddDebt,
              onAction: widget.onAdd,
            );
          }
          return ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                child: Text(
                  l10n.pickerTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              for (final debt in active)
                ListTile(
                  key: Key('picker-debt-${debt.id}'),
                  title: Text(debt.counterpartyName),
                  subtitle: Text(
                    _subtitle(l10n, debt),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => widget.onPick(debt),
                ),
            ],
          );
        },
      ),
    );
  }
}
