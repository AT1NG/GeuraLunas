import 'package:flutter/material.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';

/// An amount of money formatted as `Rp1.250.000`.
class MoneyText extends StatelessWidget {
  /// Creates the text for [value].
  const MoneyText(this.value, {this.style, super.key});

  /// The amount to show.
  final Money value;

  /// Optional text style.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Text(formatRupiah(value), style: style);
}
