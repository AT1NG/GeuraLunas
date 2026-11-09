import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/domain/auth/app_user.dart';
import 'package:geuralunas/repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

sealed class AuthEvent {
  const AuthEvent();
}

final class AuthStarted extends AuthEvent {
  const AuthStarted();
}

final class AuthSignOutRequested extends AuthEvent {
  const AuthSignOutRequested();
}

final class AuthState extends Equatable {
  const AuthState({this.status = AuthStatus.unknown, this.user});

  final AuthStatus status;
  final AppUser? user;

  @override
  List<Object?> get props => [status, user];
}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository) : super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignOutRequested>((event, emit) => _repository.signOut());
  }

  final AuthRepository _repository;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) {
    return emit.forEach<AppUser?>(
      _repository.authStateChanges,
      onData: (user) => user == null
          ? const AuthState(status: AuthStatus.unauthenticated)
          : AuthState(status: AuthStatus.authenticated, user: user),
    );
  }
}
