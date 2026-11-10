import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/app/app.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/category_repository.dart';
import 'package:geuralunas/repositories/expense_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/debt_fixtures.dart';
import '../helpers/fakes.dart';

late SharedPreferences prefs;

Widget _app({
  FakeAuthRepository? auth,
  FakeOnboardingRepository? onboarding,
}) => App(
  authRepository: auth ?? FakeAuthRepository(initialUser: testUser),
  onboardingRepository: onboarding ?? FakeOnboardingRepository(),
  userProfileRepository: FakeUserProfileRepository(),
  debtRepository: FakeDebtRepository(),
  reminderRepository: FakeReminderRepository(),
  categoryRepository: FakeCategoryRepository(),
  expenseRepository: FakeExpenseRepository(),
  prefs: prefs,
);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('App builds a MaterialApp', (tester) async {
    await tester.pumpWidget(_app());

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App uses Indonesian locale and localized title', (tester) async {
    await tester.pumpWidget(_app());

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('id'),
    );
    expect(tester.widget<Title>(find.byType(Title)).title, 'GeuraLunas');
  });

  testWidgets('context.l10n resolves Indonesian strings', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(NavigationBar));

    expect(context.l10n.navHome, 'Beranda');
  });

  testWidgets('signed-in user starts on Beranda', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-page')), findsOneWidget);
  });

  testWidgets('signed-out user who saw onboarding lands on login', (
    tester,
  ) async {
    await tester.pumpWidget(_app(auth: FakeAuthRepository()));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-page')), findsOneWidget);
  });

  testWidgets('first-time user sees onboarding, then login after finishing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        auth: FakeAuthRepository(),
        onboarding: FakeOnboardingRepository(seen: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lewati'), findsOneWidget);

    await tester.tap(find.text('Lewati'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-page')), findsOneWidget);
  });

  testWidgets('signing out returns to login', (tester) async {
    final auth = FakeAuthRepository(initialUser: testUser);
    await tester.pumpWidget(_app(auth: auth));
    await tester.pumpAndSettle();

    auth.emit(null);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-page')), findsOneWidget);
  });

  testWidgets('signing out cancels every scheduled reminder', (tester) async {
    final auth = FakeAuthRepository(initialUser: testUser);
    final reminders = FakeReminderRepository();
    await tester.pumpWidget(
      App(
        authRepository: auth,
        onboardingRepository: FakeOnboardingRepository(),
        userProfileRepository: FakeUserProfileRepository(),
        debtRepository: FakeDebtRepository(),
        reminderRepository: reminders,
        categoryRepository: FakeCategoryRepository(),
        expenseRepository: FakeExpenseRepository(),
        prefs: prefs,
      ),
    );
    await tester.pumpAndSettle();
    expect(reminders.calls, isNot(contains('cancel')));

    auth.emit(null);
    await tester.pumpAndSettle();

    expect(reminders.calls, contains('cancel'));
  });

  testWidgets('cold start shows splash, never login, until auth is known', (
    tester,
  ) async {
    final auth = FakeAuthRepository(emitOnListen: false);
    await tester.pumpWidget(_app(auth: auth));
    await tester.pump();

    expect(find.byKey(const Key('splash-page')), findsOneWidget);
    expect(find.byKey(const Key('login-page')), findsNothing);

    auth.emit(testUser);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('login-page')), findsNothing);
    expect(find.byKey(const Key('home-page')), findsOneWidget);
  });

  testWidgets('a write the server rejected is reported to the user', (
    tester,
  ) async {
    final debts = FakeDebtRepository();
    await tester.pumpWidget(
      App(
        authRepository: FakeAuthRepository(initialUser: testUser),
        onboardingRepository: FakeOnboardingRepository(),
        userProfileRepository: FakeUserProfileRepository(),
        debtRepository: debts,
        reminderRepository: FakeReminderRepository(),
        categoryRepository: FakeCategoryRepository(),
        expenseRepository: FakeExpenseRepository(),
        prefs: prefs,
      ),
    );
    await tester.pumpAndSettle();

    debts.rejectWrite(StateError('permission-denied'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Perubahan terakhir belum bisa disimpan ke server dan dibatalkan. '
        'Coba lagi ya.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('category and expense repositories are provided', (tester) async {
    final categories = FakeCategoryRepository();
    final expenses = FakeExpenseRepository();
    await tester.pumpWidget(
      App(
        authRepository: FakeAuthRepository(initialUser: testUser),
        onboardingRepository: FakeOnboardingRepository(),
        userProfileRepository: FakeUserProfileRepository(),
        debtRepository: FakeDebtRepository(),
        reminderRepository: FakeReminderRepository(),
        categoryRepository: categories,
        expenseRepository: expenses,
        prefs: prefs,
      ),
    );
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(NavigationBar));

    expect(context.read<CategoryRepository>(), same(categories));
    expect(context.read<ExpenseRepository>(), same(expenses));
  });

  for (final source in ['category', 'expense']) {
    testWidgets('a rejected $source write is reported to the user', (
      tester,
    ) async {
      final categories = FakeCategoryRepository();
      final expenses = FakeExpenseRepository();
      await tester.pumpWidget(
        App(
          authRepository: FakeAuthRepository(initialUser: testUser),
          onboardingRepository: FakeOnboardingRepository(),
          userProfileRepository: FakeUserProfileRepository(),
          debtRepository: FakeDebtRepository(),
          reminderRepository: FakeReminderRepository(),
          categoryRepository: categories,
          expenseRepository: expenses,
          prefs: prefs,
        ),
      );
      await tester.pumpAndSettle();

      final error = StateError('permission-denied');
      if (source == 'category') {
        categories.rejectWrite(error);
      } else {
        expenses.rejectWrite(error);
      }
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Perubahan terakhir belum bisa disimpan ke server dan dibatalkan. '
          'Coba lagi ya.',
        ),
        findsOneWidget,
      );
    });
  }
}
