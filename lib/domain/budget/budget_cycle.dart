import 'package:equatable/equatable.dart';

/// The day a budget cycle starts when the user has not chosen one.
const defaultBudgetCycleStartDay = 1;

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// One budget month: from a start day to the day before the next start day.
///
/// A cycle is named after the month it starts in, so the cycle that runs from
/// 25 Nov to 24 Dec has the id `2026-11`.
final class BudgetCycle extends Equatable {
  /// Creates a cycle from its first and last day (time of day is dropped).
  BudgetCycle({required DateTime start, required DateTime endInclusive})
    : start = _dateOnly(start),
      endInclusive = _dateOnly(endInclusive);

  /// The cycle that contains [day] when cycles start on [startDay] (1 to 28).
  factory BudgetCycle.of(DateTime day, {required int startDay}) {
    if (startDay < 1 || startDay > 28) {
      throw ArgumentError.value(startDay, 'startDay', 'must be 1 to 28');
    }
    final d = _dateOnly(day);
    final month = d.day >= startDay ? d.month : d.month - 1;
    final start = DateTime(d.year, month, startDay);
    // Day 0 of a month is the last day of the month before it.
    final end = DateTime(start.year, start.month + 1, startDay - 1);
    return BudgetCycle(start: start, endInclusive: end);
  }

  /// First day of the cycle.
  final DateTime start;

  /// Last day of the cycle.
  final DateTime endInclusive;

  /// `yyyy-MM` of the month the cycle starts in.
  String get id =>
      '${start.year.toString().padLeft(4, '0')}-'
      '${start.month.toString().padLeft(2, '0')}';

  /// Whether [day], at any time of day, falls inside the cycle.
  bool contains(DateTime day) {
    final d = _dateOnly(day);
    return !d.isBefore(start) && !d.isAfter(endInclusive);
  }

  /// Days from [today] to the last day, counting both; never below 1.
  int remainingDays(DateTime today) {
    final days = endInclusive.difference(_dateOnly(today)).inDays + 1;
    return days < 1 ? 1 : days;
  }

  @override
  List<Object?> get props => [start, endInclusive];
}
