import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/app/theme/app_theme.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/features/debts/view/debt_detail_page.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/debt_repository.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';
import 'package:geuralunas/shared/widgets/progress_bar.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/debt_fixtures.dart';

Future<void> _pump(
  WidgetTester tester,
  FakeDebtRepository repo, {
  String id = 'd1',
  double textScale = 1,
}) {
  final router = GoRouter(
    initialLocation: '/debts/$id',
    routes: [
      GoRoute(
        path: '/debts/:id',
        builder: (_, state) =>
            DebtDetailPage(debtId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/debts/:id/edit',
        builder: (_, state) => Text('edit-${state.pathParameters['id']}'),
      ),
      GoRoute(
        path: '/debts/:id/pay',
        builder: (_, state) => Text('pay-${state.pathParameters['id']}'),
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

Installment inst(
  int seq, {
  int amount = 300000,
  int paid = 0,
  InstallmentStatus status = InstallmentStatus.pending,
}) => Installment(
  seq: seq,
  dueDate: DateTime(2026, 12, seq),
  amount: Money(amount),
  paidAmount: Money(paid),
  status: status,
);

Payment pay(String id, int amount, DateTime at, {String? note}) =>
    Payment(id: id, amount: Money(amount), paidAt: at, note: note);

Finder key(String k) => find.byKey(Key(k));

Debt debt600of900() => makeDebt(
  name: 'Paylater A',
  kind: DebtKind.installment,
  total: 900000,
  remaining: 300000,
);

void main() {
  setUpAll(initializeFormatting);

  testWidgets('shows a progress indicator while loading', (tester) async {
    await _pump(tester, FakeDebtRepository(debts: [debt600of900()]));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('shows name, remaining amount and progress', (tester) async {
    await _pump(tester, FakeDebtRepository(debts: [debt600of900()]));
    await tester.pumpAndSettle();

    expect(find.text('Paylater A'), findsWidgets);
    expect(find.text('Rp300.000'), findsOneWidget);
    expect(find.textContaining('Rp600.000 dari Rp900.000'), findsOneWidget);
    expect(
      tester.widget<ProgressBar>(find.byType(ProgressBar)).value,
      closeTo(0.6667, 0.001),
    );
  });

  testWidgets('shows what kind of debt it is and whose it is', (tester) async {
    await _pump(tester, FakeDebtRepository(debts: [debt600of900()]));
    await tester.pumpAndSettle();

    expect(find.text('Cicilan · Aku berutang'), findsOneWidget);
  });

  testWidgets('lists installments with their status', (tester) async {
    final repo = FakeDebtRepository(
      debts: [debt600of900()],
      installments: {
        'd1': [
          inst(
            1,
            paid: 300000,
            status: InstallmentStatus.paid,
          ),
          inst(2, paid: 100000, status: InstallmentStatus.partial),
          inst(3),
        ],
      },
    );
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    expect(find.text('Cicilan 1'), findsOneWidget);
    expect(find.text('Cicilan 3'), findsOneWidget);
    String statusOf(int n) =>
        tester.widget<Text>(key('installment-$n-status')).data!;
    expect(statusOf(1), 'Lunas');
    expect(statusOf(2), 'Sebagian (Rp100.000 dari Rp300.000)');
    expect(statusOf(3), 'Belum dibayar');
    expect(find.textContaining('1 Des 2026'), findsWidgets);
  });

  testWidgets('says so when there is no schedule', (tester) async {
    await _pump(tester, FakeDebtRepository(debts: [makeDebt()]));
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada jadwal cicilan.'), findsOneWidget);
  });

  testWidgets('lists payments newest first', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = FakeDebtRepository(
      debts: [debt600of900()],
      payments: {
        'd1': [
          pay('p1', 100000, DateTime(2026, 11), note: 'pertama'),
          pay('p2', 200000, DateTime(2026, 11, 20)),
          pay('p3', 300000, DateTime(2026, 11, 10)),
        ],
      },
    );
    await _pump(tester, repo);
    await tester.pumpAndSettle();

    final order = [
      for (final id in ['p1', 'p2', 'p3'])
        tester.getTopLeft(key('payment-$id')).dy,
    ];
    // p2 (20 Nov) is first, then p3 (10 Nov), then p1 (1 Nov).
    expect(order[1] < order[2], isTrue);
    expect(order[2] < order[0], isTrue);
    expect(find.text('pertama'), findsOneWidget);
  });

  testWidgets('says so when there are no payments', (tester) async {
    await _pump(tester, FakeDebtRepository(debts: [debt600of900()]));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada pembayaran.'), findsOneWidget);
  });

  testWidgets('a receivable uses receiving wording', (tester) async {
    final lent = makeDebt(
      name: 'Budi',
      direction: DebtDirection.lent,
      kind: DebtKind.personal,
    );
    await _pump(tester, FakeDebtRepository(debts: [lent]));
    await tester.pumpAndSettle();

    expect(find.text('Pinjaman teman · Dia berutang ke aku'), findsOneWidget);
    expect(find.text('Sisa yang akan diterima'), findsOneWidget);
    expect(find.text('Riwayat penerimaan'), findsOneWidget);
    expect(find.text('Catat penerimaan'), findsOneWidget);
  });

  testWidgets('Bayar opens the payment form', (tester) async {
    await _pump(tester, FakeDebtRepository(debts: [debt600of900()]));
    await tester.pumpAndSettle();

    await tester.tap(key('detail-pay'));
    await tester.pumpAndSettle();

    expect(find.text('pay-d1'), findsOneWidget);
  });

  testWidgets('the menu opens the edit form', (tester) async {
    await _pump(tester, FakeDebtRepository(debts: [debt600of900()]));
    await tester.pumpAndSettle();

    await tester.tap(key('detail-menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ubah'));
    await tester.pumpAndSettle();

    expect(find.text('edit-d1'), findsOneWidget);
  });

  testWidgets('a settled debt hides Bayar and celebrates', (tester) async {
    final settled = makeDebt(
      status: DebtStatus.settled,
      remaining: 0,
    );
    await _pump(tester, FakeDebtRepository(debts: [settled]));
    await tester.pumpAndSettle();

    expect(key('detail-pay'), findsNothing);
    expect(key('detail-settled'), findsOneWidget);
    expect(find.textContaining('Lunas!'), findsOneWidget);
  });

  group('Tagih', () {
    Debt receivable({
      DebtStatus status = DebtStatus.active,
      int remaining = 150000,
    }) => makeDebt(
      name: 'Budi',
      direction: DebtDirection.lent,
      kind: DebtKind.personal,
      status: status,
      total: 200000,
      remaining: remaining,
      nextDue: DateTime(2099, 12, 31),
    );

    testWidgets('an active receivable can be collected', (tester) async {
      await _pump(tester, FakeDebtRepository(debts: [receivable()]));
      await tester.pumpAndSettle();

      expect(key('debt-collect'), findsOneWidget);
    });

    testWidgets('the sheet carries the remaining amount and due date', (
      tester,
    ) async {
      await _pump(tester, FakeDebtRepository(debts: [receivable()]));
      await tester.pumpAndSettle();

      await tester.ensureVisible(key('debt-collect'));
      await tester.tap(key('debt-collect'));
      await tester.pumpAndSettle();

      final text = tester
          .widget<TextField>(key('collection-message'))
          .controller!
          .text;
      expect(text, contains('Rp150.000'));
      expect(text, isNot(contains('Rp200.000')));
      expect(text, contains('31 Des 2099'));
    });

    testWidgets('a debt I owe has no Tagih', (tester) async {
      await _pump(tester, FakeDebtRepository(debts: [debt600of900()]));
      await tester.pumpAndSettle();

      expect(key('debt-collect'), findsNothing);
    });

    testWidgets('a settled receivable has no Tagih', (tester) async {
      await _pump(
        tester,
        FakeDebtRepository(
          debts: [receivable(status: DebtStatus.settled, remaining: 0)],
        ),
      );
      await tester.pumpAndSettle();

      expect(key('debt-collect'), findsNothing);
    });

    testWidgets('an archived receivable has no Tagih', (tester) async {
      await _pump(
        tester,
        FakeDebtRepository(debts: [receivable(status: DebtStatus.archived)]),
      );
      await tester.pumpAndSettle();

      expect(key('debt-collect'), findsNothing);
    });
  });

  testWidgets('a debt that does not exist shows a message', (tester) async {
    await _pump(tester, FakeDebtRepository(), id: 'nope');
    await tester.pumpAndSettle();

    expect(key('detail-not-found'), findsOneWidget);
  });

  testWidgets('semantic labels describe the progress', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, FakeDebtRepository(debts: [debt600of900()]));
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('Sudah dibayar Rp600.000 dari Rp900.000'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('no overflow at text scale 2.0 on a phone', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repo = FakeDebtRepository(
      debts: [
        makeDebt(
          name: 'Paylater dengan nama yang sangat panjang sekali',
          kind: DebtKind.installment,
          total: 900000,
          remaining: 300000,
          nextDue: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ],
      installments: {
        'd1': [
          inst(1, paid: 300000, status: InstallmentStatus.paid),
          inst(2, paid: 100000, status: InstallmentStatus.partial),
          inst(3),
        ],
      },
      payments: {
        'd1': [pay('p1', 400000, DateTime(2026, 11), note: 'transfer bank')],
      },
    );
    await _pump(tester, repo, textScale: 2);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
