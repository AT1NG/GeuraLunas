import 'package:flutter/material.dart';

/// Placeholder for the debt detail screen; filled in by the next task.
class DebtDetailPage extends StatelessWidget {
  /// Creates the page for the debt with [debtId].
  const DebtDetailPage({required this.debtId, super.key});

  /// Id of the debt to show.
  final String debtId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('debt-detail-page'),
      appBar: AppBar(),
      body: Center(child: Text(debtId)),
    );
  }
}
