import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/app/theme/app_theme.dart';
import 'package:geuralunas/data/debt_data_source.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/features/debts/view/debt_detail_page.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/debt_repository.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/debt_fixtures.dart';

Future<void> _pump(WidgetTester tester, DebtRepository repo) {
  final router = GoRouter(
    initialLocation: '/debts/d1',
    routes: [
      GoRoute(
        path: '/debts/:id',
        builder: (_, state) =>
            DebtDetailPage(debtId: state.pathParameters['id']!),
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
        routerConfig: router,
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

FakeDebtRepository withOnePayment() => FakeDebtRepository(
  debts: [makeDebt(total: 900000, remaining: 600000)],
  payments: {
    'd1': [
      Payment(
        id: 'p1',
        amount: const Money(300000),
        paidAt: DateTime(2026, 11, 20),
      ),
    ],
  },
);

void main() {
  setUpAll(initializeFormatting);

  testWidgets('deleting asks first; cancelling does nothing', (tester) async {
    phone(tester);
    final repo = withOnePayment();
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(key('payment-delete-p1'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus pembayaran?'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(repo.deleted, isEmpty);
  });

  testWidgets('confirming deletes that payment', (tester) async {
    phone(tester);
    final repo = withOnePayment();
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(key('payment-delete-p1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(repo.deleted, [(debtId: 'd1', paymentId: 'p1')]);
  });

  testWidgets('a failed delete says so', (tester) async {
    phone(tester);
    final repo = withOnePayment()..deleteError = StateError('boom');
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(key('payment-delete-p1'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(
      find.text('Pembayaran belum bisa dihapus. Coba lagi sebentar lagi.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'deleting the only payment of a settled debt reactivates it',
    (tester) async {
      phone(tester);
      final fake = FakeFirebaseFirestore();
      final repo = DebtRepositoryImpl(
        DebtDataSource(fake),
        currentUid: () => 'u1',
        now: () => DateTime(2026, 11, 9, 10),
      );

      late String id;
      await tester.runAsync(() async {
        id = await repo.addDebt(
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
        await repo.recordPayment(
          debtId: id,
          amount: const Money(900000),
          paidAt: DateTime(2026, 11, 9),
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      // The page asks for 'd1'; use the generated id instead.
      final router = GoRouter(
        initialLocation: '/debts/$id',
        routes: [
          GoRoute(
            path: '/debts/:id',
            builder: (_, state) =>
                DebtDetailPage(debtId: state.pathParameters['id']!),
          ),
        ],
      );
      await tester.pumpWidget(
        RepositoryProvider<DebtRepository>.value(
          value: repo,
          child: MaterialApp.router(
            theme: AppTheme.light(),
            locale: const Locale('id'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();

      expect(key('detail-settled'), findsOneWidget);
      expect(key('detail-pay'), findsNothing);

      final paymentId = (await tester.runAsync(
        () => repo.watchPayments(id).first,
      ))!.single.id;
      await tester.tap(key('payment-delete-$paymentId'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus'));
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();

      expect(key('detail-settled'), findsNothing);
      expect(key('detail-pay'), findsOneWidget);
      expect(find.text('Rp900.000'), findsWidgets);
    },
  );
}
