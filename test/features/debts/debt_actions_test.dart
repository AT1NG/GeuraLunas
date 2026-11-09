import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/app/theme/app_theme.dart';
import 'package:geuralunas/data/debt_data_source.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/features/debts/view/debt_detail_page.dart';
import 'package:geuralunas/features/debts/view/debts_page.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/debt_repository.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/debt_fixtures.dart';

GoRouter _router() => GoRouter(
  initialLocation: '/debts',
  routes: [
    GoRoute(
      path: '/debts',
      builder: (_, _) => const DebtsPage(),
      routes: [
        GoRoute(
          path: ':id',
          builder: (_, state) =>
              DebtDetailPage(debtId: state.pathParameters['id']!),
        ),
      ],
    ),
    GoRoute(path: '/debts/:id/edit', builder: (_, _) => const Text('edit')),
    GoRoute(path: '/debts/:id/pay', builder: (_, _) => const Text('pay')),
  ],
);

Future<void> _pump(WidgetTester tester, DebtRepository repo) {
  return tester.pumpWidget(
    RepositoryProvider<DebtRepository>.value(
      value: repo,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        locale: const Locale('id'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: _router(),
      ),
    ),
  );
}

Finder key(String k) => find.byKey(Key(k));

void phone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(360, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> openMenu(WidgetTester tester, String item) async {
  await tester.tap(key('detail-menu'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(item));
  await tester.pumpAndSettle();
}

/// Lets fake Firestore deliver its (real-async) events.
Future<void> settle(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

Future<DebtRepositoryImpl> realRepoWithDebt(WidgetTester tester) async {
  final repo = DebtRepositoryImpl(
    DebtDataSource(FakeFirebaseFirestore()),
    currentUid: () => 'u1',
    now: () => DateTime(2026, 11, 9, 10),
  );
  await tester.runAsync(() async {
    await repo.addDebt(
      NewDebt(
        direction: DebtDirection.owe,
        kind: DebtKind.installment,
        counterpartyName: 'Paylater A',
        principal: const Money(900000),
        tenorCount: 3,
        frequency: Frequency.monthly,
        startDate: DateTime(2026, 11, 5),
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 50));
  });
  return repo;
}

void main() {
  setUpAll(initializeFormatting);

  group('with a fake repository', () {
    FakeDebtRepository seeded() =>
        FakeDebtRepository(debts: [makeDebt(total: 900000, remaining: 450000)]);

    testWidgets('delete asks for confirmation; cancel does nothing', (
      tester,
    ) async {
      phone(tester);
      final repo = seeded();
      await _pump(tester, repo);
      await tester.pumpAndSettle();
      await tester.tap(key('debt-card-d1'));
      await tester.pumpAndSettle();

      await openMenu(tester, 'Hapus');
      expect(find.text('Hapus hutang?'), findsOneWidget);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(repo.deletedDebts, isEmpty);
      expect(key('debt-detail-page'), findsOneWidget);
    });

    testWidgets('confirming delete removes it and returns to the list', (
      tester,
    ) async {
      phone(tester);
      final repo = seeded();
      await _pump(tester, repo);
      await tester.pumpAndSettle();
      await tester.tap(key('debt-card-d1'));
      await tester.pumpAndSettle();

      await openMenu(tester, 'Hapus');
      await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
      await tester.pumpAndSettle();

      expect(repo.deletedDebts, ['d1']);
      expect(key('debts-page'), findsOneWidget);
      expect(key('debt-detail-page'), findsNothing);
    });

    testWidgets('archive asks for confirmation, then goes back', (
      tester,
    ) async {
      phone(tester);
      final repo = seeded();
      await _pump(tester, repo);
      await tester.pumpAndSettle();
      await tester.tap(key('debt-card-d1'));
      await tester.pumpAndSettle();

      await openMenu(tester, 'Arsipkan');
      expect(find.text('Arsipkan hutang?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Arsipkan'));
      await tester.pumpAndSettle();

      expect(repo.archived, [(debtId: 'd1', archived: true)]);
      expect(key('debts-page'), findsOneWidget);
    });

    testWidgets('mark settled asks, records the remaining amount, celebrates', (
      tester,
    ) async {
      phone(tester);
      final repo = seeded();
      await _pump(tester, repo);
      await tester.pumpAndSettle();
      await tester.tap(key('debt-card-d1'));
      await tester.pumpAndSettle();

      await openMenu(tester, 'Tandai lunas');
      expect(find.textContaining('Rp450.000'), findsWidgets);
      await tester.tap(find.widgetWithText(FilledButton, 'Tandai lunas'));
      await tester.pumpAndSettle();

      expect(repo.recorded.single.amount, const Money(450000));
      expect(repo.recorded.single.note, 'Ditandai lunas');
      expect(key('settled-celebration'), findsOneWidget);
    });

    testWidgets('a failed action says so and stays on the screen', (
      tester,
    ) async {
      phone(tester);
      final repo = seeded()..actionError = StateError('boom');
      await _pump(tester, repo);
      await tester.pumpAndSettle();
      await tester.tap(key('debt-card-d1'));
      await tester.pumpAndSettle();

      await openMenu(tester, 'Hapus');
      await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
      await tester.pumpAndSettle();

      expect(
        find.text('Belum bisa menyelesaikannya. Coba lagi sebentar lagi.'),
        findsOneWidget,
      );
      expect(key('debt-detail-page'), findsOneWidget);
    });

    testWidgets('a settled debt has no "Tandai lunas" in the menu', (
      tester,
    ) async {
      phone(tester);
      final repo = FakeDebtRepository(
        debts: [makeDebt(status: DebtStatus.settled, remaining: 0)],
      );
      await _pump(tester, repo);
      await tester.pumpAndSettle();
      await tester.tap(key('filter-settled'));
      await tester.pumpAndSettle();
      await tester.tap(key('debt-card-d1'));
      await tester.pumpAndSettle();

      await tester.tap(key('detail-menu'));
      await tester.pumpAndSettle();

      expect(find.text('Tandai lunas'), findsNothing);
      expect(find.text('Arsipkan'), findsOneWidget);
      expect(find.text('Hapus'), findsOneWidget);
    });
  });

  group('with the real repository', () {
    testWidgets('an archived debt disappears from the list', (tester) async {
      phone(tester);
      final repo = await realRepoWithDebt(tester);
      await _pump(tester, repo);
      await settle(tester);
      expect(find.text('Paylater A'), findsOneWidget);

      await tester.tap(find.text('Paylater A'));
      await tester.pumpAndSettle();
      await openMenu(tester, 'Arsipkan');
      await tester.tap(find.widgetWithText(FilledButton, 'Arsipkan'));
      await settle(tester);

      expect(key('debts-page'), findsOneWidget);
      expect(find.text('Paylater A'), findsNothing);
    });

    testWidgets('a deleted debt disappears from the list', (tester) async {
      phone(tester);
      final repo = await realRepoWithDebt(tester);
      await _pump(tester, repo);
      await settle(tester);

      await tester.tap(find.text('Paylater A'));
      await tester.pumpAndSettle();
      await openMenu(tester, 'Hapus');
      await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
      await settle(tester);

      expect(key('debts-page'), findsOneWidget);
      expect(find.text('Paylater A'), findsNothing);
      expect(
        await tester.runAsync(() => repo.watchDebts().first),
        isEmpty,
      );
    });

    testWidgets('marking settled turns the debt into Lunas', (tester) async {
      phone(tester);
      final repo = await realRepoWithDebt(tester);
      await _pump(tester, repo);
      await settle(tester);

      await tester.tap(find.text('Paylater A'));
      await tester.pumpAndSettle();
      await openMenu(tester, 'Tandai lunas');
      await tester.tap(find.widgetWithText(FilledButton, 'Tandai lunas'));
      await settle(tester);
      expect(key('settled-celebration'), findsOneWidget);
      await tester.tap(find.text('Oke'));
      await settle(tester);

      expect(key('detail-settled'), findsOneWidget);
      expect(key('detail-pay'), findsNothing);
      expect(find.text('Rp0'), findsWidgets);
    });
  });
}
