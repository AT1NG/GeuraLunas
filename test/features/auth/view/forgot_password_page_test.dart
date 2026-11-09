import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/features/auth/view/forgot_password_page.dart';
import 'package:geuralunas/repositories/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/fakes.dart';
import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('sent state shows confirmation', (tester) async {
    final repo = MockAuthRepository();
    when(() => repo.sendPasswordReset(any())).thenAnswer((_) async {});
    await pumpApp(
      tester,
      RepositoryProvider<AuthRepository>.value(
        value: repo,
        child: const ForgotPasswordPage(),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('forgot-email')),
      'rani@mail.com',
    );
    await tester.tap(find.byKey(const Key('forgot-submit')));
    await tester.pump();

    expect(find.byKey(const Key('forgot-sent')), findsOneWidget);
    verify(() => repo.sendPasswordReset('rani@mail.com')).called(1);
  });
}
