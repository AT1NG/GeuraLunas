import 'package:flutter/widgets.dart';
import 'package:geuralunas/features/budget/view/budget_page.dart';
import 'package:geuralunas/features/debts/view/debts_page.dart';
import 'package:geuralunas/features/home/view/home_page.dart';
import 'package:geuralunas/features/more/view/more_page.dart';
import 'package:geuralunas/features/shell/app_shell.dart';
import 'package:go_router/go_router.dart';

StatefulShellBranch _branch(String path, Widget page) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (_, _) => page)],
);

/// Builds the app router.
GoRouter createRouter({
  String initialLocation = '/home',
  Listenable? refreshListenable,
  GoRouterRedirect? redirect,
}) {
  return GoRouter(
    initialLocation: initialLocation,
    refreshListenable: refreshListenable,
    redirect: redirect,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => AppShell(navigationShell: shell),
        branches: [
          _branch('/home', const HomePage()),
          _branch('/debts', const DebtsPage()),
          _branch('/budget', const BudgetPage()),
          _branch('/more', const MorePage()),
        ],
      ),
    ],
  );
}
