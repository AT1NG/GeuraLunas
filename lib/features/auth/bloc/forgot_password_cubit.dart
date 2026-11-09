import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/features/auth/bloc/submit_status.dart';
import 'package:geuralunas/repositories/auth_failure.dart';
import 'package:geuralunas/repositories/auth_repository.dart';
import 'package:geuralunas/shared/validators.dart';

final class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.email = '',
    this.status = SubmitStatus.idle,
    this.failure,
    this.showErrors = false,
  });

  final String email;

  /// [SubmitStatus.success] means the reset email was sent.
  final SubmitStatus status;
  final AuthFailure? failure;
  final bool showErrors;

  ValidationError? get emailError => validateEmail(email);

  ForgotPasswordState copyWith({
    String? email,
    SubmitStatus? status,
    AuthFailure? failure,
    bool clearFailure = false,
    bool? showErrors,
  }) => ForgotPasswordState(
    email: email ?? this.email,
    status: status ?? this.status,
    failure: clearFailure ? null : failure ?? this.failure,
    showErrors: showErrors ?? this.showErrors,
  );

  @override
  List<Object?> get props => [email, status, failure, showErrors];
}

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit(this._repository) : super(const ForgotPasswordState());

  final AuthRepository _repository;

  void emailChanged(String value) => emit(state.copyWith(email: value));

  Future<void> submit() async {
    if (state.status == SubmitStatus.submitting) return;
    if (state.emailError != null) {
      emit(state.copyWith(showErrors: true));
      return;
    }
    emit(state.copyWith(status: SubmitStatus.submitting, clearFailure: true));
    try {
      await _repository.sendPasswordReset(normalizeEmail(state.email));
      emit(state.copyWith(status: SubmitStatus.success));
    } on AuthFailure catch (f) {
      emit(state.copyWith(status: SubmitStatus.failure, failure: f));
    }
  }
}
