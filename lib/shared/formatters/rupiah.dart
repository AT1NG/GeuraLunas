import 'package:geuralunas/domain/money.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

const _locale = 'id_ID';

/// Loads locale data. Call once at startup (and in tests) before formatting.
Future<void> initializeFormatting() => initializeDateFormatting(_locale);

final _rupiah = NumberFormat.currency(
  locale: _locale,
  symbol: 'Rp',
  decimalDigits: 0,
);

/// Formats [value] as `Rp1.250.000`; negatives as `-Rp1.000`.
String formatRupiah(Money value) {
  final formatted = _rupiah.format(value.rupiah.abs());
  return value.isNegative ? '-$formatted' : formatted;
}

final _date = DateFormat('d MMM y', _locale);

/// Formats [date] as `9 Nov 2026`.
String formatDate(DateTime date) => _date.format(date);
