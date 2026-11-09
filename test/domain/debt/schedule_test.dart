import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/debt/schedule.dart';
import 'package:geuralunas/domain/money.dart';

List<DateTime> dues(List<Installment> list) =>
    list.map((i) => i.dueDate).toList();

int sum(List<Installment> list) =>
    list.fold(0, (total, i) => total + i.amount.rupiah);

void main() {
  group('addPeriods', () {
    test('monthly keeps the anchor day, clamped to month end', () {
      final anchor = DateTime(2026, 1, 31);
      expect(addPeriods(anchor, Frequency.monthly, 0), DateTime(2026, 1, 31));
      expect(addPeriods(anchor, Frequency.monthly, 1), DateTime(2026, 2, 28));
      expect(addPeriods(anchor, Frequency.monthly, 2), DateTime(2026, 3, 31));
      expect(addPeriods(anchor, Frequency.monthly, 3), DateTime(2026, 4, 30));
    });

    test('leap year February has 29 days', () {
      final anchor = DateTime(2028, 1, 31);
      expect(addPeriods(anchor, Frequency.monthly, 1), DateTime(2028, 2, 29));
    });

    test('29 Feb in a leap year clamps to 28 Feb a year later', () {
      final anchor = DateTime(2028, 2, 29);
      expect(addPeriods(anchor, Frequency.monthly, 12), DateTime(2029, 2, 28));
    });

    test('monthly crosses the year boundary', () {
      final anchor = DateTime(2026, 11, 15);
      expect(addPeriods(anchor, Frequency.monthly, 2), DateTime(2027, 1, 15));
      expect(addPeriods(anchor, Frequency.monthly, 14), DateTime(2028, 1, 15));
    });

    test('weekly adds 7 days per period across month and year', () {
      final anchor = DateTime(2026, 12, 28);
      expect(addPeriods(anchor, Frequency.weekly, 1), DateTime(2027, 1, 4));
      expect(addPeriods(anchor, Frequency.weekly, 2), DateTime(2027, 1, 11));
    });

    test('once always returns the anchor date', () {
      final anchor = DateTime(2026, 11, 9);
      expect(addPeriods(anchor, Frequency.once, 0), anchor);
      expect(addPeriods(anchor, Frequency.once, 5), anchor);
    });

    test('drops the time of day', () {
      expect(
        addPeriods(DateTime(2026, 11, 9, 17, 45), Frequency.monthly, 1),
        DateTime(2026, 12, 9),
      );
    });
  });

  group('generateSchedule', () {
    test('monthly from 31 Jan: 31 Jan, 28 Feb, 31 Mar, 30 Apr', () {
      final schedule = generateSchedule(
        totalPayable: const Money(400000),
        count: 4,
        frequency: Frequency.monthly,
        firstDueDate: DateTime(2026, 1, 31),
      );
      expect(dues(schedule), [
        DateTime(2026, 1, 31),
        DateTime(2026, 2, 28),
        DateTime(2026, 3, 31),
        DateTime(2026, 4, 30),
      ]);
    });

    test('numbers installments from 1 and starts unpaid', () {
      final schedule = generateSchedule(
        totalPayable: const Money(300000),
        count: 3,
        frequency: Frequency.weekly,
        firstDueDate: DateTime(2026, 12, 28),
      );
      expect(schedule.map((i) => i.seq), [1, 2, 3]);
      expect(
        schedule.every(
          (i) =>
              i.paidAmount == Money.zero &&
              i.status == InstallmentStatus.pending &&
              i.paidAt == null,
        ),
        isTrue,
      );
      expect(dues(schedule), [
        DateTime(2026, 12, 28),
        DateTime(2027, 1, 4),
        DateTime(2027, 1, 11),
      ]);
    });

    test('rounding remainder goes to the last installment', () {
      final schedule = generateSchedule(
        totalPayable: const Money(1000000),
        count: 3,
        frequency: Frequency.monthly,
        firstDueDate: DateTime(2026, 12),
      );
      expect(schedule.map((i) => i.amount.rupiah), [333333, 333333, 333334]);
    });

    test('amounts always sum to the total', () {
      for (final total in [1, 2, 7, 100, 1000001, 999999999999]) {
        for (final count in [1, 2, 3, 7, 12, 36]) {
          if (total < count) continue;
          final schedule = generateSchedule(
            totalPayable: Money(total),
            count: count,
            frequency: Frequency.monthly,
            firstDueDate: DateTime(2026, 11, 9),
          );
          expect(sum(schedule), total, reason: 'total=$total count=$count');
          expect(schedule.length, count);
          expect(schedule.every((i) => i.amount.rupiah > 0), isTrue);
        }
      }
    });

    test('a single installment gets the whole total', () {
      final schedule = generateSchedule(
        totalPayable: const Money(123457),
        count: 1,
        frequency: Frequency.monthly,
        firstDueDate: DateTime(2026, 12, 5),
      );
      expect(schedule.single.amount, const Money(123457));
    });

    test('frequency once yields one installment on the first due date', () {
      final schedule = generateSchedule(
        totalPayable: const Money(500000),
        count: 1,
        frequency: Frequency.once,
        firstDueDate: DateTime(2026, 12, 5),
      );
      expect(dues(schedule), [DateTime(2026, 12, 5)]);
    });

    test('rejects invalid arguments', () {
      expect(
        () => generateSchedule(
          totalPayable: const Money(1000),
          count: 0,
          frequency: Frequency.monthly,
          firstDueDate: DateTime(2026),
        ),
        throwsArgumentError,
      );
      expect(
        () => generateSchedule(
          totalPayable: Money.zero,
          count: 3,
          frequency: Frequency.monthly,
          firstDueDate: DateTime(2026),
        ),
        throwsArgumentError,
      );
      expect(
        () => generateSchedule(
          totalPayable: const Money(2),
          count: 3,
          frequency: Frequency.monthly,
          firstDueDate: DateTime(2026),
        ),
        throwsArgumentError,
      );
    });
  });

  group('nextDueDate', () {
    List<Installment> three() => generateSchedule(
      totalPayable: const Money(300000),
      count: 3,
      frequency: Frequency.monthly,
      firstDueDate: DateTime(2026, 12, 5),
    );

    test('is the first installment while all are pending', () {
      expect(nextDueDate(three()), DateTime(2026, 12, 5));
    });

    test('skips paid installments', () {
      final list = three();
      list[0] = list[0].copyWith(status: InstallmentStatus.paid);
      expect(nextDueDate(list), DateTime(2027, 1, 5));
    });

    test('a partially paid installment is still the next due', () {
      final list = three();
      list[0] = list[0].copyWith(status: InstallmentStatus.partial);
      expect(nextDueDate(list), DateTime(2026, 12, 5));
    });

    test('is null when everything is paid', () {
      final list = three()
          .map((i) => i.copyWith(status: InstallmentStatus.paid))
          .toList();
      expect(nextDueDate(list), isNull);
    });

    test('is null for an empty schedule', () {
      expect(nextDueDate(const []), isNull);
    });

    test('picks the earliest date even if the list is unordered', () {
      final list = three().reversed.toList();
      expect(nextDueDate(list), DateTime(2026, 12, 5));
    });
  });
}
