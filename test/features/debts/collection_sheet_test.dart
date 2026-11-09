import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/features/debts/view/collection_sheet.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';

import '../../helpers/pump_app.dart';

void main() {
  setUpAll(initializeFormatting);

  Future<void> open(
    WidgetTester tester, {
    required ShareText share,
    double textScale = 1,
    String name = 'Budi',
  }) async {
    await pumpApp(
      tester,
      MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open'),
              onPressed: () => showCollectionSheet(
                context,
                name: name,
                remaining: const Money(250000),
                dueDate: DateTime(2099, 12, 31),
                share: share,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pumpAndSettle();
  }

  testWidgets('shows a ready message with the remaining amount', (
    tester,
  ) async {
    await open(tester, share: (_) async {});

    final field = tester.widget<TextField>(
      find.byKey(const Key('collection-message')),
    );
    expect(
      field.controller!.text,
      'Halo Budi, mau mengingatkan pinjaman Rp250.000 yang jatuh tempo '
      'tanggal 31 Des 2099. Kapan kira-kira bisa dibayar? Terima kasih ya.',
    );
  });

  testWidgets('shares the text as edited', (tester) async {
    final shared = <String>[];
    await open(tester, share: (text) async => shared.add(text));

    await tester.enterText(
      find.byKey(const Key('collection-message')),
      'Halo Budi, jangan lupa ya',
    );
    await tester.tap(find.byKey(const Key('collection-share')));
    await tester.pumpAndSettle();

    expect(shared, ['Halo Budi, jangan lupa ya']);
  });

  testWidgets('a long name with odd characters does not break the sheet', (
    tester,
  ) async {
    await open(tester, share: (_) async {}, name: "${'B' * 100} {x} 'Pak'");

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('collection-share')), findsOneWidget);
  });

  testWidgets('does not overflow at 2x text size', (tester) async {
    await open(tester, share: (_) async {}, textScale: 2);

    expect(tester.takeException(), isNull);
  });
}
