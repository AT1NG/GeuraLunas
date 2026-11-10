import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/budget/category.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/features/budget/view/add_expense_sheet.dart';
import 'package:geuralunas/repositories/category_repository.dart';
import 'package:geuralunas/repositories/expense_repository.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

void main() {
  late FakeCategoryRepository categories;
  late FakeExpenseRepository expenses;

  Future<void> open(WidgetTester tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            key: const Key('open'),
            onPressed: () => showAddExpenseSheet(context),
            child: const Text('open'),
          ),
        ),
      ),
      repositories: [
        RepositoryProvider<CategoryRepository>.value(value: categories),
        RepositoryProvider<ExpenseRepository>.value(value: expenses),
      ],
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
  }

  setUpAll(initializeFormatting);

  setUp(() {
    categories = FakeCategoryRepository();
    expenses = FakeExpenseRepository();
  });

  testWidgets('three taps record an expense, close the sheet and confirm', (
    tester,
  ) async {
    await open(tester);

    await tester.enterText(find.byKey(const Key('expense-amount')), '25000');
    await tester.tap(find.byKey(const Key('expense-category-makan')));
    await tester.tap(find.byKey(const Key('expense-save')));
    await tester.pumpAndSettle();

    expect(expenses.added, hasLength(1));
    expect(expenses.added.single.amount, const Money(25000));
    expect(expenses.added.single.categoryId, 'makan');
    expect(find.byKey(const Key('expense-save')), findsNothing);
    expect(find.text('Pengeluaran dicatat'), findsOneWidget);
  });

  testWidgets('the amount field has focus when the sheet opens', (
    tester,
  ) async {
    await open(tester);
    final field = tester.widget<TextField>(
      find.byKey(const Key('expense-amount')),
    );
    expect(field.autofocus, isTrue);
  });

  testWidgets('archived categories are not offered, the rest are', (
    tester,
  ) async {
    categories = FakeCategoryRepository(
      initial: [
        defaultCategories[0],
        defaultCategories[1].copyWith(archived: true),
        defaultCategories[2],
      ],
    );
    await open(tester);

    expect(find.byKey(const Key('expense-category-makan')), findsOneWidget);
    expect(find.byKey(const Key('expense-category-belanja')), findsOneWidget);
    expect(find.byKey(const Key('expense-category-transport')), findsNothing);
  });

  testWidgets('saving without an amount explains what is missing', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.byKey(const Key('expense-category-makan')));
    await tester.tap(find.byKey(const Key('expense-save')));
    await tester.pumpAndSettle();

    expect(find.text('Isi nominalnya dulu ya.'), findsOneWidget);
    expect(expenses.added, isEmpty);
  });

  testWidgets('saving without a category explains what is missing', (
    tester,
  ) async {
    await open(tester);

    await tester.enterText(find.byKey(const Key('expense-amount')), '5000');
    await tester.tap(find.byKey(const Key('expense-save')));
    await tester.pumpAndSettle();

    expect(find.text('Pilih kategorinya dulu ya.'), findsOneWidget);
    expect(expenses.added, isEmpty);
  });

  testWidgets('a zero amount gets a friendly message and nothing is saved', (
    tester,
  ) async {
    await open(tester);

    await tester.enterText(find.byKey(const Key('expense-amount')), '0');
    await tester.tap(find.byKey(const Key('expense-category-makan')));
    await tester.tap(find.byKey(const Key('expense-save')));
    await tester.pumpAndSettle();

    expect(
      find.text('Nominalnya belum pas. Pakai angka saja, contoh 25.000.'),
      findsOneWidget,
    );
    expect(expenses.added, isEmpty);
  });

  testWidgets('date and note sit under "Lainnya" and are sent along', (
    tester,
  ) async {
    await open(tester);
    expect(find.byKey(const Key('expense-note')), findsNothing);

    await tester.tap(find.byKey(const Key('expense-more')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('expense-note')), 'bakso');
    await tester.enterText(find.byKey(const Key('expense-amount')), '12000');
    await tester.tap(find.byKey(const Key('expense-category-makan')));
    await tester.tap(find.byKey(const Key('expense-save')));
    await tester.pumpAndSettle();

    expect(expenses.added.single.note, 'bakso');
  });
}
