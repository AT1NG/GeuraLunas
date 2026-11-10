import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/app/theme/spacing.dart';
import 'package:geuralunas/features/auth/bloc/submit_status.dart';
import 'package:geuralunas/features/budget/bloc/add_expense_cubit.dart';
import 'package:geuralunas/features/budget/bloc/categories_cubit.dart';
import 'package:geuralunas/features/budget/widgets/category_style.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/category_repository.dart';
import 'package:geuralunas/repositories/expense_repository.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';
import 'package:geuralunas/shared/widgets/amount_field.dart';
import 'package:geuralunas/shared/widgets/submit_button.dart';

/// Opens the quick "record an expense" sheet: amount, category, save.
///
/// Shows a short confirmation on the screen underneath once saved.
Future<void> showAddExpenseSheet(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final saved = context.l10n.addExpenseSaved;
  final categories = context.read<CategoryRepository>();
  final expenses = context.read<ExpenseRepository>();
  final done = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final cubit = CategoriesCubit(categories);
            unawaited(cubit.start());
            return cubit;
          },
        ),
        BlocProvider(create: (_) => AddExpenseCubit(expenses)),
      ],
      child: const _AddExpenseSheet(),
    ),
  );
  if (done ?? false) {
    messenger.showSnackBar(SnackBar(content: Text(saved)));
  }
}

class _AddExpenseSheet extends StatelessWidget {
  const _AddExpenseSheet();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return BlocListener<AddExpenseCubit, AddExpenseState>(
      listenWhen: (a, b) => a.status != b.status,
      listener: (context, state) {
        if (state.status == SubmitStatus.success) {
          Navigator.of(context).pop(true);
        }
      },
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            Spacing.md,
            0,
            Spacing.md,
            Spacing.md + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: BlocBuilder<AddExpenseCubit, AddExpenseState>(
            builder: (context, state) {
              final cubit = context.read<AddExpenseCubit>();
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.addExpenseTitle, style: theme.textTheme.titleLarge),
                  const SizedBox(height: Spacing.md),
                  AmountField(
                    fieldKey: const Key('expense-amount'),
                    label: l10n.addExpenseAmountLabel,
                    autofocus: true,
                    onChanged: cubit.amountChanged,
                    errorText: switch (state.error) {
                      AddExpenseError.amountRequired =>
                        l10n.addExpenseAmountRequired,
                      AddExpenseError.amountInvalid =>
                        l10n.addExpenseAmountInvalid,
                      _ => null,
                    },
                  ),
                  const SizedBox(height: Spacing.md),
                  Text(
                    l10n.addExpenseCategory,
                    style: theme.textTheme.labelLarge,
                  ),
                  const SizedBox(height: Spacing.sm),
                  BlocBuilder<CategoriesCubit, CategoriesState>(
                    builder: (context, categories) => Wrap(
                      spacing: Spacing.sm,
                      runSpacing: Spacing.sm,
                      children: [
                        for (final c in categories.active)
                          ChoiceChip(
                            key: Key('expense-category-${c.id}'),
                            avatar: Icon(
                              categoryIcon(c.icon),
                              size: 18,
                              color: categoryColor(c.colorHex),
                            ),
                            label: Text(c.name),
                            selected: state.categoryId == c.id,
                            onSelected: (_) => cubit.categorySelected(c.id),
                          ),
                      ],
                    ),
                  ),
                  if (state.error == AddExpenseError.categoryRequired)
                    Padding(
                      padding: const EdgeInsets.only(top: Spacing.sm),
                      child: Text(
                        l10n.addExpenseCategoryRequired,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ExpansionTile(
                    key: const Key('expense-more'),
                    tilePadding: EdgeInsets.zero,
                    title: Text(l10n.addExpenseMore),
                    children: [
                      ListTile(
                        key: const Key('expense-date'),
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_outlined),
                        title: Text(l10n.addExpenseDate),
                        subtitle: Text(formatDate(state.date)),
                        onTap: () async {
                          final today = DateTime.now();
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: state.date,
                            firstDate: DateTime(today.year - 1),
                            lastDate: today,
                          );
                          if (picked != null) cubit.dateChanged(picked);
                        },
                      ),
                      TextField(
                        key: const Key('expense-note'),
                        onChanged: cubit.noteChanged,
                        maxLength: 500,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: l10n.addExpenseNote,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                  if (state.status == SubmitStatus.failure)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Spacing.sm),
                      child: Text(
                        l10n.addExpenseFailed,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  SubmitButton(
                    key: const Key('expense-save'),
                    label: l10n.addExpenseSave,
                    busy: state.status == SubmitStatus.submitting,
                    onPressed: cubit.submit,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
