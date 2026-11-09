import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/features/auth/view/splash_page.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('shows progress indicator', (tester) async {
    await pumpApp(tester, const SplashPage());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
