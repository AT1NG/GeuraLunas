import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geuralunas/shared/parse_amount.dart';

/// Keeps only digits and groups them with dots while typing.
class ThousandsFormatter extends TextInputFormatter {
  /// Creates the formatter.
  const ThousandsFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = formatThousands(newValue.text);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// A rupiah amount field with a number keypad and thousands separators.
class AmountField extends StatelessWidget {
  /// Creates the field. [onChanged] receives the formatted text.
  const AmountField({
    required this.label,
    required this.onChanged,
    this.controller,
    this.errorText,
    this.helperText,
    this.fieldKey,
    this.autofocus = false,
    super.key,
  });

  /// Field label.
  final String label;

  /// Called with the text as shown (for example `1.500.000`).
  final ValueChanged<String> onChanged;

  /// Controls the text; pass one to prefill.
  final TextEditingController? controller;

  /// Error to show under the field.
  final String? errorText;

  /// Hint to show under the field.
  final String? helperText;

  /// Key set on the inner text field (for tests).
  final Key? fieldKey;

  /// Whether the field takes focus as soon as it appears.
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: fieldKey,
      autofocus: autofocus,
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: const [ThousandsFormatter()],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixText: 'Rp ',
        errorText: errorText,
        helperText: helperText,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
