import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/features/auth/bloc/submit_status.dart';
import 'package:geuralunas/repositories/auth_failure.dart';
import 'package:geuralunas/repositories/auth_repository.dart';
import 'package:geuralunas/shared/validators.dart';

final class LoginState extends Equatable {
  const LoginState({
    this.email = '',
    this.password = '',
    this.status = SubmitStatus.idle,
    this.failure,
    this.showErrors = false,
  });

  final String email;
  final String password;
  final SubmitStatus status;
  final AuthFailure? failure;

  /// Field errors are shown only after the first submit attempt.
  final bool showErrors;

  ValidationError? get emailError => validateEmail(email);
  ValidationError? get passwordError =>
      password.isEmpty ? ValidationError.required : null;

  LoginState copyWith({
    String? email,
    String? password,
    SubmitStatus? status,
    AuthFailure? failure,
    bool clearFailure = false,
    bool? showErrors,
  }) => LoginState(
    email: email ?? this.email,
    password: password ?? this.password,
    status: status ?? this.status,
    failure: clearFailure ? null : failure ?? this.failure,
    showErrors: showErrors ?? this.showErrors,
  );

  @override
  List<Object?> get props => [email, password, status, failure, showErrors];
}

class LoginCubit extends Cubit<LoginState> {
  LoginCubit(this._repository) : super(const LoginState());

  final AuthRepository _repository;

  void emailChanged(String value) => emit(state.copyWith(email: value));

  void passwordChanged(String value) => emit(state.copyWith(password: value));

  Future<void> submit() async {
    if (state.status == SubmitStatus.submitting) return;
    if (state.emailError != null || state.passwordError != null) {
      emit(state.copyWith(showErrors: true));
      return;
    }
    await _run(
      () async {
        await _repository.signInWithEmail(
          email: normalizeEmail(state.email),
          password: state.password,
        );
        return true;
      },
    );
  }

  Future<void> submitGoogle() async {
    if (state.status == SubmitStatus.submitting) return;
    await _run(_repository.signInWithGoogle);
  }

  /// [action] returns `false` when the user cancelled (back to idle).
  Future<void> _run(Future<bool> Function() action) async {
    emit(state.copyWith(status: SubmitStatus.submitting, clearFailure: true));
    try {
      final done = await action();
      emit(
        state.copyWith(
          status: done ? SubmitStatus.success : SubmitStatus.idle,
        ),
      );
    } on AuthFailure catch (f) {
      emit(state.copyWith(status: SubmitStatus.failure, failure: f));
    }
  }
}
