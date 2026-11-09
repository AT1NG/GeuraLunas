import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/domain/reminder/reminder_plan.dart';
import 'package:geuralunas/l10n/gen/app_localizations.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';
import 'package:geuralunas/shared/reminder_text.dart';

ReminderPlan planFor(int daysBefore) => ReminderPlan(
  id: 1,
  at: DateTime(2026, 12, 17, 9),
  debtId: 'd1',
  debtName: 'Paylater A',
  amount: const Money(350000),
  daysBefore: daysBefore,
);

void main() {
  setUpAll(initializeFormatting);
  final l10n = lookupAppLocalizations(const Locale('id'));

  test('title is fixed', () {
    expect(reminderTitle(l10n), 'Cicilan jatuh tempo');
  });

  test('body says today on the day', () {
    expect(
      reminderBody(planFor(0), l10n),
      'Cicilan Paylater A Rp350.000 jatuh tempo hari ini.',
    );
  });

  test('body says tomorrow one day before', () {
    expect(
      reminderBody(planFor(1), l10n),
      'Cicilan Paylater A Rp350.000 jatuh tempo besok.',
    );
  });

  test('body counts days otherwise', () {
    expect(
      reminderBody(planFor(3), l10n),
      'Cicilan Paylater A Rp350.000 jatuh tempo dalam 3 hari.',
    );
  });
}
