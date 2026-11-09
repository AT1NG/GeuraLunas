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

  testWidgets('no overflow at text scale 2.0 on a phone; submit reachable', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpApp(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: RepositoryProvider<AuthRepository>.value(
            value: MockAuthRepository(),
            child: const ForgotPasswordPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const Key('forgot-submit')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(tester.takeException(), isNull);
  });
}
