import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/app/theme/spacing.dart';
import 'package:geuralunas/domain/budget/category.dart';
import 'package:geuralunas/domain/budget/expense.dart';
import 'package:geuralunas/features/budget/bloc/categories_cubit.dart';
import 'package:geuralunas/features/budget/bloc/expenses_cubit.dart';
import 'package:geuralunas/features/budget/widgets/category_style.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/category_repository.dart';
import 'package:geuralunas/repositories/expense_repository.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';
import 'package:geuralunas/shared/widgets/confirm_dialog.dart';
import 'package:geuralunas/shared/widgets/empty_state.dart';
import 'package:geuralunas/shared/widgets/money_text.dart';
import 'package:go_router/go_router.dart';

/// The budget tab: this cycle's expenses and the way to manage categories.
class BudgetPage extends StatelessWidget {
  /// Creates the page.
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              ExpensesCubit(context.read<ExpenseRepository>())..start(),
        ),
        BlocProvider(
          create: (context) {
            final cubit = CategoriesCubit(context.read<CategoryRepository>());
            unawaited(cubit.start());
            return cubit;
          },
        ),
      ],
      child: const _BudgetView(),
    );
  }
}

class _BudgetView extends StatefulWidget {
  const _BudgetView();

  @override
  State<_BudgetView> createState() => _BudgetViewState();
}

class _BudgetViewState extends State<_BudgetView> with WidgetsBindingObserver {
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

  // The tab keeps its state while the app sleeps, so a new day (or month)
  // would otherwise leave the list on the cycle it first opened with.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<ExpensesCubit>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Scaffold(
      key: const Key('budget-page'),
      appBar: AppBar(title: Text(l10n.navBudget)),
      body: BlocBuilder<ExpensesCubit, ExpensesState>(
        builder: (context, state) {
          final categories = context.watch<CategoriesCubit>().state.categories;
          final days = state.byDay;
          return ListView(
            padding: const EdgeInsets.only(bottom: Spacing.xl),
            children: [
              ListTile(
                key: const Key('manage-categories'),
                leading: const Icon(Icons.category_outlined),
                title: Text(l10n.budgetManageCategories),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => unawaited(context.push('/budget/categories')),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.md,
                  Spacing.md,
                  Spacing.md,
                  Spacing.sm,
                ),
                child: Text(
                  l10n.budgetExpensesTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (state.status != ExpensesStatus.loading &&
                  state.expenses.isEmpty)
                EmptyState(
                  icon: Icons.shopping_bag_outlined,
                  message: l10n.budgetExpensesEmpty,
                ),
              for (final entry in days.entries) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.md,
                    Spacing.sm,
                    Spacing.md,
                    0,
                  ),
                  child: Text(
                    formatDate(entry.key),
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                for (final expense in entry.value)
                  _ExpenseRow(
                    expense: expense,
                    category: _find(categories, expense.categoryId),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }

  static Category? _find(List<Category> all, String id) {
    for (final c in all) {
      if (c.id == id) return c;
    }
    return null;
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.expense, required this.category});

  final Expense expense;
  final Category? category;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cat = category;
    final note = expense.note;
    return ListTile(
      key: Key('expense-row-${expense.id}'),
      leading: Icon(
        categoryIcon(cat?.icon ?? ''),
        color: categoryColor(cat?.colorHex ?? ''),
      ),
      title: Text(cat?.name ?? l10n.budgetUncategorized),
      subtitle: note == null ? null : Text(note),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          MoneyText(expense.amount),
          IconButton(
            key: Key('expense-delete-${expense.id}'),
            icon: const Icon(Icons.delete_outline),
            tooltip: l10n.budgetDeleteConfirm,
            onPressed: () async {
              final cubit = context.read<ExpensesCubit>();
              final ok = await ConfirmDialog.show(
                context,
                title: l10n.budgetDeleteTitle,
                body: l10n.budgetDeleteBody,
                confirmLabel: l10n.budgetDeleteConfirm,
              );
              if (ok) unawaited(cubit.delete(expense.id));
            },
          ),
        ],
      ),
    );
  }
}
