import 'package:equatable/equatable.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/debt/payments.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/domain/reminder/reminder_settings.dart';

/// One notification to schedule.
final class ReminderPlan extends Equatable {
  const ReminderPlan({
    required this.id,
    required this.at,
    required this.debtId,
    required this.debtName,
    required this.amount,
    required this.daysBefore,
  });

  /// Stable notification id, see [notificationId].
  final int id;

  /// Wall-clock time in the reminder time zone.
  final DateTime at;
  final String debtId;
  final String debtName;

  /// What is still unpaid on the installment.
  final Money amount;
  final int daysBefore;

  @override
  List<Object?> get props => [id, at, debtId, debtName, amount, daysBefore];
}

int _fnv1a32(String s) {
  var hash = 0x811c9dc5;
  for (final unit in s.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}

/// Notification id that is the same on every run for the same installment and
/// reminder day, and always below 2^31.
///
/// `seq` up to 511 and `daysBefore` 0 to 7 fit in the low 12 bits.
int notificationId({
  required String debtId,
  required int seq,
  required int daysBefore,
}) => (_fnv1a32(debtId) % 500000) * 4096 + seq * 8 + daysBefore;

/// The reminders to schedule for [debts], earliest first.
///
/// Only unpaid installments of active "owe" debts count. [now] and the
/// returned times are wall-clock times in the reminder time zone. Reminders
/// that are not after [now], or are more than [horizonDays] ahead, are left
/// out, and at most [maxCount] remain.
List<ReminderPlan> planReminders({
  required List<DebtState> debts,
  required ReminderSettings settings,
  required DateTime now,
  int horizonDays = 60,
  int maxCount = 200,
}) {
  final limit = now.add(Duration(days: horizonDays));
  final plans = <ReminderPlan>[];
  for (final state in debts) {
    final debt = state.debt;
    if (debt.direction != DebtDirection.owe ||
        debt.status != DebtStatus.active) {
      continue;
    }
    for (final i in state.installments) {
      if (i.status == InstallmentStatus.paid) continue;
      for (final n in settings.daysBefore) {
        final at = DateTime(
          i.dueDate.year,
          i.dueDate.month,
          i.dueDate.day - n,
          settings.hour,
          settings.minute,
        );
        if (!at.isAfter(now) || at.isAfter(limit)) continue;
        plans.add(
          ReminderPlan(
            id: notificationId(debtId: debt.id, seq: i.seq, daysBefore: n),
            at: at,
            debtId: debt.id,
            debtName: debt.counterpartyName,
            amount: i.amount - i.paidAmount,
            daysBefore: n,
          ),
        );
      }
    }
  }
  plans.sort((a, b) {
    final byTime = a.at.compareTo(b.at);
    return byTime != 0 ? byTime : a.id.compareTo(b.id);
  });
  return plans.take(maxCount).toList();
}
