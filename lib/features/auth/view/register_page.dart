import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/app/theme/spacing.dart';
import 'package:geuralunas/features/auth/bloc/register_cubit.dart';
import 'package:geuralunas/features/auth/bloc/submit_status.dart';
import 'package:geuralunas/features/auth/view/auth_widgets.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/auth_repository.dart';
import 'package:go_router/go_router.dart';

/// Email/password sign-up screen.
class RegisterPage extends StatelessWidget {
  /// Creates the register page.
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegisterCubit(context.read<AuthRepository>()),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatelessWidget {
  const _RegisterView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<RegisterCubit>();
    return Scaffold(
      key: const Key('register-page'),
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: BlocBuilder<RegisterCubit, RegisterState>(
            builder: (context, state) {
              final busy = state.status == SubmitStatus.submitting;
              final nameError = state.showErrors ? state.nameError : null;
              final emailError = state.showErrors ? state.emailError : null;
              final passwordError = state.showErrors
                  ? state.passwordError
                  : null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.registerTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(l10n.registerSubtitle),
                  const SizedBox(height: Spacing.lg),
                  TextField(
                    key: const Key('register-name'),
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    onChanged: cubit.nameChanged,
                    decoration: InputDecoration(
                      labelText: l10n.authName,
                      errorText: nameError == null
                          ? null
                          : l10n.validationText(nameError),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  TextField(
                    key: const Key('register-email'),
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
                    fieldKey: const Key('register-password'),
                    onChanged: cubit.passwordChanged,
                    errorText: passwordError == null
                        ? null
                        : l10n.validationText(passwordError),
                  ),
                  const SizedBox(height: Spacing.lg),
                  if (state.failure != null) ...[
                    AuthErrorBanner(message: l10n.failureText(state.failure!)),
                    const SizedBox(height: Spacing.md),
                  ],
                  SubmitButton(
                    key: const Key('register-submit'),
                    label: l10n.registerSubmit,
                    busy: busy,
                    onPressed: cubit.submit,
                  ),
                  const SizedBox(height: Spacing.lg),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(l10n.registerHaveAccount),
                      TextButton(
                        onPressed: () => context.canPop()
                            ? context.pop()
                            : context.go('/login'),
                        child: Text(l10n.registerToLogin),
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
