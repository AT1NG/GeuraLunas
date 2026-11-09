import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/repositories/onboarding_repository.dart';

/// [seen] is `null` until the stored flag has been loaded.
final class OnboardingState extends Equatable {
  const OnboardingState({required this.seen});

  final bool? seen;

  @override
  List<Object?> get props => [seen];
}

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit(this._repository) : super(const OnboardingState(seen: null));

  final OnboardingRepository _repository;

  /// If the stored flag cannot be read, assume it was not seen: showing
  /// onboarding once more is better than a splash screen that never ends.
  Future<void> load() async {
    try {
      emit(OnboardingState(seen: await _repository.isSeen()));
    } on Object {
      emit(const OnboardingState(seen: false));
    }
  }

  Future<void> complete() async {
    await _repository.markSeen();
    emit(const OnboardingState(seen: true));
  }
}
