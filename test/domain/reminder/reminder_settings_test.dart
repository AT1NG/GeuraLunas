import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/reminder/reminder_settings.dart';

void main() {
  test('defaults are 09:00, H-3/H-1/H-0, Asia/Jakarta', () {
    const d = ReminderSettings.defaults;
    expect(d.hour, 9);
    expect(d.minute, 0);
    expect(d.daysBefore, [3, 1, 0]);
    expect(d.timezone, 'Asia/Jakarta');
  });

  group('validDaysBefore', () {
    test('rejects empty, out of range, duplicates and too many', () {
      expect(ReminderSettings.validDaysBefore([]), isFalse);
      expect(ReminderSettings.validDaysBefore([8]), isFalse);
      expect(ReminderSettings.validDaysBefore([-1]), isFalse);
      expect(ReminderSettings.validDaysBefore([1, 1]), isFalse);
      expect(
        ReminderSettings.validDaysBefore([0, 1, 2, 3, 4, 5, 6, 7, 0]),
        isFalse,
      );
    });

    test('accepts valid lists', () {
      expect(ReminderSettings.validDaysBefore([0]), isTrue);
      expect(ReminderSettings.validDaysBefore([7, 5, 3, 2, 1, 0]), isTrue);
    });
  });

  test('copyWith replaces only given fields', () {
    final s = ReminderSettings.defaults.copyWith(hour: 7, minute: 30);
    expect(s.hour, 7);
    expect(s.minute, 30);
    expect(s.daysBefore, [3, 1, 0]);
    expect(s, isNot(ReminderSettings.defaults));
  });
}
