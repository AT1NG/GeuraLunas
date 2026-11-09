import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/app/theme/app_theme.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/features/payments/view/debt_picker_sheet.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/debt_repository.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/debt_fixtures.dart';

Future<void> _open(WidgetTester tester, FakeDebtRepository repo) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, _) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showDebtPicker(context),
              child: const Text('buka'),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/debts/new',
        builder: (_, _) => const Text('new-stub'),
      ),
      GoRoute(
        path: '/debts/:id/pay',
        builder: (_, state) => Text('pay-${state.pathParameters['id']}'),
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
  await tester.tap(find.text('buka'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initializeFormatting);

  testWidgets('lists only active debts', (tester) async {
    await _open(
      tester,
      FakeDebtRepository(
        debts: [
          makeDebt(id: 'a', name: 'Aktif owe'),
          makeDebt(id: 'b', name: 'Aktif lent', direction: DebtDirection.lent),
          makeDebt(id: 'c', name: 'Sudah lunas', status: DebtStatus.settled),
          makeDebt(id: 'd', name: 'Diarsipkan', status: DebtStatus.archived),
        ],
      ),
    );

    expect(find.text('Aktif owe'), findsOneWidget);
    expect(find.text('Aktif lent'), findsOneWidget);
    expect(find.text('Sudah lunas'), findsNothing);
    expect(find.text('Diarsipkan'), findsNothing);
  });

  testWidgets('picking a debt opens its payment form', (tester) async {
    await _open(
      tester,
      FakeDebtRepository(
        debts: [makeDebt(id: 'abc')],
      ),
    );

    await tester.tap(find.byKey(const Key('picker-debt-abc')));
    await tester.pumpAndSettle();

    expect(find.text('pay-abc'), findsOneWidget);
  });

  testWidgets('with no active debt it offers to add one', (tester) async {
    await _open(tester, FakeDebtRepository());

    expect(find.text('Belum ada hutang aktif untuk dicatat.'), findsOneWidget);
    await tester.tap(find.text('Tambah hutang'));
    await tester.pumpAndSettle();

    expect(find.text('new-stub'), findsOneWidget);
  });

  testWidgets('shows the failure message when loading fails', (tester) async {
    await _open(
      tester,
      FakeDebtRepository()..streamError = StateError('offline'),
    );

    expect(find.textContaining('belum bisa dimuat'), findsOneWidget);
  });
}
