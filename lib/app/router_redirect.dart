import 'package:geuralunas/features/auth/bloc/auth_bloc.dart';

const _splash = '/splash';
const _onboarding = '/onboarding';
const _login = '/login';
const _home = '/home';
const _authScreens = {'/login', '/register', '/forgot-password'};

/// Decides where the user must be, given auth and onboarding state.
///
/// Returns `null` when [location] is already correct.
String? resolveRedirect({
  required AuthStatus status,
  required bool? onboardingSeen,
  required String location,
}) {
  switch (status) {
    case AuthStatus.unknown:
      return location == _splash ? null : _splash;
    case AuthStatus.authenticated:
      final transient = location == _splash || location == _onboarding;
      return transient || _authScreens.contains(location) ? _home : null;
    case AuthStatus.unauthenticated:
      if (onboardingSeen == null) {
        return location == _splash ? null : _splash;
      }
      if (!onboardingSeen) {
        return location == _onboarding ? null : _onboarding;
      }
      return _authScreens.contains(location) ? null : _login;
  }
}
