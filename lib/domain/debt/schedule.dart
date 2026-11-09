import 'dart:math' as math;

import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/money.dart';

/// The date [count] periods after [anchor], without the time of day.
///
/// Monthly keeps the anchor's day of month and clamps it to the last day of
/// the target month (31 Jan -> 28/29 Feb -> 31 Mar). It always counts from
/// [anchor], never from the previous result, so the day does not drift.
DateTime addPeriods(DateTime anchor, Frequency frequency, int count) {
  switch (frequency) {
    case Frequency.once:
      return DateTime(anchor.year, anchor.month, anchor.day);
    case Frequency.weekly:
      return DateTime(anchor.year, anchor.month, anchor.day + 7 * count);
    case Frequency.monthly:
      final monthIndex = anchor.month - 1 + count;
      final year = anchor.year + monthIndex ~/ 12;
      final month = monthIndex % 12 + 1;
      final lastDay = DateTime(year, month + 1, 0).day;
      return DateTime(year, month, math.min(anchor.day, lastDay));
  }
}

/// Splits [totalPayable] into [count] installments.
///
/// Every installment gets `totalPayable ~/ count`; the last one absorbs the
/// rounding remainder, so the amounts always sum to [totalPayable].
///
/// Dates normally count from [firstDueDate]. With a [periodAnchor] (the start
/// date) installment `i` falls `i` periods after the anchor instead, so a loan
/// started on the 31st keeps its due dates on the 31st (28 Feb, 31 Mar, ...)
/// rather than drifting to the 28th. [firstDueDate] is then unused.
List<Installment> generateSchedule({
  required Money totalPayable,
  required int count,
  required Frequency frequency,
  required DateTime firstDueDate,
  DateTime? periodAnchor,
}) {
  if (count < 1) {
    throw ArgumentError.value(count, 'count', 'must be >= 1');
  }
  if (totalPayable.rupiah <= 0) {
    throw ArgumentError.value(totalPayable, 'totalPayable', 'must be positive');
  }
  if (totalPayable.rupiah < count) {
    throw ArgumentError.value(
      count,
      'count',
      'each installment must be at least Rp1',
    );
  }

  final each = totalPayable.rupiah ~/ count;
  final remainder = totalPayable.rupiah - each * count;
  return [
    for (var i = 0; i < count; i++)
      Installment(
        seq: i + 1,
        dueDate: periodAnchor == null
            ? addPeriods(firstDueDate, frequency, i)
            : addPeriods(periodAnchor, frequency, i + 1),
        amount: Money(i == count - 1 ? each + remainder : each),
      ),
  ];
}

/// Due date of the nearest installment that is not fully paid.
DateTime? nextDueDate(List<Installment> installments) {
  DateTime? next;
  for (final i in installments) {
    if (i.status == InstallmentStatus.paid) continue;
    if (next == null || i.dueDate.isBefore(next)) next = i.dueDate;
  }
  return next;
}
