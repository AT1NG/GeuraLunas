import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/debt/payments.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/domain/reminder/reminder_plan.dart';
import 'package:geuralunas/domain/reminder/reminder_settings.dart';

import '../../helpers/debt_fixtures.dart';

DebtState state({
  required List<Installment> installments,
  String id = 'd1',
  String name = 'Paylater A',
  DebtDirection direction = DebtDirection.owe,
  DebtStatus status = DebtStatus.active,
}) => DebtState(
  debt: makeDebt(id: id, name: name, direction: direction, status: status),
  installments: installments,
);

Installment inst(
  int seq,
  DateTime due, {
  int amount = 350000,
  int paid = 0,
  InstallmentStatus status = InstallmentStatus.pending,
}) => Installment(
  seq: seq,
  dueDate: due,
  amount: Money(amount),
  paidAmount: Money(paid),
  status: status,
);

void main() {
  const settings = ReminderSettings.defaults;

  List<ReminderPlan> plan(
    List<DebtState> debts,
    DateTime now, {
    int horizonDays = 60,
    int maxCount = 200,
  }) => planReminders(
    debts: debts,
    settings: settings,
    now: now,
    horizonDays: horizonDays,
    maxCount: maxCount,
  );

  test('plans one reminder per installment per day before at the reminder '
      'time', () {
    final plans = plan([
      state(installments: [inst(1, DateTime(2026, 12, 20))]),
    ], DateTime(2026, 12));
    expect(plans.map((p) => p.at), [
      DateTime(2026, 12, 17, 9),
      DateTime(2026, 12, 19, 9),
      DateTime(2026, 12, 20, 9),
    ]);
    expect(plans.map((p) => p.daysBefore), [3, 1, 0]);
    expect(plans.first.debtId, 'd1');
    expect(plans.first.debtName, 'Paylater A');
    expect(plans.first.amount, const Money(350000));
  });

  test('skips reminders already in the past', () {
    final plans = plan([
      state(installments: [inst(1, DateTime(2026, 12, 20))]),
    ], DateTime(2026, 12, 20, 14));
    expect(plans, isEmpty);
  });

  test('ignores lent debts, settled, archived and paid installments', () {
    final due = DateTime(2026, 12, 20);
    final plans = plan([
      state(
        id: 'lent',
        direction: DebtDirection.lent,
        installments: [inst(1, due)],
      ),
      state(
        id: 'settled',
        status: DebtStatus.settled,
        installments: [inst(1, due)],
      ),
      state(
        id: 'arch',
        status: DebtStatus.archived,
        installments: [inst(1, due)],
      ),
      state(
        id: 'paid',
        installments: [
          inst(1, due, paid: 350000, status: InstallmentStatus.paid),
        ],
      ),
    ], DateTime(2026, 12));
    expect(plans, isEmpty);
  });

  test('partial installment uses the remaining amount', () {
    final plans = plan([
      state(
        installments: [
          inst(
            1,
            DateTime(2026, 12, 20),
            amount: 400000,
            paid: 150000,
            status: InstallmentStatus.partial,
          ),
        ],
      ),
    ], DateTime(2026, 12));
    expect(plans, isNotEmpty);
    expect(plans.every((p) => p.amount == const Money(250000)), isTrue);
  });

  test('reminders near the start of a month fall into the previous month', () {
    final march = plan([
      state(installments: [inst(1, DateTime(2027, 3, 2))]),
    ], DateTime(2027, 2));
    expect(march.first.at, DateTime(2027, 2, 27, 9));
    final april = plan([
      state(installments: [inst(1, DateTime(2027, 4))]),
    ], DateTime(2027, 3, 20));
    expect(april.first.at, DateTime(2027, 3, 29, 9));
  });

  test('stops at the horizon', () {
    final now = DateTime(2026, 12);
    final far = plan([
      state(installments: [inst(1, now.add(const Duration(days: 100)))]),
    ], now);
    expect(far, isEmpty);
    final near = plan([
      state(installments: [inst(1, DateTime(2027, 1, 29))]),
    ], now);
    expect(near.map((p) => p.daysBefore), contains(0));
  });

  test('caps at maxCount, keeping the earliest', () {
    final installments = [
      for (var i = 0; i < 30; i++) inst(i + 1, DateTime(2026, 12, 1 + i)),
    ];
    final now = DateTime(2026, 11, 25);
    final plans = plan([state(installments: installments)], now, maxCount: 10);
    expect(plans, hasLength(10));
    final times = plans.map((p) => p.at).toList();
    expect([...times]..sort(), times);
    final all = plan([state(installments: installments)], now);
    expect(plans, all.take(10).toList());
  });

  test('ids are stable and unique', () {
    final a = notificationId(debtId: 'abc', seq: 3, daysBefore: 1);
    expect(notificationId(debtId: 'abc', seq: 3, daysBefore: 1), a);
    expect(notificationId(debtId: 'abc', seq: 3, daysBefore: 0), isNot(a));
    expect(notificationId(debtId: 'abc', seq: 4, daysBefore: 1), isNot(a));
    expect(notificationId(debtId: 'abd', seq: 3, daysBefore: 1), isNot(a));
    for (var seq = 1; seq <= 360; seq++) {
      for (var n = 0; n <= 7; n++) {
        final id = notificationId(debtId: 'zzz', seq: seq, daysBefore: n);
        expect(id, greaterThanOrEqualTo(0));
        expect(id, lessThan(2147483648));
      }
    }
  });
}
