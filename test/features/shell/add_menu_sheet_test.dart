import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/features/shell/add_menu_sheet.dart';
import 'package:geuralunas/repositories/category_repository.dart';
import 'package:geuralunas/repositories/expense_repository.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  setUpAll(initializeFormatting);

  testWidgets('"Catat pengeluaran" opens the expense sheet', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            key: const Key('open-menu'),
            onPressed: () => showAddMenu(context),
            child: const Text('menu'),
          ),
        ),
      ),
      repositories: [
        RepositoryProvider<CategoryRepository>.value(
          value: FakeCategoryRepository(),
        ),
        RepositoryProvider<ExpenseRepository>.value(
          value: FakeExpenseRepository(),
        ),
      ],
    );
    await tester.tap(find.byKey(const Key('open-menu')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Catat pengeluaran'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('expense-save')), findsOneWidget);
    expect(find.byKey(const Key('expense-amount')), findsOneWidget);
  });
}
