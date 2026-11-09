import 'package:flutter/material.dart';
import 'package:geuralunas/app/theme/spacing.dart';

/// Material 3 themes. The seed color below is the only literal color in the
/// app; everything else derives from the resulting [ColorScheme].
abstract final class AppTheme {
  static const Color _seed = Color(0xFF1B7F6B);

  /// Light theme.
  static ThemeData light() => _build(Brightness.light);

  /// Dark theme.
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: _seed,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.md,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
        ),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}
