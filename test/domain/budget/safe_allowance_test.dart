import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/budget/budget_cycle.dart';
import 'package:geuralunas/domain/budget/expense.dart';
import 'package:geuralunas/domain/budget/safe_allowance.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/debt/payments.dart';
import 'package:geuralunas/domain/money.dart';

import '../../helpers/debt_fixtures.dart';

final cycle = BudgetCycle.of(DateTime(2026, 11, 10), startDay: 1);

Expense spend(int rupiah, DateTime at, {String id = 'e'}) => Expense(
  id: id,
  amount: Money(rupiah),
  categoryId: 'makan',
  spentAt: at,
  createdAt: at,
);

Installment inst(
  DateTime due,
  int amount, {
  int paid = 0,
  InstallmentStatus status = InstallmentStatus.pending,
}) => Installment(
  seq: 1,
  dueDate: due,
  amount: Money(amount),
  paidAmount: Money(paid),
  status: status,
);

DebtState state(
  List<Installment> installments, {
  DebtDirection direction = DebtDirection.owe,
  DebtStatus status = DebtStatus.active,
}) => DebtState(
  debt: makeDebt(direction: direction, status: status),
  installments: installments,
);

SafeAllowance compute({
  DateTime? today,
  int income = 5000000,
  int savings = 0,
  List<DebtState> debts = const [],
  List<Expense> expenses = const [],
}) => computeSafeAllowance(
  cycle: cycle,
  today: today ?? DateTime(2026, 11, 10),
  incomeTotal: Money(income),
  savingsTarget: Money(savings),
  debts: debts,
  expenses: expenses,
);

void main() {
  test('worked example from the spec numbers', () {
    final result = compute(
      savings: 300000,
      debts: [
        state([inst(DateTime(2026, 11, 20), 200000)]),
      ],
      expenses: [spend(600000, DateTime(2026, 11, 5))],
    );
    expect(result.status, AllowanceStatus.ok);
    expect(result.installmentsThisCycle, const Money(200000));
    expect(result.monthlyLimit, const Money(4500000));
    expect(result.monthlyRemaining, const Money(3900000));
    expect(result.remainingDays, 21);
    expect(result.todayAllowance, const Money(185714));
    // Tuesday: six days left in the week (Tue to Sun).
    expect(result.weekAllowance, const Money(1114284));
  });

  group('installments', () {
    test('a partly paid installment counts what is left', () {
      final result = compute(
        debts: [
          state([inst(DateTime(2026, 11, 20), 200000, paid: 50000)]),
        ],
      );
      expect(result.installmentsThisCycle, const Money(150000));
    });

    test('a paid installment does not count', () {
      final result = compute(
        debts: [
          state([
            inst(
              DateTime(2026, 11, 20),
              200000,
              paid: 200000,
              status: InstallmentStatus.paid,
            ),
          ]),
        ],
      );
      expect(result.installmentsThisCycle, Money.zero);
    });

    test('an installment due in another cycle does not count', () {
      final result = compute(
        debts: [
          state([
            inst(DateTime(2026, 12), 200000),
            inst(DateTime(2026, 10, 31), 100000),
          ]),
        ],
      );
      expect(result.installmentsThisCycle, Money.zero);
    });

    test('debts owed to the user are ignored', () {
      final result = compute(
        debts: [
          state([
            inst(DateTime(2026, 11, 20), 200000),
          ], direction: DebtDirection.lent),
        ],
      );
      expect(result.installmentsThisCycle, Money.zero);
    });

    test('settled and archived debts are ignored', () {
      final result = compute(
        debts: [
          state([
            inst(DateTime(2026, 11, 20), 200000),
          ], status: DebtStatus.settled),
          state([
            inst(DateTime(2026, 11, 21), 100000),
          ], status: DebtStatus.archived),
        ],
      );
      expect(result.installmentsThisCycle, Money.zero);
    });

    test('installments of several debts add up', () {
      final result = compute(
        debts: [
          state([inst(DateTime(2026, 11, 20), 200000)]),
          state([inst(DateTime(2026, 11, 25), 300000)]),
        ],
      );
      expect(result.installmentsThisCycle, const Money(500000));
    });

    test('installments above income give a status and no negative numbers', () {
      final result = compute(
        income: 200000,
        debts: [
          state([inst(DateTime(2026, 11, 20), 300000)]),
        ],
      );
      expect(result.status, AllowanceStatus.installmentsExceedIncome);
      expect(result.monthlyLimit, Money.zero);
      expect(result.monthlyRemaining, Money.zero);
      expect(result.todayAllowance, Money.zero);
      expect(result.weekAllowance, Money.zero);
    });
  });

  group('expenses', () {
    test('spending above what is left gives zero, not a negative', () {
      final result = compute(
        income: 1000000,
        expenses: [spend(1200000, DateTime(2026, 11, 3))],
      );
      expect(result.status, AllowanceStatus.ok);
      expect(result.monthlyRemaining, Money.zero);
      expect(result.todayAllowance, Money.zero);
    });

    test('expenses outside the cycle are ignored', () {
      final result = compute(
        income: 1000000,
        expenses: [
          spend(100000, DateTime(2026, 10, 31, 23, 59), id: 'a'),
          spend(100000, DateTime(2026, 12), id: 'b'),
        ],
      );
      expect(result.monthlyRemaining, const Money(1000000));
    });

    test('the last minute of the cycle counts, midnight after does not', () {
      final result = compute(
        income: 1000000,
        expenses: [
          spend(100000, DateTime(2026, 11, 30, 23, 59), id: 'a'),
          spend(50000, DateTime(2026, 12), id: 'b'),
        ],
      );
      expect(result.monthlyRemaining, const Money(900000));
    });

    test('spending today lowers today allowance', () {
      final before = compute(income: 2100000);
      final after = compute(
        income: 2100000,
        expenses: [spend(100000, DateTime(2026, 11, 10, 12))],
      );
      expect(before.todayAllowance, const Money(100000));
      expect(after.todayAllowance, const Money(95238));
    });

    test('the savings target is taken from the limit', () {
      final result = compute(income: 1000000, savings: 400000);
      expect(result.monthlyLimit, const Money(600000));
    });
  });

  group('rounding and days', () {
    test('today allowance rounds down', () {
      final result = compute(income: 1000000);
      expect(result.todayAllowance, const Money(47619));
    });

    test('on a Sunday only one day is left in the week', () {
      final result = compute(
        today: DateTime(2026, 11, 15),
        income: 1000000,
      );
      expect(result.remainingDays, 16);
      expect(result.weekAllowance, result.todayAllowance);
    });

    test('on a Monday seven days are left in the week', () {
      final result = compute(
        today: DateTime(2026, 11, 16),
        income: 1000000,
      );
      expect(result.remainingDays, 15);
      expect(
        result.weekAllowance,
        Money(result.todayAllowance.rupiah * 7),
      );
    });

    test('the week allowance never exceeds what is left in the month', () {
      final result = compute(
        today: DateTime(2026, 11, 16),
        income: 100,
        expenses: [spend(1, DateTime(2026, 11, 2))],
      );
      expect(result.monthlyRemaining, const Money(99));
      expect(result.weekAllowance.rupiah, lessThanOrEqualTo(99));
    });

    test('on the last day the week allowance equals today allowance', () {
      final result = compute(
        today: DateTime(2026, 11, 30),
        income: 1000000,
      );
      expect(result.remainingDays, 1);
      expect(result.todayAllowance, const Money(1000000));
      expect(result.weekAllowance, const Money(1000000));
    });

    test('the week is cut at the end of the cycle', () {
      // Monday 23 Nov: 8 days left, but a cycle ending on Wed 25 Nov has 3.
      final shortCycle = BudgetCycle.of(DateTime(2026, 11, 23), startDay: 26);
      final result = computeSafeAllowance(
        cycle: shortCycle,
        today: DateTime(2026, 11, 23),
        incomeTotal: const Money(300000),
        savingsTarget: Money.zero,
        debts: const [],
        expenses: const [],
      );
      expect(result.remainingDays, 3);
      expect(result.todayAllowance, const Money(100000));
      expect(result.weekAllowance, const Money(300000));
    });
  });
}
