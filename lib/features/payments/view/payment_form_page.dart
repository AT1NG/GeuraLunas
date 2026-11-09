import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/app/theme/spacing.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/features/auth/bloc/submit_status.dart';
import 'package:geuralunas/features/payments/bloc/payment_form_cubit.dart';
import 'package:geuralunas/features/payments/view/settled_celebration.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/debt_repository.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';
import 'package:geuralunas/shared/parse_amount.dart';
import 'package:geuralunas/shared/widgets/amount_field.dart';
import 'package:geuralunas/shared/widgets/submit_button.dart';
import 'package:go_router/go_router.dart';

/// Records a payment (or, for a receivable, a received payment).
class PaymentFormPage extends StatefulWidget {
  /// Creates the form for the debt with [debtId].
  const PaymentFormPage({required this.debtId, super.key});

  /// The debt being paid.
  final String debtId;

  @override
  State<PaymentFormPage> createState() => _PaymentFormPageState();
}

typedef _Loaded = (Debt?, List<Installment>);

class _PaymentFormPageState extends State<PaymentFormPage> {
  late final Future<_Loaded> _loading;

  @override
  void initState() {
    super.initState();
    final repo = context.read<DebtRepository>();
    _loading = () async {
      final debt = await repo.watchDebt(widget.debtId).first;
      final installments = await repo.watchInstallments(widget.debtId).first;
      return (debt, installments);
    }();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_Loaded>(
      future: _loading,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data;
        final debt = data?.$1;
        final installments = data?.$2 ?? const <Installment>[];
        if (debt == null ||
            debt.status != DebtStatus.active ||
            debt.remaining.isZero) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Text(
                  context.l10n.payUnavailable,
                  key: const Key('pay-not-found'),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return BlocProvider(
          create: (context) => PaymentFormCubit(
            context.read<DebtRepository>(),
            debt: debt,
            installments: installments,
          ),
          child: _PaymentFormView(debt: debt, installments: installments),
        );
      },
    );
  }
}

class _PaymentFormView extends StatefulWidget {
  const _PaymentFormView({required this.debt, required this.installments});

  final Debt debt;
  final List<Installment> installments;

  @override
  State<_PaymentFormView> createState() => _PaymentFormViewState();
}

class _PaymentFormViewState extends State<_PaymentFormView> {
  late final TextEditingController _amount;
  late final TextEditingController _note;

  @override
  void initState() {
    super.initState();
    final s = context.read<PaymentFormCubit>().state;
    _amount = TextEditingController(text: formatThousands(s.amount));
    _note = TextEditingController(text: s.note);
  }

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _onSuccess(PaymentFormState state) async {
    final l10n = context.l10n;
    final router = GoRouter.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final isOwe = widget.debt.direction == DebtDirection.owe;
    if (state.settled) {
      await showSettledCelebration(context, isOwe: isOwe);
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.paySaved(formatRupiah(state.remainingAfter!))),
        ),
      );
    }
    if (router.canPop()) {
      router.pop();
    } else {
      router.go('/debts/${widget.debt.id}');
    }
  }

  String? _amountError(PaymentFormState state) {
    final error = state.amountError;
    if (error == null) return null;
    if (error != PaymentFormError.exceedsRemaining && !state.showErrors) {
      return null;
    }
    final l10n = context.l10n;
    return switch (error) {
      PaymentFormError.invalidAmount => l10n.payErrorAmount,
      PaymentFormError.exceedsRemaining => l10n.payErrorExceeds(
        formatRupiah(state.remaining),
      ),
      PaymentFormError.futureDate => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<PaymentFormCubit>();
    final debt = widget.debt;
    final isOwe = debt.direction == DebtDirection.owe;
    final unpaid = widget.installments
        .where((i) => i.status != InstallmentStatus.paid)
        .toList();

    return BlocConsumer<PaymentFormCubit, PaymentFormState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == SubmitStatus.success,
      listener: (context, state) => unawaited(_onSuccess(state)),
      builder: (context, state) {
        final theme = Theme.of(context);
        return Scaffold(
          key: const Key('payment-form-page'),
          appBar: AppBar(
            title: Text(isOwe ? l10n.payTitleOwe : l10n.payTitleLent),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    debt.counterpartyName,
                    style: theme.textTheme.titleLarge,
                  ),
                  Text(
                    isOwe
                        ? l10n.payDirectionOwe
                        : l10n.payDirectionLent(debt.counterpartyName),
                  ),
                  const SizedBox(height: Spacing.xs),
                  Text(
                    l10n.payRemainingNow(formatRupiah(state.remaining)),
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: Spacing.lg),
                  AmountField(
                    fieldKey: const Key('pay-amount'),
                    controller: _amount,
                    label: l10n.payAmount,
                    onChanged: cubit.amountChanged,
                    errorText: _amountError(state),
                  ),
                  const SizedBox(height: Spacing.md),
                  ListTile(
                    key: const Key('pay-date'),
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event),
                    title: Text(l10n.payDate),
                    subtitle: Text(
                      state.dateError != null && state.showErrors
                          ? l10n.payErrorFuture
                          : formatDate(state.date),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: state.date,
                        firstDate: DateTime(2000),
                        lastDate: state.today,
                      );
                      if (picked != null) cubit.dateChanged(picked);
                    },
                  ),
                  if (unpaid.isNotEmpty) ...[
                    const SizedBox(height: Spacing.sm),
                    DropdownButtonFormField<int?>(
                      key: const Key('pay-installment'),
                      isExpanded: true,
                      initialValue: state.installmentSeq,
                      decoration: InputDecoration(
                        labelText: l10n.payInstallment,
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem<int?>(
                          child: Text(l10n.payInstallmentAuto),
                        ),
                        for (final i in unpaid)
                          DropdownMenuItem<int?>(
                            value: i.seq,
                            child: Text(
                              l10n.payInstallmentOption(
                                i.seq,
                                formatRupiah(i.amount - i.paidAmount),
                              ),
                            ),
                          ),
                      ],
                      onChanged: (seq) {
                        cubit.installmentSelected(seq);
                        _amount.text = formatThousands(cubit.state.amount);
                      },
                    ),
                  ],
                  const SizedBox(height: Spacing.md),
                  TextField(
                    key: const Key('pay-note'),
                    controller: _note,
                    maxLines: 3,
                    minLines: 1,
                    maxLength: 500,
                    onChanged: cubit.noteChanged,
                    decoration: InputDecoration(
                      labelText: l10n.payNote,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),
                  if (state.failure != null) ...[
                    Container(
                      key: const Key('pay-error'),
                      padding: const EdgeInsets.all(Spacing.md),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(Spacing.md),
                      ),
                      child: Text(
                        state.failure == PaymentFormFailure.exceedsRemaining
                            ? l10n.payErrorExceeds(
                                formatRupiah(state.remaining),
                              )
                            : l10n.payFailed,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: Spacing.md),
                  ],
                  SubmitButton(
                    key: const Key('pay-submit'),
                    label: l10n.paySubmit,
                    busy: state.status == SubmitStatus.submitting,
                    onPressed: cubit.submit,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
