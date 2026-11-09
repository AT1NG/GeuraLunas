import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/app/theme/spacing.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/features/debts/bloc/debts_cubit.dart';
import 'package:geuralunas/features/debts/widgets/debt_card.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/debt_repository.dart';
import 'package:geuralunas/shared/widgets/empty_state.dart';
import 'package:geuralunas/shared/widgets/money_text.dart';
import 'package:go_router/go_router.dart';

/// All debts, split into "Aku berutang" and "Piutang".
class DebtsPage extends StatelessWidget {
  /// Creates the page.
  const DebtsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => DebtsCubit(context.read<DebtRepository>())..start(),
      child: const _DebtsView(),
    );
  }
}

class _DebtsView extends StatelessWidget {
  const _DebtsView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        key: const Key('debts-page'),
        appBar: AppBar(
          title: Text(l10n.navDebts),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.debtsTabOwe),
              Tab(text: l10n.debtsTabLent),
            ],
          ),
        ),
        body: BlocBuilder<DebtsCubit, DebtsState>(
          builder: (context, state) => switch (state.status) {
            DebtsStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            DebtsStatus.failure => Center(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Text(l10n.debtsLoadError, textAlign: TextAlign.center),
              ),
            ),
            DebtsStatus.loaded => Column(
              children: [
                _FilterBar(filter: state.filter),
                Expanded(
                  child: TabBarView(
                    children: [
                      _DebtGroup(
                        debts: state.owe,
                        total: state.oweRemaining,
                        totalLabel: l10n.debtsTotalOwe,
                        emptyMessage: state.filter == DebtFilter.settled
                            ? l10n.debtsEmptySettled
                            : l10n.debtsEmptyOwe,
                        filter: state.filter,
                      ),
                      _DebtGroup(
                        debts: state.lent,
                        total: state.lentRemaining,
                        totalLabel: l10n.debtsTotalLent,
                        emptyMessage: state.filter == DebtFilter.settled
                            ? l10n.debtsEmptySettled
                            : l10n.debtsEmptyLent,
                        filter: state.filter,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          },
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filter});

  final DebtFilter filter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<DebtsCubit>();
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.sm,
      ),
      child: Wrap(
        spacing: Spacing.sm,
        children: [
          ChoiceChip(
            key: const Key('filter-active'),
            label: Text(l10n.debtsFilterActive),
            selected: filter == DebtFilter.active,
            onSelected: (_) => cubit.setFilter(DebtFilter.active),
          ),
          ChoiceChip(
            key: const Key('filter-settled'),
            label: Text(l10n.debtsFilterSettled),
            selected: filter == DebtFilter.settled,
            onSelected: (_) => cubit.setFilter(DebtFilter.settled),
          ),
        ],
      ),
    );
  }
}

class _DebtGroup extends StatelessWidget {
  const _DebtGroup({
    required this.debts,
    required this.total,
    required this.totalLabel,
    required this.emptyMessage,
    required this.filter,
  });

  final List<Debt> debts;
  final Money total;
  final String totalLabel;
  final String emptyMessage;
  final DebtFilter filter;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final today = DateTime.now();
    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(totalLabel, style: theme.textTheme.bodyMedium),
                MoneyText(total, style: theme.textTheme.headlineMedium),
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.sm),
        if (debts.isEmpty)
          Center(
            child: EmptyState(
              icon: Icons.receipt_long_outlined,
              message: emptyMessage,
              actionLabel: filter == DebtFilter.active
                  ? l10n.debtsEmptyAction
                  : null,
              onAction: () => context.push('/debts/new'),
            ),
          )
        else
          for (final debt in debts)
            DebtCard(
              debt: debt,
              today: today,
              onTap: () => context.push('/debts/${debt.id}'),
            ),
      ],
    );
  }
}
