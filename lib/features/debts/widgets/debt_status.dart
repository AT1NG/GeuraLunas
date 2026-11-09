import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/shared/widgets/status_chip.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// How many days ahead a due date counts as "soon".
const dueSoonDays = 3;

/// The status to display for [debt] on [today].
DebtStatusKind statusKindOf(Debt debt, DateTime today) {
  if (debt.status != DebtStatus.active) return DebtStatusKind.settled;
  if (debt.isOverdue(today)) return DebtStatusKind.overdue;
  final due = debt.nextDueDate;
  if (due != null) {
    final limit = _dateOnly(today).add(const Duration(days: dueSoonDays));
    if (!_dateOnly(due).isAfter(limit)) return DebtStatusKind.dueSoon;
  }
  return DebtStatusKind.active;
}
