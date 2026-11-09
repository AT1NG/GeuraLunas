import 'dart:async';
import 'dart:developer' as developer;

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/domain/auth/app_user.dart';
import 'package:geuralunas/repositories/auth_repository.dart';
import 'package:geuralunas/repositories/user_profile_repository.dart';

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
  AuthBloc(this._repository, this._profiles) : super(const AuthState()) {
    on<AuthStarted>(_onStarted);
    on<AuthSignOutRequested>((event, emit) => _repository.signOut());
  }

  final AuthRepository _repository;
  final UserProfileRepository _profiles;
  String? _ensuredUid;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) {
    return emit.forEach<AppUser?>(
      _repository.authStateChanges,
      onData: (user) {
        if (user == null) {
          _ensuredUid = null;
          return const AuthState(status: AuthStatus.unauthenticated);
        }
        unawaited(_ensureProfile(user));
        return AuthState(status: AuthStatus.authenticated, user: user);
      },
    );
  }

  /// Runs once per signed-in uid. A failure never blocks login: it is logged
  /// and retried the next time the app opens (or the user signs in again).
  Future<void> _ensureProfile(AppUser user) async {
    if (_ensuredUid == user.uid) return;
    _ensuredUid = user.uid;
    try {
      await _profiles.ensureProfile(user);
    } on Object catch (error, stackTrace) {
      _ensuredUid = null;
      developer.log(
        'ensureProfile failed',
        name: 'AuthBloc',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
