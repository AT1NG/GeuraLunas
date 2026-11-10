import 'package:equatable/equatable.dart';
import 'package:geuralunas/domain/budget/budget_cycle.dart';
import 'package:geuralunas/domain/budget/expense.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/debt/payments.dart';
import 'package:geuralunas/domain/money.dart';

/// Whether the month has room for spending at all.
enum AllowanceStatus {
  /// There is a limit, possibly already used up.
  ok,

  /// Installments, with the savings target, are more than the income.
  installmentsExceedIncome,
}

/// How much can be spent without putting repayments at risk.
final class SafeAllowance extends Equatable {
  /// Creates a result.
  const SafeAllowance({
    required this.status,
    required this.installmentsThisCycle,
    required this.monthlyLimit,
    required this.monthlyRemaining,
    required this.todayAllowance,
    required this.weekAllowance,
    required this.remainingDays,
  });

  final AllowanceStatus status;

  /// Unpaid installments of debts the user owes that fall due this cycle.
  final Money installmentsThisCycle;

  /// Income minus installments and the savings target; zero when negative.
  final Money monthlyLimit;

  /// What is left of [monthlyLimit] after this cycle's expenses.
  final Money monthlyRemaining;

  /// [monthlyRemaining] spread over the days left, today included.
  final Money todayAllowance;

  /// [todayAllowance] for each day left in the week (Monday to Sunday).
  final Money weekAllowance;

  /// Days left in the cycle, today included.
  final int remainingDays;

  @override
  List<Object?> get props => [
    status,
    installmentsThisCycle,
    monthlyLimit,
    monthlyRemaining,
    todayAllowance,
    weekAllowance,
    remainingDays,
  ];
}

/// Works out the safe allowance for [today] inside [cycle].
///
/// Only debts the user owes count: money owed to the user is not income until
/// it arrives. Today's allowance is taken from what is left after today's
/// spending, so it drops as the day's expenses are recorded.
SafeAllowance computeSafeAllowance({
  required BudgetCycle cycle,
  required DateTime today,
  required Money incomeTotal,
  required Money savingsTarget,
  required List<DebtState> debts,
  required List<Expense> expenses,
}) {
  var installments = 0;
  for (final state in debts) {
    if (state.debt.direction != DebtDirection.owe ||
        state.debt.status != DebtStatus.active) {
      continue;
    }
    for (final i in state.installments) {
      if (i.status == InstallmentStatus.paid || !cycle.contains(i.dueDate)) {
        continue;
      }
      installments += i.amount.rupiah - i.paidAmount.rupiah;
    }
  }

  final days = cycle.remainingDays(today);
  final limit = incomeTotal.rupiah - installments - savingsTarget.rupiah;
  if (limit < 0) {
    return SafeAllowance(
      status: AllowanceStatus.installmentsExceedIncome,
      installmentsThisCycle: Money(installments),
      monthlyLimit: Money.zero,
      monthlyRemaining: Money.zero,
      todayAllowance: Money.zero,
      weekAllowance: Money.zero,
      remainingDays: days,
    );
  }

  var spent = 0;
  for (final e in expenses) {
    if (cycle.contains(e.spentAt)) spent += e.amount.rupiah;
  }
  final remaining = limit - spent < 0 ? 0 : limit - spent;
  final todayAllowance = remaining ~/ days;

  // DateTime.weekday is 1 for Monday to 7 for Sunday.
  final daysLeftInWeek = 8 - today.weekday;
  final weekDays = daysLeftInWeek < days ? daysLeftInWeek : days;
  final week = todayAllowance * weekDays;

  return SafeAllowance(
    status: AllowanceStatus.ok,
    installmentsThisCycle: Money(installments),
    monthlyLimit: Money(limit),
    monthlyRemaining: Money(remaining),
    todayAllowance: Money(todayAllowance),
    weekAllowance: Money(week < remaining ? week : remaining),
    remainingDays: days,
  );
}
