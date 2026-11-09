import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/app/theme/app_theme.dart';
import 'package:geuralunas/app/theme/spacing.dart';

void main() {
  group('AppTheme', () {
    test('light theme uses material3 and light brightness', () {
      final theme = AppTheme.light();

      expect(theme.useMaterial3, isTrue);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('dark theme is dark', () {
      expect(AppTheme.dark().colorScheme.brightness, Brightness.dark);
    });

    test('text theme has bodyMedium', () {
      expect(AppTheme.light().textTheme.bodyMedium, isNotNull);
    });
  });

  group('Spacing', () {
    test('scale increases', () {
      expect(Spacing.xs, lessThan(Spacing.sm));
      expect(Spacing.sm, lessThan(Spacing.md));
      expect(Spacing.md, lessThan(Spacing.lg));
      expect(Spacing.lg, lessThan(Spacing.xl));
    });
  });
}
