import 'package:shared_preferences/shared_preferences.dart';

abstract interface class OnboardingRepository {
  Future<bool> isSeen();

  Future<void> markSeen();
}

class SharedPrefsOnboardingRepository implements OnboardingRepository {
  SharedPrefsOnboardingRepository(this._prefs);

  static const _key = 'onboarding_seen';

  final SharedPreferences _prefs;

  @override
  Future<bool> isSeen() async => _prefs.getBool(_key) ?? false;

  @override
  Future<void> markSeen() => _prefs.setBool(_key, true);
}
