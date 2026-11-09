import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/app/app.dart';
import 'package:geuralunas/l10n/l10n.dart';

void main() {
  testWidgets('App builds a MaterialApp', (tester) async {
    await tester.pumpWidget(const App());

    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App uses Indonesian locale and localized title', (tester) async {
    await tester.pumpWidget(const App());

    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).locale,
      const Locale('id'),
    );
    expect(tester.widget<Title>(find.byType(Title)).title, 'GeuraLunas');
  });

  testWidgets('context.l10n resolves Indonesian strings', (tester) async {
    late String home;
    await tester.pumpWidget(const App());
    final context = tester.element(find.byType(NavigationBar));
    home = context.l10n.navHome;

    expect(home, 'Beranda');
  });
}
