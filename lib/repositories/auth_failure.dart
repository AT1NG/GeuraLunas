/// Domain-level auth errors, mapped from Firebase error codes.
sealed class AuthFailure implements Exception {
  const AuthFailure();
}

final class InvalidCredentials extends AuthFailure {
  const InvalidCredentials();
}

final class InvalidEmail extends AuthFailure {
  const InvalidEmail();
}

final class EmailInUse extends AuthFailure {
  const EmailInUse();
}

final class WeakPassword extends AuthFailure {
  const WeakPassword();
}

final class TooManyRequests extends AuthFailure {
  const TooManyRequests();
}

final class NetworkFailure extends AuthFailure {
  const NetworkFailure();
}

final class AccountExistsWithDifferentCredential extends AuthFailure {
  const AccountExistsWithDifferentCredential();
}

final class UnknownAuthFailure extends AuthFailure {
  const UnknownAuthFailure();
}
