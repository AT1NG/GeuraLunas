import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/features/auth/bloc/submit_status.dart';
import 'package:geuralunas/repositories/auth_failure.dart';
import 'package:geuralunas/repositories/auth_repository.dart';
import 'package:geuralunas/shared/validators.dart';

final class RegisterState extends Equatable {
  const RegisterState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.status = SubmitStatus.idle,
    this.failure,
    this.showErrors = false,
  });

  final String name;
  final String email;
  final String password;
  final SubmitStatus status;
  final AuthFailure? failure;
  final bool showErrors;

  ValidationError? get nameError => validateName(name);
  ValidationError? get emailError => validateEmail(email);
  ValidationError? get passwordError => validatePassword(password);

  RegisterState copyWith({
    String? name,
    String? email,
    String? password,
    SubmitStatus? status,
    AuthFailure? failure,
    bool clearFailure = false,
    bool? showErrors,
  }) => RegisterState(
    name: name ?? this.name,
    email: email ?? this.email,
    password: password ?? this.password,
    status: status ?? this.status,
    failure: clearFailure ? null : failure ?? this.failure,
    showErrors: showErrors ?? this.showErrors,
  );

  @override
  List<Object?> get props => [
    name,
    email,
    password,
    status,
    failure,
    showErrors,
  ];
}

class RegisterCubit extends Cubit<RegisterState> {
  RegisterCubit(this._repository) : super(const RegisterState());

  final AuthRepository _repository;

  /// The screen can be disposed (by the auth redirect) while a request is in
  /// flight; late results must not throw.
  @override
  void emit(RegisterState state) {
    if (!isClosed) super.emit(state);
  }

  void nameChanged(String value) => emit(state.copyWith(name: value));

  void emailChanged(String value) => emit(state.copyWith(email: value));

  void passwordChanged(String value) => emit(state.copyWith(password: value));

  Future<void> submit() async {
    if (state.status == SubmitStatus.submitting) return;
    if (state.nameError != null ||
        state.emailError != null ||
        state.passwordError != null) {
      emit(state.copyWith(showErrors: true));
      return;
    }
    emit(state.copyWith(status: SubmitStatus.submitting, clearFailure: true));
    try {
      await _repository.signUpWithEmail(
        email: normalizeEmail(state.email),
        password: state.password,
        displayName: state.name,
      );
      emit(state.copyWith(status: SubmitStatus.success));
    } on AuthFailure catch (f) {
      emit(state.copyWith(status: SubmitStatus.failure, failure: f));
    } on Object {
      emit(
        state.copyWith(
          status: SubmitStatus.failure,
          failure: const UnknownAuthFailure(),
        ),
      );
    }
  }
}
