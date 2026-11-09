import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/features/onboarding/view/onboarding_page.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('shows first slide and Lewati', (tester) async {
    await pumpApp(tester, OnboardingPage(onFinished: () {}));
    expect(find.text('Catat semua hutang di satu tempat'), findsOneWidget);
    expect(find.text('Lewati'), findsOneWidget);
    expect(find.text('Lanjut'), findsOneWidget);
  });

  testWidgets('Lanjut moves to next slide', (tester) async {
    await pumpApp(tester, OnboardingPage(onFinished: () {}));
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Jangan sampai telat bayar'), findsOneWidget);
  });

  testWidgets('Mulai on last slide calls onFinished', (tester) async {
    var finished = 0;
    await pumpApp(tester, OnboardingPage(onFinished: () => finished++));
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjut'));
    await tester.pumpAndSettle();
    expect(find.text('Mulai'), findsOneWidget);
    await tester.tap(find.text('Mulai'));
    expect(finished, 1);
  });

  testWidgets('Lewati calls onFinished', (tester) async {
    var finished = 0;
    await pumpApp(tester, OnboardingPage(onFinished: () => finished++));
    await tester.tap(find.text('Lewati'));
    expect(finished, 1);
  });

  testWidgets('renders without overflow at text scale 2.0', (tester) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: OnboardingPage(onFinished: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
