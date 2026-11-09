import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/app/router.dart';
import 'package:geuralunas/app/theme/app_theme.dart';
import 'package:geuralunas/l10n/gen/app_localizations.dart';
import 'package:geuralunas/repositories/debt_repository.dart';

import '../../helpers/debt_fixtures.dart';

Future<void> _pumpRouter(WidgetTester tester) {
  return tester.pumpWidget(
    RepositoryProvider<DebtRepository>.value(
      value: FakeDebtRepository(),
      child: MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: createRouter(),
      ),
    ),
  );
}

Finder _navLabel(String label) => find.descendant(
  of: find.byType(NavigationBar),
  matching: find.text(label),
);

void main() {
  testWidgets('shows five destinations', (tester) async {
    await _pumpRouter(tester);

    expect(find.byType(NavigationDestination), findsNWidgets(5));
    for (final label in ['Beranda', 'Hutang', 'Tambah', 'Budget', 'Lainnya']) {
      expect(_navLabel(label), findsOneWidget);
    }
  });

  testWidgets('starts on the home page', (tester) async {
    await _pumpRouter(tester);

    expect(find.byKey(const Key('home-page')), findsOneWidget);
  });

  testWidgets('tapping Hutang shows debts page', (tester) async {
    await _pumpRouter(tester);

    await tester.tap(_navLabel('Hutang'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('debts-page')), findsOneWidget);
  });

  testWidgets('tapping Budget and Lainnya shows their pages', (tester) async {
    await _pumpRouter(tester);

    await tester.tap(_navLabel('Budget'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('budget-page')), findsOneWidget);

    await tester.tap(_navLabel('Lainnya'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('more-page')), findsOneWidget);
  });

  testWidgets('tapping add opens the three-item menu', (tester) async {
    await _pumpRouter(tester);

    await tester.tap(_navLabel('Tambah'));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNWidgets(3));
    expect(find.text('Catat pengeluaran'), findsOneWidget);
    expect(find.text('Catat pembayaran'), findsOneWidget);
    expect(find.text('Tambah hutang'), findsOneWidget);
  });

  testWidgets('selected tab is kept when add sheet closes', (tester) async {
    await _pumpRouter(tester);
    await tester.tap(_navLabel('Hutang'));
    await tester.pumpAndSettle();

    await tester.tap(_navLabel('Tambah'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Catat pengeluaran'));
    await tester.pumpAndSettle();

    expect(find.byType(ListTile), findsNothing);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(find.byKey(const Key('debts-page')), findsOneWidget);
  });

  testWidgets('Tambah hutang in the menu opens the debt form', (tester) async {
    await _pumpRouter(tester);

    await tester.tap(_navLabel('Tambah'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah hutang'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('debt-form-page')), findsOneWidget);
  });
}
