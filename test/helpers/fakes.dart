import 'dart:async';

import 'package:geuralunas/domain/auth/app_user.dart';
import 'package:geuralunas/domain/reminder/reminder_settings.dart';
import 'package:geuralunas/repositories/auth_repository.dart';
import 'package:geuralunas/repositories/onboarding_repository.dart';
import 'package:geuralunas/repositories/user_profile_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

/// In-memory auth repository for app-level tests.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AppUser? initialUser, bool emitOnListen = true}) {
    _controller = StreamController<AppUser?>.broadcast(
      onListen: () {
        if (emitOnListen) _controller.add(_user);
      },
    );
    _user = initialUser;
  }

  late final StreamController<AppUser?> _controller;
  AppUser? _user;

  void emit(AppUser? user) {
    _user = user;
    _controller.add(user);
  }

  @override
  Stream<AppUser?> get authStateChanges => _controller.stream;

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {}

  @override
  Future<bool> signInWithGoogle() async => true;

  @override
  Future<void> sendPasswordReset(String email) async {}

  @override
  Future<void> signOut() async => emit(null);
}

class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository({this.seen = true});

  bool seen;

  @override
  Future<bool> isSeen() async => seen;

  @override
  Future<void> markSeen() async => seen = true;
}

const testUser = AppUser(
  uid: 'u1',
  email: 'rani@mail.com',
  displayName: 'Rani',
);

class FakeUserProfileRepository implements UserProfileRepository {
  final ensured = <String>[];

  @override
  Future<void> ensureProfile(AppUser user) async => ensured.add(user.uid);

  /// Reminder settings the fake reports; push a new value with [setSettings].
  ReminderSettings _settings = ReminderSettings.defaults;
  final _settingsController = StreamController<ReminderSettings>.broadcast();

  /// Calls made to `saveReminderSettings`.
  final saved = <ReminderSettings>[];

  void setSettings(ReminderSettings settings) {
    _settings = settings;
    _settingsController.add(settings);
  }

  @override
  Stream<ReminderSettings> watchReminderSettings(String uid) async* {
    yield _settings;
    yield* _settingsController.stream;
  }

  @override
  Future<void> saveReminderSettings(
    String uid,
    ReminderSettings settings,
  ) async {
    saved.add(settings);
    setSettings(settings);
  }
}
