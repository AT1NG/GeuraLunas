import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/debt/interest.dart';
import 'package:geuralunas/domain/money.dart';

Money total({
  required int principal,
  InterestType type = InterestType.none,
  double rate = 0,
  int adminFee = 0,
  int periods = 1,
}) => calculateTotalPayable(
  principal: Money(principal),
  interestType: type,
  interestRate: rate,
  adminFee: Money(adminFee),
  periods: periods,
);

void main() {
  group('none', () {
    test('is principal plus admin fee', () {
      expect(total(principal: 1000000, adminFee: 25000), const Money(1025000));
    });

    test('ignores rate and periods', () {
      expect(
        total(principal: 1000000, rate: 5, periods: 12),
        const Money(1000000),
      );
    });
  });

  group('flat_monthly', () {
    test('1.000.000 at 3% for 3 months has interest 90.000', () {
      expect(
        total(
          principal: 1000000,
          type: InterestType.flatMonthly,
          rate: 3,
          periods: 3,
        ),
        const Money(1090000),
      );
    });

    test('adds admin fee once', () {
      expect(
        total(
          principal: 1000000,
          type: InterestType.flatMonthly,
          rate: 3,
          periods: 3,
          adminFee: 10000,
        ),
        const Money(1100000),
      );
    });
  });

  group('flat_daily', () {
    test('1.000.000 at 0,4% for 30 days has interest 120.000', () {
      expect(
        total(
          principal: 1000000,
          type: InterestType.flatDaily,
          rate: 0.4,
          periods: 30,
        ),
        const Money(1120000),
      );
    });
  });

  group('reducing_monthly (annuity)', () {
    // Reference values computed in a spreadsheet:
    // A = P*r / (1 - (1+r)^-n), rounded to the nearest rupiah, total = A*n.
    test('12.000.000 at 2% for 12 months: A = 1.134.715', () {
      expect(
        total(
          principal: 12000000,
          type: InterestType.reducingMonthly,
          rate: 2,
          periods: 12,
        ),
        const Money(13616580),
      );
    });

    test('5.000.000 at 1,5% for 6 months: A = 877.626', () {
      expect(
        total(
          principal: 5000000,
          type: InterestType.reducingMonthly,
          rate: 1.5,
          periods: 6,
        ),
        const Money(5265756),
      );
    });

    test('2.500.000 at 3% for 3 months: A = 883.826', () {
      expect(
        total(
          principal: 2500000,
          type: InterestType.reducingMonthly,
          rate: 3,
          periods: 3,
        ),
        const Money(2651478),
      );
    });

    test('adds admin fee on top of A*n', () {
      expect(
        total(
          principal: 12000000,
          type: InterestType.reducingMonthly,
          rate: 2,
          periods: 12,
          adminFee: 50000,
        ),
        const Money(13666580),
      );
    });

    test('zero rate does not divide by zero', () {
      expect(
        total(
          principal: 1000000,
          type: InterestType.reducingMonthly,
          periods: 4,
          adminFee: 5000,
        ),
        const Money(1005000),
      );
    });

    test('single period works', () {
      expect(
        total(
          principal: 1000000,
          type: InterestType.reducingMonthly,
          rate: 2,
        ),
        const Money(1020000),
      );
    });
  });

  group('rounding and size', () {
    test('rounds half up', () {
      // 250 * 5% * 1 = 12.5 -> 13
      expect(
        total(principal: 250, type: InterestType.flatMonthly, rate: 5),
        const Money(263),
      );
    });

    test('very large principal does not overflow or go negative', () {
      final result = total(
        principal: 999999999999,
        type: InterestType.reducingMonthly,
        rate: 2,
        periods: 12,
      );
      expect(result.isNegative, isFalse);
      expect(result.rupiah, 1134715159476);
    });
  });

  group('invalid input', () {
    test('principal must be positive', () {
      expect(() => total(principal: 0), throwsArgumentError);
      expect(() => total(principal: -1), throwsArgumentError);
    });

    test('rate must not be negative', () {
      expect(
        () => total(principal: 1000, type: InterestType.flatMonthly, rate: -1),
        throwsArgumentError,
      );
    });

    test('admin fee must not be negative', () {
      expect(() => total(principal: 1000, adminFee: -1), throwsArgumentError);
    });

    test('periods must be at least 1', () {
      expect(() => total(principal: 1000, periods: 0), throwsArgumentError);
    });
  });
}
