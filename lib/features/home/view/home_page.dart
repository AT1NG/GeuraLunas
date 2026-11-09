import 'package:flutter/material.dart';
import 'package:geuralunas/l10n/l10n.dart';

/// Placeholder for the home tab; filled in by a later phase.
class HomePage extends StatelessWidget {
  /// Creates the page.
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('home-page'),
      appBar: AppBar(title: Text(context.l10n.navHome)),
      body: const SizedBox.expand(),
    );
  }
}
