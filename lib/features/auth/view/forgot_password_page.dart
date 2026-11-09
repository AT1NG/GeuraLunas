import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/app/theme/spacing.dart';
import 'package:geuralunas/features/auth/bloc/forgot_password_cubit.dart';
import 'package:geuralunas/features/auth/bloc/submit_status.dart';
import 'package:geuralunas/features/auth/view/auth_widgets.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/auth_repository.dart';

/// Sends a password-reset email.
class ForgotPasswordPage extends StatelessWidget {
  /// Creates the forgot-password page.
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ForgotPasswordCubit(context.read<AuthRepository>()),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatelessWidget {
  const _ForgotPasswordView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ForgotPasswordCubit>();
    return Scaffold(
      key: const Key('forgot-password-page'),
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: BlocBuilder<ForgotPasswordCubit, ForgotPasswordState>(
            builder: (context, state) {
              final busy = state.status == SubmitStatus.submitting;
              final emailError = state.showErrors ? state.emailError : null;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.forgotTitle,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: Spacing.sm),
                  Text(l10n.forgotBody),
                  const SizedBox(height: Spacing.lg),
                  TextField(
                    key: const Key('forgot-email'),
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
                  const SizedBox(height: Spacing.lg),
                  if (state.status == SubmitStatus.success) ...[
                    Container(
                      key: const Key('forgot-sent'),
                      padding: const EdgeInsets.all(Spacing.md),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(l10n.forgotSent),
                    ),
                    const SizedBox(height: Spacing.md),
                  ],
                  if (state.failure != null) ...[
                    AuthErrorBanner(message: l10n.failureText(state.failure!)),
                    const SizedBox(height: Spacing.md),
                  ],
                  SubmitButton(
                    key: const Key('forgot-submit'),
                    label: l10n.forgotSubmit,
                    busy: busy,
                    onPressed: cubit.submit,
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
