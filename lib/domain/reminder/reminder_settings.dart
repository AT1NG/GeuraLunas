import 'package:equatable/equatable.dart';

/// When and how often a payment reminder fires.
final class ReminderSettings extends Equatable {
  const ReminderSettings({
    required this.hour,
    required this.minute,
    required this.daysBefore,
    required this.timezone,
  });

  /// 09:00, three days before, the day before and on the day.
  static const defaults = ReminderSettings(
    hour: 9,
    minute: 0,
    daysBefore: [3, 1, 0],
    timezone: 'Asia/Jakarta',
  );

  /// Whether [days] is acceptable: 1 to 8 distinct values from 0 to 7.
  static bool validDaysBefore(List<int> days) =>
      days.isNotEmpty &&
      days.length <= 8 &&
      days.every((d) => d >= 0 && d <= 7) &&
      days.toSet().length == days.length;

  final int hour;
  final int minute;

  /// How many days before the due date a reminder fires.
  final List<int> daysBefore;

  /// IANA zone name the reminder time is read in.
  final String timezone;

  ReminderSettings copyWith({
    int? hour,
    int? minute,
    List<int>? daysBefore,
    String? timezone,
  }) => ReminderSettings(
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    daysBefore: daysBefore ?? this.daysBefore,
    timezone: timezone ?? this.timezone,
  );

  @override
  List<Object?> get props => [hour, minute, daysBefore, timezone];
}
