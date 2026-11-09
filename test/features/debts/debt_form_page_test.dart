import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/app/theme/app_theme.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/features/debts/view/debt_form_page.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/debt_repository.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/debt_fixtures.dart';

Future<void> _pump(
  WidgetTester tester,
  FakeDebtRepository repo, {
  String location = '/debts/new',
  double textScale = 1,
}) {
  final router = GoRouter(
    initialLocation: location,
    routes: [
      GoRoute(path: '/debts', builder: (_, _) => const Text('list-stub')),
      GoRoute(path: '/debts/new', builder: (_, _) => const DebtFormPage()),
      GoRoute(
        path: '/debts/:id/edit',
        builder: (_, state) => DebtFormPage(debtId: state.pathParameters['id']),
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

Future<void> scrollTo(WidgetTester tester, String k) async {
  await tester.ensureVisible(key(k));
  await tester.pumpAndSettle();
}

Future<void> enter(WidgetTester tester, String k, String text) async {
  await scrollTo(tester, k);
  await tester.enterText(key(k), text);
  await tester.pump();
}

void phone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(360, 1200)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  setUpAll(initializeFormatting);

  testWidgets('shows field errors on an empty submit', (tester) async {
    phone(tester);
    final repo = FakeDebtRepository();
    await _pump(tester, repo);

    await scrollTo(tester, 'form-submit');
    await tester.tap(key('form-submit'));
    await tester.pumpAndSettle();

    expect(find.text('Wajib diisi'), findsWidgets);
    expect(repo.added, isNull);
  });

  testWidgets('typing 1500000 shows 1.500.000', (tester) async {
    phone(tester);
    await _pump(tester, FakeDebtRepository());

    await enter(tester, 'form-principal', '1500000');

    expect(textOf(tester, 'form-principal'), '1.500.000');
  });

  testWidgets('pasting letters and symbols keeps only the digits', (
    tester,
  ) async {
    phone(tester);
    await _pump(tester, FakeDebtRepository());

    await enter(tester, 'form-principal', 'Rp 2.000abc');

    expect(textOf(tester, 'form-principal'), '2.000');
  });

  testWidgets('a personal debt hides interest and tenor fields', (
    tester,
  ) async {
    phone(tester);
    await _pump(tester, FakeDebtRepository());

    await scrollTo(tester, 'form-tenor');
    expect(key('form-tenor'), findsOneWidget);
    expect(key('interest-none'), findsOneWidget);

    await scrollTo(tester, 'kind-personal');
    await tester.tap(key('kind-personal'));
    await tester.pumpAndSettle();

    expect(key('form-tenor'), findsNothing);
    expect(key('form-rate'), findsNothing);
    expect(key('interest-none'), findsNothing);
    expect(key('form-admin-fee'), findsNothing);
  });

  testWidgets('choosing an interest type reveals the rate field', (
    tester,
  ) async {
    phone(tester);
    await _pump(tester, FakeDebtRepository());
    expect(key('form-rate'), findsNothing);

    await scrollTo(tester, 'interest-flat_monthly');
    await tester.tap(key('interest-flat_monthly'));
    await tester.pumpAndSettle();

    expect(key('form-rate'), findsOneWidget);
  });

  testWidgets('the preview updates when the tenor changes', (tester) async {
    phone(tester);
    await _pump(tester, FakeDebtRepository());

    await scrollTo(tester, 'kind-installment');
    await tester.tap(key('kind-installment'));
    await tester.pumpAndSettle();
    await enter(tester, 'form-principal', '900000');
    await enter(tester, 'form-tenor', '3');

    await scrollTo(tester, 'preview-total');
    expect(
      tester.widget<Text>(key('preview-total')).data,
      contains('Rp900.000'),
    );
    expect(key('preview-row-3'), findsOneWidget);

    await enter(tester, 'form-tenor', '2');
    await scrollTo(tester, 'preview-row-2');

    expect(key('preview-row-3'), findsNothing);
    expect(
      find.descendant(
        of: key('preview-row-2'),
        matching: find.textContaining('Rp450.000'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('picking a first due date shows it, and it can be cleared', (
    tester,
  ) async {
    phone(tester);
    await _pump(tester, FakeDebtRepository());
    await scrollTo(tester, 'form-first-due');
    expect(
      find.descendant(
        of: key('form-first-due'),
        matching: find.text('Otomatis'),
      ),
      findsOneWidget,
    );

    await tester.tap(key('form-first-due'));
    await tester.pumpAndSettle();
    final ok = MaterialLocalizations.of(
      tester.element(find.byType(Dialog)),
    ).okButtonLabel;
    await tester.tap(find.text(ok));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: key('form-first-due'),
        matching: find.text('Otomatis'),
      ),
      findsNothing,
    );

    await tester.tap(find.byTooltip('Hapus tanggal'));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: key('form-first-due'),
        matching: find.text('Otomatis'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('picking a start date updates it', (tester) async {
    phone(tester);
    await _pump(tester, FakeDebtRepository());
    await scrollTo(tester, 'form-start-date');
    final before =
        tester.widget<ListTile>(key('form-start-date')).subtitle! as Text;

    await tester.tap(key('form-start-date'));
    await tester.pumpAndSettle();
    final dialog = find.byType(Dialog);
    final ok = MaterialLocalizations.of(tester.element(dialog)).okButtonLabel;
    await tester.tap(find.text(ok));
    await tester.pumpAndSettle();

    final after =
        tester.widget<ListTile>(key('form-start-date')).subtitle! as Text;
    expect(after.data, before.data);
  });

  testWidgets('saving calls addDebt and goes back to the list', (tester) async {
    phone(tester);
    final repo = FakeDebtRepository();
    await _pump(tester, repo);

    await enter(tester, 'form-name', '  Pinjol B  ');
    await enter(tester, 'form-principal', '1500000');
    await scrollTo(tester, 'form-submit');
    await tester.tap(key('form-submit'));
    await tester.pumpAndSettle();

    final added = repo.added!;
    expect(added.counterpartyName, 'Pinjol B');
    expect(added.principal, const Money(1500000));
    expect(added.direction, DebtDirection.owe);
    expect(find.text('list-stub'), findsOneWidget);
  });

  testWidgets('a failed save shows a message and keeps the form', (
    tester,
  ) async {
    phone(tester);
    final repo = FakeDebtRepository()..addError = StateError('boom');
    await _pump(tester, repo);

    await enter(tester, 'form-name', 'Pinjol B');
    await enter(tester, 'form-principal', '1500000');
    await scrollTo(tester, 'form-submit');
    await tester.tap(key('form-submit'));
    await tester.pumpAndSettle();

    expect(key('form-error'), findsOneWidget);
    expect(textOf(tester, 'form-name'), 'Pinjol B');
  });

  testWidgets('editing prefills the form and warns about payments', (
    tester,
  ) async {
    phone(tester);
    final debt = makeDebt(
      name: 'Paylater A',
      kind: DebtKind.installment,
      total: 900000,
      remaining: 300000,
    ).copyWith(tenorCount: 3);
    await _pump(
      tester,
      FakeDebtRepository(debts: [debt]),
      location: '/debts/d1/edit',
    );
    await tester.pumpAndSettle();

    expect(textOf(tester, 'form-name'), 'Paylater A');
    expect(textOf(tester, 'form-principal'), '900.000');
    expect(textOf(tester, 'form-tenor'), '3');
    expect(key('form-paid-warning'), findsOneWidget);
  });

  testWidgets('editing a debt that does not exist shows a message', (
    tester,
  ) async {
    await _pump(tester, FakeDebtRepository(), location: '/debts/nope/edit');
    await tester.pumpAndSettle();

    expect(key('form-not-found'), findsOneWidget);
  });

  testWidgets('no overflow at text scale 2.0 on a phone; submit reachable', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await _pump(tester, FakeDebtRepository(), textScale: 2);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      key('form-submit'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(tester.takeException(), isNull);
  });
}
