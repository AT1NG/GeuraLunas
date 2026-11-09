import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/app/app.dart';
import 'package:geuralunas/l10n/l10n.dart';

import '../helpers/fakes.dart';

Widget _app({
  FakeAuthRepository? auth,
  FakeOnboardingRepository? onboarding,
}) => App(
  authRepository: auth ?? FakeAuthRepository(initialUser: testUser),
  onboardingRepository: onboarding ?? FakeOnboardingRepository(),
);

void main() {
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
}
