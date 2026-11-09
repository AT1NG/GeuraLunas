import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/features/auth/bloc/auth_bloc.dart';
import 'package:geuralunas/features/settings/view/settings_page.dart';
import 'package:geuralunas/repositories/reminder_repository.dart';
import 'package:geuralunas/repositories/user_profile_repository.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  late _MockAuthBloc bloc;

  setUpAll(() => registerFallbackValue(const AuthStarted()));

  setUp(() {
    bloc = _MockAuthBloc();
    whenListen(
      bloc,
      const Stream<AuthState>.empty(),
      initialState: const AuthState(
        status: AuthStatus.authenticated,
        user: testUser,
      ),
    );
  });

  Future<void> pump(WidgetTester tester) => pumpApp(
    tester,
    const SettingsPage(),
    providers: [BlocProvider<AuthBloc>.value(value: bloc)],
    repositories: [
      RepositoryProvider<UserProfileRepository>.value(
        value: FakeUserProfileRepository(),
      ),
      RepositoryProvider<ReminderRepository>.value(
        value: FakeReminderRepository(),
      ),
    ],
  );

  testWidgets('shows the reminder settings above sign out', (tester) async {
    await pump(tester);

    expect(find.text('Pengingat bayar'), findsOneWidget);
    expect(find.byKey(const Key('reminder-day-3')), findsOneWidget);
  });

  testWidgets('shows name and email', (tester) async {
    await pump(tester);

    expect(find.text('Rani'), findsOneWidget);
    expect(find.text('rani@mail.com'), findsOneWidget);
  });

  testWidgets('sign out asks for confirmation; cancel does nothing', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('settings-sign-out')));
    await tester.pumpAndSettle();
    expect(find.text('Keluar dari akun?'), findsOneWidget);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    verifyNever(() => bloc.add(any()));
    expect(find.text('Keluar dari akun?'), findsNothing);
  });

  testWidgets('confirming sign out dispatches AuthSignOutRequested', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.byKey(const Key('settings-sign-out')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-sign-out-confirm')));
    await tester.pumpAndSettle();

    verify(() => bloc.add(any(that: isA<AuthSignOutRequested>()))).called(1);
  });
}
