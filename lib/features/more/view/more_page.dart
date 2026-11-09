import 'package:flutter/material.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:go_router/go_router.dart';

/// Entry point to settings and tools that do not fit in the bottom bar.
class MorePage extends StatelessWidget {
  /// Creates the page.
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      key: const Key('more-page'),
      appBar: AppBar(title: Text(l10n.navMore)),
      body: ListView(
        children: [
          ListTile(
            key: const Key('more-settings'),
            leading: const Icon(Icons.settings_outlined),
            title: Text(l10n.settingsTitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/more/settings'),
          ),
          ListTile(
            key: const Key('more-simulation'),
            enabled: false,
            leading: const Icon(Icons.trending_down),
            title: Text(l10n.moreSimulation),
            subtitle: Text(l10n.commonComingSoon),
          ),
        ],
      ),
    );
  }
}
