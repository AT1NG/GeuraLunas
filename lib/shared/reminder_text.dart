import 'package:geuralunas/domain/reminder/reminder_plan.dart';
import 'package:geuralunas/l10n/gen/app_localizations.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';

/// Title of every payment reminder notification.
String reminderTitle(AppLocalizations l10n) => l10n.reminderTitle;

/// Body text for [plan], such as "Cicilan Paylater A Rp350.000 jatuh tempo
/// besok."
String reminderBody(ReminderPlan plan, AppLocalizations l10n) {
  final when = switch (plan.daysBefore) {
    0 => l10n.reminderWhenToday,
    1 => l10n.reminderWhenTomorrow,
    final n => l10n.reminderWhenInDays(n),
  };
  return l10n.reminderBody(plan.debtName, formatRupiah(plan.amount), when);
}
