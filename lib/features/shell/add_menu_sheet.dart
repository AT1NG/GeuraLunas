import 'package:flutter/material.dart';
import 'package:geuralunas/l10n/l10n.dart';

/// Shows the quick-add menu. Entries are wired up in later phases; for now
/// each one just closes the sheet.
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
              onTap: close,
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: Text(l10n.addMenuPayment),
              onTap: close,
            ),
            ListTile(
              leading: const Icon(Icons.request_quote_outlined),
              title: Text(l10n.addMenuDebt),
              onTap: close,
            ),
          ],
        ),
      );
    },
  );
}
