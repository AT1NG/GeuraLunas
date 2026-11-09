import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/l10n/gen/app_localizations.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';

/// A polite message asking [name] to pay back [remaining].
///
/// Built only from fixed templates; the note of the debt is never included.
/// Line breaks in [name] become spaces and the name is trimmed. A due date
/// before the calendar day of [now] reads as already passed.
String buildCollectionMessage({
  required AppLocalizations l10n,
  required String name,
  required Money remaining,
  required DateTime now,
  DateTime? dueDate,
}) {
  final who = name.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();
  final amount = formatRupiah(remaining);
  if (dueDate == null) return l10n.collectionNoDue(who, amount);
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
  final date = formatDate(due);
  return due.isBefore(today)
      ? l10n.collectionAfterDue(who, amount, date)
      : l10n.collectionBeforeDue(who, amount, date);
}
