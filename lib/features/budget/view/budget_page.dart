import 'package:flutter/material.dart';
import 'package:geuralunas/l10n/l10n.dart';

/// Placeholder for the budget tab; filled in by a later phase.
class BudgetPage extends StatelessWidget {
  /// Creates the page.
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('budget-page'),
      appBar: AppBar(title: Text(context.l10n.navBudget)),
      body: const SizedBox.expand(),
    );
  }
}
