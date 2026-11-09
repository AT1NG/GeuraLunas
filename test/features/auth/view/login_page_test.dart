import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/app/theme/app_theme.dart';
import 'package:geuralunas/features/auth/view/login_page.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/auth_failure.dart';
import 'package:geuralunas/repositories/auth_repository.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes.dart';

Future<void> _pump(
  WidgetTester tester,
  AuthRepository repo, {
  double textScale = 1,
}) {
  final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (_, _) => const Text('register-stub'),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const Text('forgot-stub'),
      ),
    ],
  );
  return tester.pumpWidget(
    RepositoryProvider<AuthRepository>.value(
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

Finder get _email => find.byKey(const Key('login-email'));
Finder get _password => find.byKey(const Key('login-password'));
Finder get _submit => find.byKey(const Key('login-submit'));

void main() {
  late MockAuthRepository repo;
  setUp(() => repo = MockAuthRepository());

  testWidgets('shows validation errors for empty fields', (tester) async {
    await _pump(tester, repo);
    await tester.tap(_submit);
    await tester.pump();

    expect(find.text('Wajib diisi'), findsNWidgets(2));
    verifyNever(
      () => repo.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('submit calls repository with trimmed lowercase email', (
    tester,
  ) async {
    when(
      () => repo.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});
    await _pump(tester, repo);

    await tester.enterText(_email, ' Rani@Mail.COM ');
    await tester.enterText(_password, 'rahasia123');
    await tester.tap(_submit);
    await tester.pump();

    verify(
      () =>
          repo.signInWithEmail(email: 'rani@mail.com', password: 'rahasia123'),
    ).called(1);
  });

  testWidgets('failure InvalidCredentials shows error message from l10n', (
    tester,
  ) async {
    when(
      () => repo.signInWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenThrow(const InvalidCredentials());
    await _pump(tester, repo);

    await tester.enterText(_email, 'rani@mail.com');
    await tester.enterText(_password, 'salahsalah');
    await tester.tap(_submit);
    await tester.pump();

    expect(find.byKey(const Key('auth-error')), findsOneWidget);
    expect(
      find.textContaining('Email atau password belum cocok'),
      findsOneWidget,
    );
  });

  testWidgets('google cancelled shows no error', (tester) async {
    when(() => repo.signInWithGoogle()).thenAnswer((_) async => false);
    await _pump(tester, repo);

    await tester.tap(find.byKey(const Key('login-google')));
    await tester.pump();

    expect(find.byKey(const Key('auth-error')), findsNothing);
  });

  testWidgets('Daftar link navigates to register', (tester) async {
    await _pump(tester, repo);
    await tester.tap(find.byKey(const Key('login-to-register')));
    await tester.pumpAndSettle();

    expect(find.text('register-stub'), findsOneWidget);
  });

  testWidgets('Lupa password link navigates', (tester) async {
    await _pump(tester, repo);
    await tester.tap(find.byKey(const Key('login-to-forgot')));
    await tester.pumpAndSettle();

    expect(find.text('forgot-stub'), findsOneWidget);
  });

  testWidgets('no overflow at text scale 2.0 and scrollable', (tester) async {
    await _pump(tester, repo, textScale: 2);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });
}
