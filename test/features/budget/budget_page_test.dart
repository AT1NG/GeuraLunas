import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/app/theme/app_theme.dart';
import 'package:geuralunas/domain/budget/category.dart';
import 'package:geuralunas/domain/budget/expense.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/features/budget/view/budget_page.dart';
import 'package:geuralunas/l10n/gen/app_localizations.dart';
import 'package:geuralunas/repositories/category_repository.dart';
import 'package:geuralunas/repositories/expense_repository.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/fakes.dart';

Expense expense(
  String id, {
  String category = 'makan',
  int rupiah = 25000,
  DateTime? spent,
  String? note,
}) => Expense(
  id: id,
  amount: Money(rupiah),
  categoryId: category,
  spentAt: spent ?? DateTime.now(),
  createdAt: spent ?? DateTime.now(),
  note: note,
);

void main() {
  late FakeCategoryRepository categories;
  late FakeExpenseRepository expenses;
  late String lastLocation;

  setUpAll(initializeFormatting);

  Future<void> pump(WidgetTester tester) async {
    lastLocation = '/';
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => const BudgetPage()),
        GoRoute(
          path: '/budget/categories',
          builder: (_, _) {
            lastLocation = '/budget/categories';
            return const Scaffold(body: Text('categories-stub'));
          },
        ),
      ],
    );
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<CategoryRepository>.value(value: categories),
          RepositoryProvider<ExpenseRepository>.value(value: expenses),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    categories = FakeCategoryRepository();
    expenses = FakeExpenseRepository();
  });

  testWidgets('keeps the budget page key', (tester) async {
    await pump(tester);
    expect(find.byKey(const Key('budget-page')), findsOneWidget);
  });

  testWidgets('an empty cycle shows a friendly message', (tester) async {
    await pump(tester);
    expect(
      find.text(
        'Belum ada pengeluaran bulan ini. Catat yang pertama lewat tombol '
        'Tambah.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('rows show category, amount and note', (tester) async {
    expenses = FakeExpenseRepository(
      initial: [expense('e1', note: 'bakso', category: 'transport')],
    );
    await pump(tester);

    final row = find.byKey(const Key('expense-row-e1'));
    expect(row, findsOneWidget);
    expect(
      find.descendant(of: row, matching: find.text('Transport')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.text('bakso')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: row, matching: find.textContaining('25.000')),
      findsOneWidget,
    );
  });

  testWidgets('an archived category keeps its name on old expenses', (
    tester,
  ) async {
    categories = FakeCategoryRepository(
      initial: [
        defaultCategories[0].copyWith(archived: true),
        ...defaultCategories.skip(1),
      ],
    );
    expenses = FakeExpenseRepository(initial: [expense('e1')]);
    await pump(tester);

    expect(
      find.descendant(
        of: find.byKey(const Key('expense-row-e1')),
        matching: find.text('Makan'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('an unknown category does not break the row', (tester) async {
    expenses = FakeExpenseRepository(
      initial: [expense('e1', category: 'hilang')],
    );
    await pump(tester);
    expect(
      find.descendant(
        of: find.byKey(const Key('expense-row-e1')),
        matching: find.text('Tanpa kategori'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('deleting asks first and only deletes when confirmed', (
    tester,
  ) async {
    expenses = FakeExpenseRepository(initial: [expense('e1')]);
    await pump(tester);

    await tester.tap(find.byKey(const Key('expense-delete-e1')));
    await tester.pumpAndSettle();
    expect(find.text('Hapus pengeluaran?'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(expenses.deleted, isEmpty);

    await tester.tap(find.byKey(const Key('expense-delete-e1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(expenses.deleted, ['e1']);
    expect(find.byKey(const Key('expense-row-e1')), findsNothing);
  });

  testWidgets('"Kelola kategori" opens the category screen', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('manage-categories')));
    await tester.pumpAndSettle();
    expect(lastLocation, '/budget/categories');
    expect(find.text('categories-stub'), findsOneWidget);
  });
}
