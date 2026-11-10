import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/app/router.dart';
import 'package:geuralunas/app/theme/app_theme.dart';
import 'package:geuralunas/l10n/gen/app_localizations.dart';
import 'package:geuralunas/repositories/category_repository.dart';
import 'package:geuralunas/repositories/debt_repository.dart';
import 'package:geuralunas/repositories/expense_repository.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';

import '../helpers/debt_fixtures.dart';
import '../helpers/fakes.dart';

void main() {
  setUpAll(initializeFormatting);

  testWidgets('Kelola kategori opens the screen and back returns to Budget', (
    tester,
  ) async {
    await tester.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<DebtRepository>.value(value: FakeDebtRepository()),
          RepositoryProvider<CategoryRepository>.value(
            value: FakeCategoryRepository(),
          ),
          RepositoryProvider<ExpenseRepository>.value(
            value: FakeExpenseRepository(),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: createRouter(initialLocation: '/budget'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('budget-page')), findsOneWidget);

    await tester.tap(find.byKey(const Key('manage-categories')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('categories-page')), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('budget-page')), findsOneWidget);
    expect(find.byKey(const Key('categories-page')), findsNothing);
  });
}
