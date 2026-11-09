import 'package:flutter/material.dart';
import 'package:geuralunas/l10n/l10n.dart';

/// Placeholder for the debts tab; filled in by a later phase.
class DebtsPage extends StatelessWidget {
  /// Creates the page.
  const DebtsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('debts-page'),
      appBar: AppBar(title: Text(context.l10n.navDebts)),
      body: const SizedBox.expand(),
    );
  }
}
