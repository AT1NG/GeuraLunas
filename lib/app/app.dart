import 'package:flutter/material.dart';
import 'package:geuralunas/app/theme/app_theme.dart';
import 'package:geuralunas/l10n/l10n.dart';

/// Root widget of the GeuraLunas app.
class App extends StatelessWidget {
  /// Creates the root widget.
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.appName,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: const Locale('id'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) =>
            Scaffold(body: Center(child: Text(context.l10n.appName))),
      ),
    );
  }
}
