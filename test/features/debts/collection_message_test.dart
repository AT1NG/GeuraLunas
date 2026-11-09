import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/features/debts/collection_message.dart';
import 'package:geuralunas/l10n/gen/app_localizations.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';

void main() {
  setUpAll(initializeFormatting);
  final l10n = lookupAppLocalizations(const Locale('id'));
  final now = DateTime(2026, 11, 9, 14);

  String build({
    String name = 'Budi',
    int remaining = 100000,
    DateTime? due,
  }) => buildCollectionMessage(
    l10n: l10n,
    name: name,
    remaining: Money(remaining),
    dueDate: due,
    now: now,
  );

  test('due date not yet passed', () {
    expect(
      build(due: DateTime(2026, 11, 12)),
      'Halo Budi, mau mengingatkan pinjaman Rp100.000 yang jatuh tempo '
      'tanggal 12 Nov 2026. Kapan kira-kira bisa dibayar? Terima kasih ya.',
    );
  });

  test('due today counts as not yet passed', () {
    expect(
      build(due: DateTime(2026, 11, 9)),
      isNot(contains(' lalu.')),
    );
  });

  test('due date passed', () {
    expect(
      build(due: DateTime(2026, 11, 5)),
      'Halo Budi, mau mengingatkan pinjaman Rp100.000 yang jatuh tempo '
      'tanggal 5 Nov 2026 lalu. Kapan kira-kira bisa dibayar? Terima kasih ya.',
    );
  });

  test('no due date', () {
    expect(
      build(),
      'Halo Budi, mau mengingatkan soal pinjaman Rp100.000. '
      'Kapan kira-kira bisa dibayar? Terima kasih ya.',
    );
  });

  test('shows the remaining amount that was passed in', () {
    expect(build(remaining: 250000), contains('Rp250.000'));
  });

  test('long or odd names do not break the text', () {
    final long = 'B' * 100;
    expect(build(name: long), contains('Halo $long,'));
    final odd = build(name: "Budi {x} 'Pak' \n");
    expect(odd, contains("Halo Budi {x} 'Pak',"));
    expect(odd, isNot(contains('\n')));
  });

  test('never uses harsh words', () {
    const banned = ['bodoh', 'ancam', 'lapor', 'polisi', 'awas'];
    for (final text in [
      build(due: DateTime(2026, 11, 12)),
      build(due: DateTime(2026, 11, 5)),
      build(),
    ]) {
      for (final word in banned) {
        expect(text.toLowerCase(), isNot(contains(word)));
      }
    }
  });
}
