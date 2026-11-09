import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/app/router_redirect.dart';
import 'package:geuralunas/features/auth/bloc/auth_bloc.dart';

void main() {
  // ignore: avoid_positional_boolean_parameters // nullable flag, test helper
  String? r(AuthStatus status, bool? seen, String location) => resolveRedirect(
    status: status,
    onboardingSeen: seen,
    location: location,
  );

  group('unknown auth', () {
    for (final seen in <bool?>[null, false, true]) {
      test('seen=$seen: any location other than /splash goes to /splash', () {
        for (final loc in ['/home', '/login', '/onboarding', '/debts']) {
          expect(r(AuthStatus.unknown, seen, loc), '/splash');
        }
      });
      test('seen=$seen: /splash stays', () {
        expect(r(AuthStatus.unknown, seen, '/splash'), isNull);
      });
    }
  });

  group('unauthenticated, onboarding still loading', () {
    test('other locations go to /splash', () {
      for (final loc in ['/home', '/login', '/onboarding']) {
        expect(r(AuthStatus.unauthenticated, null, loc), '/splash');
      }
    });
    test('/splash stays', () {
      expect(r(AuthStatus.unauthenticated, null, '/splash'), isNull);
    });
  });

  group('unauthenticated, onboarding not seen', () {
    test('other locations go to /onboarding', () {
      for (final loc in ['/home', '/login', '/register', '/splash']) {
        expect(r(AuthStatus.unauthenticated, false, loc), '/onboarding');
      }
    });
    test('/onboarding stays', () {
      expect(r(AuthStatus.unauthenticated, false, '/onboarding'), isNull);
    });
  });

  group('unauthenticated, onboarding seen', () {
    test('auth screens stay', () {
      for (final loc in ['/login', '/register', '/forgot-password']) {
        expect(r(AuthStatus.unauthenticated, true, loc), isNull);
      }
    });
    test('app and transient screens go to /login', () {
      for (final loc in ['/home', '/splash', '/onboarding', '/debts']) {
        expect(r(AuthStatus.unauthenticated, true, loc), '/login');
      }
    });
  });

  group('authenticated', () {
    for (final seen in <bool?>[null, false, true]) {
      test('seen=$seen: auth and transient screens go to /home', () {
        for (final loc in [
          '/login',
          '/register',
          '/forgot-password',
          '/splash',
          '/onboarding',
        ]) {
          expect(r(AuthStatus.authenticated, seen, loc), '/home');
        }
      });
      test('seen=$seen: app screens stay', () {
        for (final loc in ['/home', '/debts', '/more/settings']) {
          expect(r(AuthStatus.authenticated, seen, loc), isNull);
        }
      });
    }
  });
}
