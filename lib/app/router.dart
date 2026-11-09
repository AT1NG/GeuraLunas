import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/app/router_redirect.dart';
import 'package:geuralunas/features/auth/bloc/auth_bloc.dart';
import 'package:geuralunas/features/auth/view/forgot_password_page.dart';
import 'package:geuralunas/features/auth/view/login_page.dart';
import 'package:geuralunas/features/auth/view/register_page.dart';
import 'package:geuralunas/features/auth/view/splash_page.dart';
import 'package:geuralunas/features/budget/view/budget_page.dart';
import 'package:geuralunas/features/debts/view/debts_page.dart';
import 'package:geuralunas/features/home/view/home_page.dart';
import 'package:geuralunas/features/more/view/more_page.dart';
import 'package:geuralunas/features/onboarding/bloc/onboarding_cubit.dart';
import 'package:geuralunas/features/onboarding/view/onboarding_page.dart';
import 'package:geuralunas/features/shell/app_shell.dart';
import 'package:go_router/go_router.dart';

StatefulShellBranch _branch(String path, Widget page) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (_, _) => page)],
);

/// Re-evaluates the router redirect whenever auth or onboarding state changes.
class RouterRefresh extends ChangeNotifier {
  /// Listens to [authBloc] and [onboardingCubit].
  RouterRefresh(AuthBloc authBloc, OnboardingCubit onboardingCubit) {
    _subscriptions = [
      authBloc.stream.listen((_) => notifyListeners()),
      onboardingCubit.stream.listen((_) => notifyListeners()),
    ];
  }

  late final List<StreamSubscription<Object?>> _subscriptions;

  @override
  void dispose() {
    for (final s in _subscriptions) {
      unawaited(s.cancel());
    }
    super.dispose();
  }
}

/// Builds the app router.
///
/// When [authBloc] and [onboardingCubit] are given, navigation follows
/// [resolveRedirect]; without them the router has no guards (used in tests).
GoRouter createRouter({
  String? initialLocation,
  AuthBloc? authBloc,
  OnboardingCubit? onboardingCubit,
  Listenable? refreshListenable,
}) {
  final guarded = authBloc != null && onboardingCubit != null;
  return GoRouter(
    initialLocation: initialLocation ?? (guarded ? '/splash' : '/home'),
    refreshListenable: refreshListenable,
    redirect: guarded
        ? (context, state) => resolveRedirect(
            status: authBloc.state.status,
            onboardingSeen: onboardingCubit.state.seen,
            location: state.matchedLocation,
          )
        : null,
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
      GoRoute(
        path: '/onboarding',
        builder: (context, _) => OnboardingPage(
          onFinished: () =>
              unawaited(context.read<OnboardingCubit>().complete()),
        ),
      ),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, _) => const ForgotPasswordPage(),
      ),
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
