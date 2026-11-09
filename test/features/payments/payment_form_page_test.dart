import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/app/theme/app_theme.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/features/payments/view/payment_form_page.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/debt_repository.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/debt_fixtures.dart';

Future<void> _pump(
  WidgetTester tester,
  FakeDebtRepository repo, {
  String id = 'd1',
  double textScale = 1,
}) {
  final router = GoRouter(
    initialLocation: '/debts/$id/pay',
    routes: [
      GoRoute(
        path: '/debts/:id',
        builder: (_, state) =>
            Scaffold(body: Text('detail-${state.pathParameters['id']}')),
        routes: [
          GoRoute(
            path: 'pay',
            builder: (_, state) =>
                PaymentFormPage(debtId: state.pathParameters['id']!),
          ),
        ],
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

Finder key(String k) => find.byKey(Key(k));

String textOf(WidgetTester tester, String k) =>
    tester.widget<TextField>(key(k)).controller!.text;

void phone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(360, 1200)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Installment inst(
  int seq, {
  int amount = 300000,
  int paid = 0,
  InstallmentStatus status = InstallmentStatus.pending,
}) => Installment(
  seq: seq,
  dueDate: DateTime(2026, 12, seq * 5),
  amount: Money(amount),
  paidAmount: Money(paid),
  status: status,
);

FakeDebtRepository seeded({Debt? debt, List<Installment>? installments}) =>
    FakeDebtRepository(
      debts: [
        debt ??
            makeDebt(
              name: 'Paylater A',
              kind: DebtKind.installment,
              total: 900000,
              remaining: 600000,
            ),
      ],
      installments: {
        'd1':
            installments ??
            [
              inst(1, paid: 300000, status: InstallmentStatus.paid),
              inst(2),
              inst(3),
            ],
      },
    );

void main() {
  setUpAll(initializeFormatting);

  testWidgets('prefills the amount with the nearest installment', (
    tester,
  ) async {
    phone(tester);
    await _pump(tester, seeded());
    await tester.pumpAndSettle();

    expect(textOf(tester, 'pay-amount'), '300.000');
    expect(find.text('Sisa sekarang Rp600.000'), findsOneWidget);
    expect(find.text('Aku bayar'), findsOneWidget);
  });

  testWidgets('saving records the payment, shows what is left, goes back', (
    tester,
  ) async {
    phone(tester);
    final repo = seeded();
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    await tester.enterText(key('pay-amount'), '200000');
    await tester.enterText(key('pay-note'), 'transfer');
    await tester.tap(key('pay-submit'));
    await tester.pumpAndSettle();

    final call = repo.recorded.single;
    expect(call.debtId, 'd1');
    expect(call.amount, const Money(200000));
    expect(call.installmentSeq, 2);
    expect(call.note, 'transfer');
    expect(find.text('detail-d1'), findsOneWidget);
    expect(find.text('Tercatat. Sisa sekarang Rp400.000.'), findsOneWidget);
  });

  testWidgets('paying everything shows the celebration, then goes back', (
    tester,
  ) async {
    phone(tester);
    final repo = seeded();
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    await tester.enterText(key('pay-amount'), '600000');
    await tester.tap(key('pay-submit'));
    await tester.pumpAndSettle();

    expect(key('settled-celebration'), findsOneWidget);
    expect(find.text('Lunas! Satu beban berkurang.'), findsOneWidget);

    await tester.tap(find.text('Oke'));
    await tester.pumpAndSettle();

    expect(find.text('detail-d1'), findsOneWidget);
  });

  testWidgets('over the remaining shows a message and writes nothing', (
    tester,
  ) async {
    phone(tester);
    final repo = seeded();
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    await tester.enterText(key('pay-amount'), '600001');
    await tester.tap(key('pay-submit'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Nominal melebihi sisa hutang (Rp600.000). '
        'Isi paling banyak sebesar sisa.',
      ),
      findsOneWidget,
    );
    expect(repo.recorded, isEmpty);
  });

  testWidgets('an empty amount asks for a number', (tester) async {
    phone(tester);
    final repo = seeded();
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    await tester.enterText(key('pay-amount'), '');
    await tester.tap(key('pay-submit'));
    await tester.pumpAndSettle();

    expect(find.text('Isi nominal pembayaran.'), findsOneWidget);
    expect(repo.recorded, isEmpty);
  });

  testWidgets('choosing an installment fills in its remainder', (tester) async {
    phone(tester);
    await _pump(
      tester,
      seeded(
        debt: makeDebt(
          name: 'Paylater A',
          kind: DebtKind.installment,
          total: 850000,
          remaining: 550000,
        ),
        installments: [
          inst(1, paid: 300000, status: InstallmentStatus.paid),
          inst(2),
          inst(3, amount: 250000),
        ],
      ),
    );
    await tester.pumpAndSettle();
    expect(textOf(tester, 'pay-amount'), '300.000');

    await tester.tap(key('pay-installment'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Cicilan 1 ·'), findsNothing);
    await tester.tap(find.textContaining('Cicilan 3 ·').last);
    await tester.pumpAndSettle();

    expect(textOf(tester, 'pay-amount'), '250.000');
  });

  testWidgets('a receivable uses receiving wording', (tester) async {
    phone(tester);
    final lent = makeDebt(
      name: 'Budi',
      direction: DebtDirection.lent,
      kind: DebtKind.personal,
      total: 100000,
      remaining: 100000,
    );
    await _pump(tester, seeded(debt: lent, installments: []));
    await tester.pumpAndSettle();

    expect(find.text('Catat penerimaan'), findsOneWidget);
    expect(find.text('Diterima dari Budi'), findsOneWidget);
  });

  testWidgets('a failed save keeps the form and says so', (tester) async {
    phone(tester);
    final repo = seeded()..recordError = StateError('boom');
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    await tester.tap(key('pay-submit'));
    await tester.pumpAndSettle();

    expect(key('pay-error'), findsOneWidget);
    expect(textOf(tester, 'pay-amount'), '300.000');
  });

  testWidgets('a debt that does not exist shows a message', (tester) async {
    await _pump(tester, FakeDebtRepository(), id: 'nope');
    await tester.pumpAndSettle();

    expect(key('pay-not-found'), findsOneWidget);
  });

  testWidgets('a debt that is already settled shows a message', (tester) async {
    final settled = makeDebt(status: DebtStatus.settled, remaining: 0);
    await _pump(tester, seeded(debt: settled, installments: []));
    await tester.pumpAndSettle();

    expect(key('pay-not-found'), findsOneWidget);
  });

  testWidgets('no overflow at text scale 2.0 on a phone; submit reachable', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pump(tester, seeded(), textScale: 2);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      key('pay-submit'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(tester.takeException(), isNull);
  });
}
