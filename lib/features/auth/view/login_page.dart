import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/app/theme/spacing.dart';
import 'package:geuralunas/features/auth/bloc/login_cubit.dart';
import 'package:geuralunas/features/auth/bloc/submit_status.dart';
import 'package:geuralunas/features/auth/view/auth_widgets.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/auth_repository.dart';
import 'package:go_router/go_router.dart';

/// Email/password and Google sign-in screen.
class LoginPage extends StatelessWidget {
  /// Creates the login page.
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginCubit(context.read<AuthRepository>()),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatelessWidget {
  const _LoginView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<LoginCubit>();
    return Scaffold(
      key: const Key('login-page'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: BlocBuilder<LoginCubit, LoginState>(
            builder: (context, state) {
              final busy = state.status == SubmitStatus.submitting;
              final emailError = state.showErrors ? state.emailError : null;
              final passwordError = state.showErrors
                  ? state.passwordError
                  : null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: Spacing.xl),
                  Text(
                    l10n.loginTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(l10n.loginSubtitle),
                  const SizedBox(height: Spacing.lg),
                  TextField(
                    key: const Key('login-email'),
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    onChanged: cubit.emailChanged,
                    decoration: InputDecoration(
                      labelText: l10n.authEmail,
                      errorText: emailError == null
                          ? null
                          : l10n.validationText(emailError),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  PasswordField(
                    fieldKey: const Key('login-password'),
                    onChanged: cubit.passwordChanged,
                    errorText: passwordError == null
                        ? null
                        : l10n.validationText(passwordError),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      key: const Key('login-to-forgot'),
                      onPressed: () => context.push('/forgot-password'),
                      child: Text(l10n.loginForgot),
                    ),
                  ),
                  if (state.failure != null) ...[
                    AuthErrorBanner(message: l10n.failureText(state.failure!)),
                    const SizedBox(height: Spacing.md),
                  ],
                  SubmitButton(
                    key: const Key('login-submit'),
                    label: l10n.loginSubmit,
                    busy: busy,
                    onPressed: cubit.submit,
                  ),
                  const SizedBox(height: Spacing.md),
                  Center(child: Text(l10n.authOr)),
                  const SizedBox(height: Spacing.md),
                  OutlinedButton.icon(
                    key: const Key('login-google'),
                    onPressed: busy ? null : cubit.submitGoogle,
                    icon: const Icon(Icons.g_mobiledata, size: 28),
                    label: Text(l10n.loginGoogle),
                  ),
                  const SizedBox(height: Spacing.lg),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(l10n.loginNoAccount),
                      TextButton(
                        key: const Key('login-to-register'),
                        onPressed: () => context.push('/register'),
                        child: Text(l10n.loginToRegister),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
