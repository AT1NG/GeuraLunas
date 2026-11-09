import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/features/auth/view/register_page.dart';
import 'package:geuralunas/repositories/auth_failure.dart';
import 'package:geuralunas/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/pump_app.dart';

Finder get _name => find.byKey(const Key('register-name'));
Finder get _email => find.byKey(const Key('register-email'));
Finder get _password => find.byKey(const Key('register-password'));
Finder get _submit => find.byKey(const Key('register-submit'));

void main() {
  late MockAuthRepository repo;
  setUp(() => repo = MockAuthRepository());

  Future<void> pump(WidgetTester tester) => pumpApp(
    tester,
    RepositoryProvider<AuthRepository>.value(
      value: repo,
      child: const RegisterPage(),
    ),
  );

  testWidgets('requires name, email, password >= 8', (tester) async {
    await pump(tester);

    await tester.tap(_submit);
    await tester.pump();
    expect(find.text('Wajib diisi'), findsNWidgets(3));

    await tester.enterText(_name, 'Rani');
    await tester.enterText(_email, 'rani@mail.com');
    await tester.enterText(_password, '1234567');
    await tester.tap(_submit);
    await tester.pump();
    expect(find.text('Minimal 8 karakter'), findsOneWidget);
    verifyNever(
      () => repo.signUpWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
        displayName: any(named: 'displayName'),
      ),
    );
  });

  testWidgets('EmailInUse shows message', (tester) async {
    when(
      () => repo.signUpWithEmail(
        email: any(named: 'email'),
        password: any(named: 'password'),
        displayName: any(named: 'displayName'),
      ),
    ).thenThrow(const EmailInUse());
    await pump(tester);

    await tester.enterText(_name, 'Rani');
    await tester.enterText(_email, 'rani@mail.com');
    await tester.enterText(_password, '12345678');
    await tester.tap(_submit);
    await tester.pump();

    expect(find.byKey(const Key('auth-error')), findsOneWidget);
    expect(find.textContaining('sudah terdaftar'), findsOneWidget);
  });
}
