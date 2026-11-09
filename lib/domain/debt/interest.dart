import 'dart:math' as math;

import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/money.dart';

/// Rounds half up to the nearest whole rupiah (values here are never negative).
int _roundHalfUp(double value) => (value + 0.5).floor();

/// Total the borrower must pay: principal + interest + admin fee.
///
/// [periods] is the number of months (`flat_monthly`, `reducing_monthly`) or
/// days (`flat_daily`); it is ignored for [InterestType.none].
/// See `docs/DATABASE.md` section 6 for the formulas.
Money calculateTotalPayable({
  required Money principal,
  required InterestType interestType,
  required double interestRate,
  required Money adminFee,
  int periods = 1,
}) {
  if (principal.rupiah <= 0) {
    throw ArgumentError.value(principal, 'principal', 'must be positive');
  }
  if (interestRate < 0) {
    throw ArgumentError.value(interestRate, 'interestRate', 'must be >= 0');
  }
  if (adminFee.isNegative) {
    throw ArgumentError.value(adminFee, 'adminFee', 'must be >= 0');
  }
  if (periods < 1) {
    throw ArgumentError.value(periods, 'periods', 'must be >= 1');
  }

  final p = principal.rupiah;
  final fee = adminFee.rupiah;
  final rate = interestRate / 100;

  switch (interestType) {
    case InterestType.none:
      return Money(p + fee);
    case InterestType.flatMonthly:
    case InterestType.flatDaily:
      final interest = _roundHalfUp(p * rate * periods);
      return Money(p + interest + fee);
    case InterestType.reducingMonthly:
      if (rate == 0) return Money(p + fee);
      final installment = _roundHalfUp(
        p * rate / (1 - math.pow(1 + rate, -periods)),
      );
      return Money(installment * periods + fee);
  }
}
