import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/debt/debt_plan.dart';
import 'package:geuralunas/domain/money.dart';

DebtPlan plan({
  int principal = 900000,
  InterestType type = InterestType.none,
  double rate = 0,
  int adminFee = 0,
  Frequency frequency = Frequency.monthly,
  DateTime? start,
  int? tenor,
  DateTime? firstDue,
}) => planDebt(
  principal: Money(principal),
  interestType: type,
  interestRate: rate,
  adminFee: Money(adminFee),
  frequency: frequency,
  startDate: start ?? DateTime(2026, 11, 5),
  tenorCount: tenor,
  firstDueDate: firstDue,
);

void main() {
  test('tenor makes a schedule starting one period after the start date', () {
    final p = plan(tenor: 3);

    expect(p.totalPayable, const Money(900000));
    expect(p.frequency, Frequency.monthly);
    expect(p.installments.map((i) => i.dueDate), [
      DateTime(2026, 12, 5),
      DateTime(2027, 1, 5),
      DateTime(2027, 2, 5),
    ]);
    expect(p.installments.fold(0, (s, i) => s + i.amount.rupiah), 900000);
  });

  test('an explicit first due date wins', () {
    final p = plan(tenor: 2, firstDue: DateTime(2026, 11, 25));
    expect(p.installments.map((i) => i.dueDate), [
      DateTime(2026, 11, 25),
      DateTime(2026, 12, 25),
    ]);
  });

  test('weekly schedules step by 7 days', () {
    final p = plan(tenor: 2, frequency: Frequency.weekly);
    expect(p.installments.map((i) => i.dueDate), [
      DateTime(2026, 11, 12),
      DateTime(2026, 11, 19),
    ]);
  });

  test('interest goes into the total', () {
    final p = plan(
      principal: 1000000,
      type: InterestType.flatMonthly,
      rate: 3,
      tenor: 3,
    );
    expect(p.totalPayable, const Money(1090000));
  });

  test('flat daily reads tenor as days and makes a single installment', () {
    final p = plan(
      principal: 1000000,
      type: InterestType.flatDaily,
      rate: 0.4,
      tenor: 30,
      frequency: Frequency.weekly,
      start: DateTime(2026, 11),
    );

    expect(p.totalPayable, const Money(1120000));
    expect(p.frequency, Frequency.once);
    expect(p.installments.single.dueDate, DateTime(2026, 12));
    expect(p.installments.single.amount, const Money(1120000));
  });

  test('flat daily with an explicit due date uses it', () {
    final p = plan(
      type: InterestType.flatDaily,
      rate: 1,
      tenor: 10,
      firstDue: DateTime(2026, 12, 20),
    );
    expect(p.installments.single.dueDate, DateTime(2026, 12, 20));
  });

  test('without tenor or due date there is no schedule', () {
    expect(plan().installments, isEmpty);
  });

  test('a due date without tenor makes a single installment', () {
    final p = plan(firstDue: DateTime(2026, 11, 20));
    expect(p.installments.single.dueDate, DateTime(2026, 11, 20));
    expect(p.installments.single.amount, const Money(900000));
    expect(p.frequency, Frequency.monthly);
  });

  test('rejects invalid input like the total calculation does', () {
    expect(() => plan(principal: 0), throwsArgumentError);
    expect(
      () => plan(type: InterestType.flatMonthly, rate: -1),
      throwsArgumentError,
    );
  });
}
