import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/features/onboarding/bloc/onboarding_cubit.dart';
import 'package:geuralunas/repositories/onboarding_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements OnboardingRepository {}

void main() {
  late _MockRepo repo;
  setUp(() => repo = _MockRepo());

  blocTest<OnboardingCubit, OnboardingState>(
    'load emits seen false then true after complete',
    setUp: () {
      when(() => repo.isSeen()).thenAnswer((_) async => false);
      when(() => repo.markSeen()).thenAnswer((_) async {});
    },
    build: () => OnboardingCubit(repo),
    act: (c) async {
      await c.load();
      await c.complete();
    },
    expect: () => [
      const OnboardingState(seen: false),
      const OnboardingState(seen: true),
    ],
    verify: (_) => verify(() => repo.markSeen()).called(1),
  );

  test('starts not loaded', () {
    expect(OnboardingCubit(repo).state.seen, isNull);
  });
}
