import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';
import 'package:geuralunas/shared/widgets/confirm_dialog.dart';
import 'package:geuralunas/shared/widgets/empty_state.dart';
import 'package:geuralunas/shared/widgets/money_text.dart';
import 'package:geuralunas/shared/widgets/progress_bar.dart';
import 'package:geuralunas/shared/widgets/status_chip.dart';

import '../../helpers/pump_app.dart';

void main() {
  setUpAll(initializeFormatting);

  group('MoneyText', () {
    testWidgets('formats rupiah', (tester) async {
      await pumpApp(tester, const MoneyText(Money(1250000)));
      expect(find.text('Rp1.250.000'), findsOneWidget);
    });

    testWidgets('formats negative amounts', (tester) async {
      await pumpApp(tester, const MoneyText(Money(-1000)));
      expect(find.text('-Rp1.000'), findsOneWidget);
    });
  });

  group('StatusChip', () {
    const expected = {
      DebtStatusKind.overdue: ('Terlambat', Icons.warning_amber_rounded),
      DebtStatusKind.dueSoon: ('Segera jatuh tempo', Icons.schedule),
      DebtStatusKind.settled: ('Lunas', Icons.check_circle_outline),
      DebtStatusKind.active: ('Aktif', Icons.circle_outlined),
    };

    for (final entry in expected.entries) {
      testWidgets('${entry.key.name} shows a label and an icon', (
        tester,
      ) async {
        await pumpApp(tester, Material(child: StatusChip(entry.key)));
        expect(find.text(entry.value.$1), findsOneWidget);
        expect(find.byIcon(entry.value.$2), findsOneWidget);
      });
    }
  });

  group('ProgressBar', () {
    Future<double?> valueFor(WidgetTester tester, double value) async {
      await pumpApp(tester, ProgressBar(value: value));
      return tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value;
    }

    testWidgets('shows the value', (tester) async {
      expect(await valueFor(tester, 0.5), 0.5);
    });

    testWidgets('clamps below 0 and above 1', (tester) async {
      expect(await valueFor(tester, -0.3), 0);
      expect(await valueFor(tester, 1.7), 1);
    });
  });

  group('EmptyState', () {
    testWidgets('shows the message and runs the action', (tester) async {
      var taps = 0;
      await pumpApp(
        tester,
        EmptyState(
          icon: Icons.inbox_outlined,
          message: 'Belum ada apa-apa',
          actionLabel: 'Tambah',
          onAction: () => taps++,
        ),
      );

      expect(find.text('Belum ada apa-apa'), findsOneWidget);
      await tester.tap(find.text('Tambah'));
      expect(taps, 1);
    });

    testWidgets('without an action shows no button', (tester) async {
      await pumpApp(
        tester,
        const EmptyState(icon: Icons.inbox_outlined, message: 'Kosong'),
      );
      expect(find.byType(FilledButton), findsNothing);
    });
  });

  group('ConfirmDialog', () {
    Future<bool?> open(WidgetTester tester, Future<void> Function() act) async {
      bool? result;
      await pumpApp(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await ConfirmDialog.show(
              context,
              title: 'Hapus hutang?',
              body: 'Tidak bisa dikembalikan.',
              confirmLabel: 'Hapus',
            ),
            child: const Text('buka'),
          ),
        ),
      );
      await tester.tap(find.text('buka'));
      await tester.pumpAndSettle();
      expect(find.text('Hapus hutang?'), findsOneWidget);
      expect(find.text('Tidak bisa dikembalikan.'), findsOneWidget);
      await act();
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('confirm returns true', (tester) async {
      expect(await open(tester, () => tester.tap(find.text('Hapus'))), isTrue);
    });

    testWidgets('cancel returns false', (tester) async {
      expect(await open(tester, () => tester.tap(find.text('Batal'))), isFalse);
    });

    testWidgets('dismissing returns false', (tester) async {
      expect(
        await open(tester, () => tester.tapAt(const Offset(5, 5))),
        isFalse,
      );
    });
  });
}
