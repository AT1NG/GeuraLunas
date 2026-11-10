import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geuralunas/features/budget/view/add_expense_sheet.dart';
import 'package:geuralunas/features/payments/view/debt_picker_sheet.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:go_router/go_router.dart';

/// Shows the quick-add menu. "Tambah hutang" opens the debt form,
/// "Catat pembayaran" the debt picker and "Catat pengeluaran" the expense
/// sheet.
Future<void> showAddMenu(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      final l10n = sheetContext.l10n;
      void close() => Navigator.of(sheetContext).pop();
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.shopping_bag_outlined),
              title: Text(l10n.addMenuExpense),
              onTap: () {
                close();
                unawaited(showAddExpenseSheet(context));
              },
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: Text(l10n.addMenuPayment),
              onTap: () {
                close();
                unawaited(showDebtPicker(context));
              },
            ),
            ListTile(
              leading: const Icon(Icons.request_quote_outlined),
              title: Text(l10n.addMenuDebt),
              onTap: () {
                close();
                unawaited(context.push('/debts/new'));
              },
            ),
          ],
        ),
      );
    },
  );
}
