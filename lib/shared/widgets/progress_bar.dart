import 'package:flutter/material.dart';
import 'package:geuralunas/app/theme/spacing.dart';

/// A thin progress bar; [value] is clamped to 0..1.
class ProgressBar extends StatelessWidget {
  /// Creates a bar showing [value].
  const ProgressBar({required this.value, super.key});

  /// Progress from 0 to 1.
  final double value;

  @override
  Widget build(BuildContext context) => LinearProgressIndicator(
    value: value.clamp(0, 1),
    minHeight: Spacing.sm,
    borderRadius: BorderRadius.circular(Spacing.xs),
  );
}
