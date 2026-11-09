import 'package:geuralunas/domain/money.dart';

/// The largest amount a form accepts: Rp999.999.999.999.
const maxAmount = 999999999999;

final _plain = RegExp(r'^\d+$');
final _grouped = RegExp(r'^\d{1,3}(\.\d{3})+$');
final _rate = RegExp(r'^\d+(\.\d+)?$');

/// Reads an amount typed or pasted by a person: `1.500.000`, `1500000`,
/// `Rp 1.500.000`.
///
/// Returns `null` for anything else (blank, text, negative, wrong grouping,
/// above [maxAmount]) and for zero unless [allowZero] is set.
Money? parseAmount(String input, {bool allowZero = false}) {
  var text = input.trim();
  if (text.toLowerCase().startsWith('rp')) text = text.substring(2).trim();
  if (!_plain.hasMatch(text) && !_grouped.hasMatch(text)) return null;
  final value = int.tryParse(text.replaceAll('.', ''));
  if (value == null || value > maxAmount) return null;
  if (value == 0 && !allowZero) return null;
  return Money(value);
}

/// Reads an interest rate in percent; accepts `0.4` and `0,4`.
/// Returns `null` for blank, negative, text, or above 1000.
double? parseRate(String input) {
  final text = input.trim().replaceAll(',', '.');
  if (!_rate.hasMatch(text)) return null;
  final value = double.parse(text);
  return value > 1000 ? null : value;
}

/// Keeps only the digits of [input] and groups them with dots:
/// `1500000` becomes `1.500.000`.
String formatThousands(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  final trimmed = digits.replaceFirst(RegExp(r'^0+(?=\d)'), '');
  final out = StringBuffer();
  for (var i = 0; i < trimmed.length; i++) {
    if (i > 0 && (trimmed.length - i) % 3 == 0) out.write('.');
    out.write(trimmed[i]);
  }
  return out.toString();
}
