import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/repositories/onboarding_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('isSeen false by default', () async {
    final repo = SharedPrefsOnboardingRepository(
      await SharedPreferences.getInstance(),
    );
    expect(await repo.isSeen(), isFalse);
  });

  test('markSeen persists true', () async {
    final prefs = await SharedPreferences.getInstance();
    await SharedPrefsOnboardingRepository(prefs).markSeen();
    expect(await SharedPrefsOnboardingRepository(prefs).isSeen(), isTrue);
    expect(prefs.getBool('onboarding_seen'), isTrue);
  });
}
