import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/app/theme/app_theme.dart';
import 'package:geuralunas/l10n/gen/app_localizations.dart';

/// Pumps [child] inside a themed, localized [MaterialApp].
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<BlocProvider<dynamic>> providers = const [],
}) {
  final app = MaterialApp(
    theme: AppTheme.light(),
    darkTheme: AppTheme.dark(),
    locale: const Locale('id'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
  return tester.pumpWidget(
    providers.isEmpty
        ? app
        : MultiBlocProvider(providers: providers, child: app),
  );
}
