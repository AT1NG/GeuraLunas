import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/app/theme/app_theme.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/features/debts/view/debts_page.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/debt_repository.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/debt_fixtures.dart';

Future<void> _pump(
  WidgetTester tester,
  FakeDebtRepository repo, {
  double textScale = 1,
}) {
  final router = GoRouter(
    initialLocation: '/debts',
    routes: [
      GoRoute(path: '/debts', builder: (_, _) => const DebtsPage()),
      GoRoute(path: '/debts/new', builder: (_, _) => const Text('new-stub')),
      GoRoute(
        path: '/debts/:id',
        builder: (_, state) => Text('detail-${state.pathParameters['id']}'),
      ),
    ],
  );
  return tester.pumpWidget(
    RepositoryProvider<DebtRepository>.value(
      value: repo,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        routerConfig: router,
      ),
    ),
  );
}

void main() {
  setUpAll(initializeFormatting);

  testWidgets('shows a progress indicator before data arrives', (
    tester,
  ) async {
    await _pump(tester, FakeDebtRepository());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows an empty state with an action that opens the form', (
    tester,
  ) async {
    await _pump(tester, FakeDebtRepository());
    await tester.pumpAndSettle();

    expect(find.text('Tambah hutang pertamamu'), findsOneWidget);
    await tester.tap(find.text('Tambah hutang pertamamu'));
    await tester.pumpAndSettle();
    expect(find.text('new-stub'), findsOneWidget);
  });

  testWidgets('shows the total remaining on top of each tab', (tester) async {
    final repo = FakeDebtRepository(
      debts: [
        makeDebt(id: 'a'),
        makeDebt(id: 'b', name: 'Paylater', remaining: 500000),
        makeDebt(
          id: 'c',
          name: 'Budi',
          direction: DebtDirection.lent,
          remaining: 250000,
        ),
      ],
    );
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('Total yang harus kamu bayar'), findsOneWidget);
    expect(find.text('Rp2.000.000'), findsOneWidget);

    await tester.tap(find.text('Piutang'));
    await tester.pumpAndSettle();
    expect(find.text('Total yang akan kamu terima'), findsOneWidget);
    expect(find.text('Rp250.000'), findsWidgets);
  });

  testWidgets('an overdue debt shows the Terlambat chip with its icon', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeDebtRepository(
        debts: [
          makeDebt(nextDue: DateTime.now().subtract(const Duration(days: 5))),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Terlambat'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('a debt due in two days shows Segera jatuh tempo', (
    tester,
  ) async {
    await _pump(
      tester,
      FakeDebtRepository(
        debts: [makeDebt(nextDue: DateTime.now().add(const Duration(days: 2)))],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Segera jatuh tempo'), findsOneWidget);
  });

  testWidgets('card semantics read name, remaining amount and due date', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      FakeDebtRepository(
        debts: [
          makeDebt(nextDue: DateTime(2030, 11, 18)),
        ],
      ),
    );
    await tester.pumpAndSettle();

    final label = tester
        .getSemantics(find.byKey(const Key('debt-card-d1')))
        .label;
    expect(label, contains('Pinjol B'));
    expect(label, contains('sisa Rp1.500.000'));
    expect(label, contains('18 Nov 2030'));
    handle.dispose();
  });

  testWidgets('a debt without due date says so', (tester) async {
    await _pump(tester, FakeDebtRepository(debts: [makeDebt()]));
    await tester.pumpAndSettle();

    expect(find.text('Tanpa jatuh tempo'), findsOneWidget);
  });

  testWidgets('tapping a card opens its detail', (tester) async {
    await _pump(tester, FakeDebtRepository(debts: [makeDebt(id: 'abc')]));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('debt-card-abc')));
    await tester.pumpAndSettle();

    expect(find.text('detail-abc'), findsOneWidget);
  });

  testWidgets('the Lunas filter shows settled debts', (tester) async {
    await _pump(
      tester,
      FakeDebtRepository(
        debts: [
          makeDebt(id: 'a', name: 'Masih berjalan'),
          makeDebt(
            id: 'b',
            name: 'Sudah beres',
            status: DebtStatus.settled,
            remaining: 0,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Masih berjalan'), findsOneWidget);
    expect(find.text('Sudah beres'), findsNothing);

    await tester.tap(find.byKey(const Key('filter-settled')));
    await tester.pumpAndSettle();

    expect(find.text('Sudah beres'), findsOneWidget);
    expect(find.text('Masih berjalan'), findsNothing);
  });

  testWidgets('shows an error message when loading fails', (tester) async {
    final repo = FakeDebtRepository()..streamError = StateError('offline');
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    expect(find.textContaining('belum bisa dimuat'), findsOneWidget);
  });

  testWidgets('no overflow at text scale 2.0 on a phone', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pump(
      tester,
      FakeDebtRepository(
        debts: [
          makeDebt(
            name: 'Pinjol dengan nama yang cukup panjang sekali',
            nextDue: DateTime.now().subtract(const Duration(days: 3)),
          ),
          makeDebt(id: 'd2', name: 'Paylater'),
        ],
      ),
      textScale: 2,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
