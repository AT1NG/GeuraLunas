import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/budget/budget_cycle.dart';

void main() {
  group('BudgetCycle.of', () {
    test('start day 1 is the calendar month', () {
      final cycle = BudgetCycle.of(DateTime(2026, 11, 10), startDay: 1);
      expect(cycle.start, DateTime(2026, 11));
      expect(cycle.endInclusive, DateTime(2026, 11, 30));
      expect(cycle.id, '2026-11');
    });

    test('before the start day the cycle began last month', () {
      final cycle = BudgetCycle.of(DateTime(2026, 11, 10), startDay: 25);
      expect(cycle.start, DateTime(2026, 10, 25));
      expect(cycle.endInclusive, DateTime(2026, 11, 24));
      expect(cycle.id, '2026-10');
    });

    test('on the start day a new cycle begins', () {
      final cycle = BudgetCycle.of(DateTime(2026, 11, 25), startDay: 25);
      expect(cycle.start, DateTime(2026, 11, 25));
      expect(cycle.endInclusive, DateTime(2026, 12, 24));
      expect(cycle.id, '2026-11');
    });

    test('a cycle can cross the new year', () {
      final cycle = BudgetCycle.of(DateTime(2027, 1, 10), startDay: 25);
      expect(cycle.start, DateTime(2026, 12, 25));
      expect(cycle.endInclusive, DateTime(2027, 1, 24));
      expect(cycle.id, '2026-12');
    });

    test('start day 28 reaches into a short February', () {
      final cycle = BudgetCycle.of(DateTime(2027, 3, 5), startDay: 28);
      expect(cycle.start, DateTime(2027, 2, 28));
      expect(cycle.endInclusive, DateTime(2027, 3, 27));
    });

    test('a leap February ends on the 29th', () {
      final cycle = BudgetCycle.of(DateTime(2028, 2, 10), startDay: 1);
      expect(cycle.endInclusive, DateTime(2028, 2, 29));
    });

    test('the time of day does not matter', () {
      final cycle = BudgetCycle.of(DateTime(2026, 11, 10, 23, 59), startDay: 1);
      expect(cycle.start, DateTime(2026, 11));
    });

    test('a start day outside 1 to 28 is rejected', () {
      expect(
        () => BudgetCycle.of(DateTime(2026, 11, 10), startDay: 0),
        throwsArgumentError,
      );
      expect(
        () => BudgetCycle.of(DateTime(2026, 11, 10), startDay: 29),
        throwsArgumentError,
      );
    });
  });

  group('contains', () {
    final cycle = BudgetCycle.of(DateTime(2026, 11, 10), startDay: 1);

    test('the last minute of the last day is inside', () {
      expect(cycle.contains(DateTime(2026, 11, 30, 23, 59)), isTrue);
    });

    test('midnight of the next day is outside', () {
      expect(cycle.contains(DateTime(2026, 12)), isFalse);
    });

    test('the first instant is inside and just before is outside', () {
      expect(cycle.contains(DateTime(2026, 11)), isTrue);
      expect(cycle.contains(DateTime(2026, 10, 31, 23, 59)), isFalse);
    });
  });

  group('remainingDays', () {
    final cycle = BudgetCycle.of(DateTime(2026, 11, 10), startDay: 1);

    test('counts today through the last day', () {
      expect(cycle.remainingDays(DateTime(2026, 11, 10)), 21);
    });

    test('is 1 on the last day', () {
      expect(cycle.remainingDays(DateTime(2026, 11, 30, 18)), 1);
    });

    test('is at least 1 after the cycle', () {
      expect(cycle.remainingDays(DateTime(2026, 12, 5)), 1);
    });
  });

  test('constant default start day is 1', () {
    expect(defaultBudgetCycleStartDay, 1);
  });
}
