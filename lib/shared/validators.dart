/// Reasons a form field can be rejected. UI maps these to localized text.
enum ValidationError { required, invalidEmail, passwordTooShort }

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Returns `null` when [v] is a valid email.
ValidationError? validateEmail(String? v) {
  final value = v?.trim() ?? '';
  if (value.isEmpty) return ValidationError.required;
  if (!_emailPattern.hasMatch(value)) return ValidationError.invalidEmail;
  return null;
}

/// Returns `null` when [v] is a valid password (min 8 chars).
ValidationError? validatePassword(String? v) {
  final value = v ?? '';
  if (value.isEmpty) return ValidationError.required;
  if (value.length < 8) return ValidationError.passwordTooShort;
  return null;
}

/// Returns `null` when [v] is a non-blank name.
ValidationError? validateName(String? v) {
  if ((v?.trim() ?? '').isEmpty) return ValidationError.required;
  return null;
}
