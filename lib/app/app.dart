import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/app/router.dart';
import 'package:geuralunas/app/theme/app_theme.dart';
import 'package:geuralunas/features/auth/bloc/auth_bloc.dart';
import 'package:geuralunas/features/onboarding/bloc/onboarding_cubit.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/auth_repository.dart';
import 'package:geuralunas/repositories/debt_repository.dart';
import 'package:geuralunas/repositories/onboarding_repository.dart';
import 'package:geuralunas/repositories/user_profile_repository.dart';
import 'package:go_router/go_router.dart';

/// Root widget of the GeuraLunas app.
class App extends StatefulWidget {
  /// Creates the root widget with its repositories.
  const App({
    required this.authRepository,
    required this.onboardingRepository,
    required this.userProfileRepository,
    required this.debtRepository,
    super.key,
  });

  /// Source of auth state and sign-in actions.
  final AuthRepository authRepository;

  /// Persisted "onboarding seen" flag.
  final OnboardingRepository onboardingRepository;

  /// Creates the Firestore profile on first sign-in.
  final UserProfileRepository userProfileRepository;

  /// Debts, installments and payments of the signed-in user.
  final DebtRepository debtRepository;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  StreamSubscription<Object>? _writeErrors;

  late final AuthBloc _authBloc = AuthBloc(
    widget.authRepository,
    widget.userProfileRepository,
  );
  late final OnboardingCubit _onboardingCubit = OnboardingCubit(
    widget.onboardingRepository,
  );
  late final RouterRefresh _refresh = RouterRefresh(
    _authBloc,
    _onboardingCubit,
  );
  late final GoRouter _router = createRouter(
    authBloc: _authBloc,
    onboardingCubit: _onboardingCubit,
    refreshListenable: _refresh,
  );

  @override
  void initState() {
    super.initState();
    _authBloc.add(const AuthStarted());
    unawaited(_onboardingCubit.load());
    _writeErrors = widget.debtRepository.writeErrors.listen(_onWriteRejected);
  }

  /// The server refused a write that the app had already shown as saved.
  void _onWriteRejected(Object error) {
    final l10n = lookupAppLocalizations(const Locale('id'));
    _messengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(l10n.writeRejected)),
    );
  }

  @override
  void dispose() {
    unawaited(_writeErrors?.cancel());
    _router.dispose();
    _refresh.dispose();
    unawaited(_authBloc.close());
    unawaited(_onboardingCubit.close());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>.value(value: widget.authRepository),
        RepositoryProvider<DebtRepository>.value(value: widget.debtRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: _authBloc),
          BlocProvider<OnboardingCubit>.value(value: _onboardingCubit),
        ],
        child: MaterialApp.router(
          scaffoldMessengerKey: _messengerKey,
          onGenerateTitle: (context) => context.l10n.appName,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          locale: const Locale('id'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: _router,
        ),
      ),
    );
  }
}
