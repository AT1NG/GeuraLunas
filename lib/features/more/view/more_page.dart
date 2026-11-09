import 'package:flutter/material.dart';
import 'package:geuralunas/l10n/l10n.dart';

/// Placeholder for the more tab; filled in by a later phase.
class MorePage extends StatelessWidget {
  /// Creates the page.
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('more-page'),
      appBar: AppBar(title: Text(context.l10n.navMore)),
      body: const SizedBox.expand(),
    );
  }
}
