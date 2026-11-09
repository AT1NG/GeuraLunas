import 'package:flutter/material.dart';
import 'package:geuralunas/app/theme/spacing.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/auth_failure.dart';
import 'package:geuralunas/shared/validators.dart';

export 'package:geuralunas/shared/widgets/submit_button.dart';

/// Maps domain errors to localized, non-blaming copy.
extension AuthMessages on AppLocalizations {
  /// Text for a form field error.
  String validationText(ValidationError error) => switch (error) {
    ValidationError.required => validationRequired,
    ValidationError.invalidEmail => validationInvalidEmail,
    ValidationError.passwordTooShort => validationPasswordTooShort,
  };

  /// Text for a failed sign-in, sign-up or reset.
  String failureText(AuthFailure failure) => switch (failure) {
    InvalidCredentials() => authErrorInvalidCredentials,
    InvalidEmail() => authErrorInvalidEmail,
    EmailInUse() => authErrorEmailInUse,
    WeakPassword() => authErrorWeakPassword,
    TooManyRequests() => authErrorTooManyRequests,
    NetworkFailure() => authErrorNetwork,
    AccountExistsWithDifferentCredential() => authErrorDifferentCredential,
    UnknownAuthFailure() => authErrorUnknown,
  };
}

/// Inline error shown above the submit button.
class AuthErrorBanner extends StatelessWidget {
  /// Creates a banner showing [message].
  const AuthErrorBanner({required this.message, super.key});

  /// Localized error text.
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('auth-error'),
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: TextStyle(color: scheme.onErrorContainer)),
    );
  }
}

/// Password field with a show/hide toggle.
class PasswordField extends StatefulWidget {
  /// Creates a password field.
  const PasswordField({
    required this.onChanged,
    this.errorText,
    this.fieldKey,
    super.key,
  });

  /// Called with the current text.
  final ValueChanged<String> onChanged;

  /// Validation error to display, if any.
  final String? errorText;

  /// Key set on the inner text field (for tests).
  final Key? fieldKey;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return TextField(
      key: widget.fieldKey,
      obscureText: _obscure,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: TextInputType.visiblePassword,
      autofillHints: const [AutofillHints.password],
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: l10n.authPassword,
        errorText: widget.errorText,
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          tooltip: _obscure ? l10n.authShowPassword : l10n.authHidePassword,
          icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}
