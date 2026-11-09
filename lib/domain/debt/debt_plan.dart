import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/debt/interest.dart';
import 'package:geuralunas/domain/debt/schedule.dart';
import 'package:geuralunas/domain/money.dart';

/// Total payable and installments derived from the terms of a debt.
typedef DebtPlan = ({
  Money totalPayable,
  Frequency frequency,
  List<Installment> installments,
});

/// Works out what a debt will cost and when it is paid.
///
/// [tenorCount] is the number of installments, except for `flat_daily` where
/// it is the number of days (and the whole total falls due in one installment).
/// Without a tenor, a [firstDueDate] makes a single installment; with neither
/// there is no schedule.
///
/// Throws [ArgumentError] for terms that [calculateTotalPayable] rejects.
DebtPlan planDebt({
  required Money principal,
  required InterestType interestType,
  required double interestRate,
  required Money adminFee,
  required Frequency frequency,
  required DateTime startDate,
  int? tenorCount,
  DateTime? firstDueDate,
}) {
  final total = calculateTotalPayable(
    principal: principal,
    interestType: interestType,
    interestRate: interestRate,
    adminFee: adminFee,
    periods: tenorCount ?? 1,
  );

  if (interestType == InterestType.flatDaily) {
    return (
      totalPayable: total,
      frequency: Frequency.once,
      installments: generateSchedule(
        totalPayable: total,
        count: 1,
        frequency: Frequency.once,
        firstDueDate:
            firstDueDate ??
            DateTime(
              startDate.year,
              startDate.month,
              startDate.day + (tenorCount ?? 1),
            ),
      ),
    );
  }

  // Monthly interest is charged once per installment, so those installments
  // must be a month apart; a weekly schedule would multiply the interest.
  final monthlyInterest =
      interestType == InterestType.flatMonthly ||
      interestType == InterestType.reducingMonthly;
  final effectiveFrequency = monthlyInterest ? Frequency.monthly : frequency;

  final List<Installment> installments;
  if (tenorCount != null) {
    installments = generateSchedule(
      totalPayable: total,
      count: tenorCount,
      frequency: effectiveFrequency,
      firstDueDate:
          firstDueDate ?? addPeriods(startDate, effectiveFrequency, 1),
      periodAnchor: firstDueDate == null ? startDate : null,
    );
  } else if (firstDueDate != null) {
    installments = generateSchedule(
      totalPayable: total,
      count: 1,
      frequency: Frequency.once,
      firstDueDate: firstDueDate,
    );
  } else {
    installments = const [];
  }
  return (
    totalPayable: total,
    frequency: effectiveFrequency,
    installments: installments,
  );
}
