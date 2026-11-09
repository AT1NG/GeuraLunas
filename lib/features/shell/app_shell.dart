import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geuralunas/features/shell/add_menu_sheet.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:go_router/go_router.dart';

/// Scaffold with the bottom navigation bar.
///
/// The bar has five destinations but the shell has four branches: the middle
/// "add" destination opens a sheet instead of a page. UI index -> branch:
/// 0->0, 1->1, 3->2, 4->3.
class AppShell extends StatelessWidget {
  /// Creates the shell around [navigationShell].
  const AppShell({required this.navigationShell, super.key});

  /// The go_router shell that hosts the tab pages.
  final StatefulNavigationShell navigationShell;

  static const int _addIndex = 2;

  int get _selectedIndex {
    final branch = navigationShell.currentIndex;
    return branch >= _addIndex ? branch + 1 : branch;
  }

  void _onSelected(BuildContext context, int index) {
    if (index == _addIndex) {
      unawaited(showAddMenu(context));
      return;
    }
    final branch = index > _addIndex ? index - 1 : index;
    navigationShell.goBranch(
      branch,
      initialLocation: branch == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => _onSelected(context, i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: l10n.navHome,
          ),
          NavigationDestination(
            icon: const Icon(Icons.receipt_long_outlined),
            selectedIcon: const Icon(Icons.receipt_long),
            label: l10n.navDebts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_circle_outline),
            label: l10n.navAdd,
          ),
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_outline),
            selectedIcon: const Icon(Icons.pie_chart),
            label: l10n.navBudget,
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz),
            label: l10n.navMore,
          ),
        ],
      ),
    );
  }
}
