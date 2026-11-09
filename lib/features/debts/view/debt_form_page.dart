import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/app/theme/spacing.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/features/auth/bloc/submit_status.dart';
import 'package:geuralunas/features/debts/bloc/debt_form_cubit.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/debt_repository.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';
import 'package:geuralunas/shared/parse_amount.dart';
import 'package:geuralunas/shared/widgets/amount_field.dart';
import 'package:geuralunas/shared/widgets/money_text.dart';
import 'package:geuralunas/shared/widgets/submit_button.dart';
import 'package:go_router/go_router.dart';

/// Add a debt, or edit the one with [debtId].
class DebtFormPage extends StatefulWidget {
  /// Creates the form; pass [debtId] to edit.
  const DebtFormPage({this.debtId, super.key});

  /// The debt to edit, or `null` to add a new one.
  final String? debtId;

  @override
  State<DebtFormPage> createState() => _DebtFormPageState();
}

class _DebtFormPageState extends State<DebtFormPage> {
  Future<Debt?>? _loading;

  @override
  void initState() {
    super.initState();
    final id = widget.debtId;
    if (id != null) {
      _loading = context.read<DebtRepository>().watchDebt(id).first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = _loading;
    if (loading == null) return const _FormScope(editing: null);
    return FutureBuilder<Debt?>(
      future: loading,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        final debt = snapshot.data;
        if (debt == null) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(Spacing.lg),
                child: Text(
                  context.l10n.formNotFound,
                  key: const Key('form-not-found'),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        return _FormScope(editing: debt);
      },
    );
  }
}

class _FormScope extends StatelessWidget {
  const _FormScope({required this.editing});

  final Debt? editing;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          DebtFormCubit(context.read<DebtRepository>(), editing: editing),
      child: _DebtFormView(isEditing: editing != null),
    );
  }
}

class _DebtFormView extends StatefulWidget {
  const _DebtFormView({required this.isEditing});

  final bool isEditing;

  @override
  State<_DebtFormView> createState() => _DebtFormViewState();
}

class _DebtFormViewState extends State<_DebtFormView> {
  late final TextEditingController _name;
  late final TextEditingController _note;
  late final TextEditingController _principal;
  late final TextEditingController _rate;
  late final TextEditingController _adminFee;
  late final TextEditingController _tenor;

  @override
  void initState() {
    super.initState();
    final s = context.read<DebtFormCubit>().state;
    _name = TextEditingController(text: s.name);
    _note = TextEditingController(text: s.note);
    _principal = TextEditingController(text: formatThousands(s.principal));
    _rate = TextEditingController(text: s.interestRate);
    _adminFee = TextEditingController(text: formatThousands(s.adminFee));
    _tenor = TextEditingController(text: s.tenor);
  }

  @override
  void dispose() {
    for (final c in [_name, _note, _principal, _rate, _adminFee, _tenor]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<DateTime?> _pickDate(DateTime initial) => showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
  );

  String? _errorText(DebtFormState state, DebtFormField field) {
    final error = state.errors[field];
    if (error == null) return null;
    if (error != DebtFormError.belowPaid && !state.showErrors) return null;
    final l10n = context.l10n;
    return switch (error) {
      DebtFormError.required => l10n.validationRequired,
      DebtFormError.invalidAmount => l10n.formErrorAmount,
      DebtFormError.invalidNumber => l10n.formErrorNumber,
      DebtFormError.belowPaid => l10n.formErrorBelowPaid(
        formatRupiah(state.paidTotal),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<DebtFormCubit>();
    return BlocConsumer<DebtFormCubit, DebtFormState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == SubmitStatus.success,
      listener: (context, _) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/debts');
        }
      },
      builder: (context, state) {
        return Scaffold(
          key: const Key('debt-form-page'),
          appBar: AppBar(
            title: Text(
              widget.isEditing ? l10n.debtFormEditTitle : l10n.debtFormNewTitle,
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(Spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.isEditing && state.paidTotal.rupiah > 0) ...[
                    _Notice(
                      key: const Key('form-paid-warning'),
                      message: l10n.formPaidWarning,
                    ),
                    const SizedBox(height: Spacing.md),
                  ],
                  _Chips<DebtDirection>(
                    selected: state.direction,
                    onSelected: cubit.directionChanged,
                    options: [
                      (
                        DebtDirection.owe,
                        l10n.formDirectionOwe,
                        'direction-owe',
                      ),
                      (
                        DebtDirection.lent,
                        l10n.formDirectionLent,
                        'direction-lent',
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.md),
                  _Chips<DebtKind>(
                    selected: state.kind,
                    onSelected: (kind) {
                      if (kind == DebtKind.personal) {
                        _rate.clear();
                        _adminFee.clear();
                        _tenor.clear();
                      }
                      cubit.kindChanged(kind);
                    },
                    options: [
                      (DebtKind.pinjol, l10n.formKindPinjol, 'kind-pinjol'),
                      (
                        DebtKind.installment,
                        l10n.formKindInstallment,
                        'kind-installment',
                      ),
                      (
                        DebtKind.personal,
                        l10n.formKindPersonal,
                        'kind-personal',
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.md),
                  TextField(
                    key: const Key('form-name'),
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    maxLength: 100,
                    buildCounter:
                        (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) => null,
                    onChanged: cubit.nameChanged,
                    decoration: InputDecoration(
                      labelText: l10n.formName,
                      errorText: _errorText(state, DebtFormField.name),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: Spacing.md),
                  AmountField(
                    fieldKey: const Key('form-principal'),
                    controller: _principal,
                    label: l10n.formPrincipal,
                    onChanged: cubit.principalChanged,
                    errorText: _errorText(state, DebtFormField.principal),
                  ),
                  if (!state.isPersonal) ..._moneyTerms(state, cubit),
                  const SizedBox(height: Spacing.md),
                  _DateTile(
                    tileKey: const Key('form-start-date'),
                    label: l10n.formStartDate,
                    value: formatDate(state.startDate),
                    onTap: () async {
                      final picked = await _pickDate(state.startDate);
                      if (picked != null) cubit.startDateChanged(picked);
                    },
                  ),
                  _DateTile(
                    tileKey: const Key('form-first-due'),
                    label: l10n.formFirstDue,
                    value: state.firstDueDate == null
                        ? l10n.formFirstDueAuto
                        : formatDate(state.firstDueDate!),
                    onTap: () async {
                      final picked = await _pickDate(
                        state.firstDueDate ?? state.startDate,
                      );
                      if (picked != null) cubit.firstDueDateChanged(picked);
                    },
                    trailing: state.firstDueDate == null
                        ? null
                        : IconButton(
                            tooltip: l10n.formFirstDueClear,
                            icon: const Icon(Icons.close),
                            onPressed: () => cubit.firstDueDateChanged(null),
                          ),
                  ),
                  const SizedBox(height: Spacing.md),
                  TextField(
                    key: const Key('form-note'),
                    controller: _note,
                    maxLines: 3,
                    minLines: 1,
                    maxLength: 500,
                    onChanged: cubit.noteChanged,
                    decoration: InputDecoration(
                      labelText: l10n.formNote,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (state.plan != null) ...[
                    const SizedBox(height: Spacing.md),
                    _Preview(state: state),
                  ],
                  const SizedBox(height: Spacing.lg),
                  if (state.failure != null) ...[
                    _Notice(
                      key: const Key('form-error'),
                      isError: true,
                      message: state.failure == DebtFormFailure.belowPaid
                          ? l10n.formErrorBelowPaid(
                              formatRupiah(state.paidTotal),
                            )
                          : l10n.formSaveFailed,
                    ),
                    const SizedBox(height: Spacing.md),
                  ],
                  SubmitButton(
                    key: const Key('form-submit'),
                    label: widget.isEditing
                        ? l10n.formSubmitEdit
                        : l10n.formSubmitNew,
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

  List<Widget> _moneyTerms(DebtFormState state, DebtFormCubit cubit) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final interest = state.interestType;
    return [
      const SizedBox(height: Spacing.md),
      Text(l10n.formInterestTitle, style: theme.textTheme.titleSmall),
      const SizedBox(height: Spacing.sm),
      _Chips<InterestType>(
        selected: interest,
        onSelected: cubit.interestTypeChanged,
        options: [
          for (final (type, label) in [
            (InterestType.none, l10n.formInterestNone),
            (InterestType.flatMonthly, l10n.formInterestFlatMonthly),
            (InterestType.flatDaily, l10n.formInterestFlatDaily),
            (InterestType.reducingMonthly, l10n.formInterestReducing),
          ])
            (type, label, 'interest-${type.wire}'),
        ],
      ),
      if (interest != InterestType.none) ...[
        const SizedBox(height: Spacing.md),
        TextField(
          key: const Key('form-rate'),
          controller: _rate,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: cubit.rateChanged,
          decoration: InputDecoration(
            labelText: l10n.formRate,
            suffixText: '%',
            errorText: _errorText(state, DebtFormField.interestRate),
            border: const OutlineInputBorder(),
          ),
        ),
      ],
      const SizedBox(height: Spacing.md),
      AmountField(
        fieldKey: const Key('form-admin-fee'),
        controller: _adminFee,
        label: l10n.formAdminFee,
        onChanged: cubit.adminFeeChanged,
        errorText: _errorText(state, DebtFormField.adminFee),
      ),
      const SizedBox(height: Spacing.md),
      TextField(
        key: const Key('form-tenor'),
        controller: _tenor,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: cubit.tenorChanged,
        decoration: InputDecoration(
          labelText: interest == InterestType.flatDaily
              ? l10n.formTenorDays
              : l10n.formTenor,
          errorText: _errorText(state, DebtFormField.tenor),
          border: const OutlineInputBorder(),
        ),
      ),
      if (interest != InterestType.flatDaily && state.tenorValue != null) ...[
        const SizedBox(height: Spacing.md),
        Text(l10n.formFrequencyTitle, style: theme.textTheme.titleSmall),
        const SizedBox(height: Spacing.sm),
        _Chips<Frequency>(
          selected: state.frequency,
          onSelected: cubit.frequencyChanged,
          options: [
            (Frequency.monthly, l10n.formFrequencyMonthly, 'freq-monthly'),
            (Frequency.weekly, l10n.formFrequencyWeekly, 'freq-weekly'),
          ],
        ),
      ],
    ];
  }
}

class _Chips<T> extends StatelessWidget {
  const _Chips({
    required this.options,
    required this.selected,
    required this.onSelected,
  });

  final List<(T, String, String)> options;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Spacing.sm,
      runSpacing: Spacing.sm,
      children: [
        for (final (value, label, keyName) in options)
          ChoiceChip(
            key: Key(keyName),
            label: Text(label),
            selected: value == selected,
            onSelected: (_) => onSelected(value),
          ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  const _DateTile({
    required this.tileKey,
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  final Key tileKey;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      key: tileKey,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.event),
      title: Text(label),
      subtitle: Text(value),
      trailing: trailing,
      onTap: onTap,
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message, this.isError = false, super.key});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: isError ? scheme.errorContainer : scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(Spacing.md),
      ),
      child: Text(
        message,
        style: TextStyle(
          color: isError
              ? scheme.onErrorContainer
              : scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.state});

  final DebtFormState state;

  static const _maxRows = 12;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final plan = state.plan!;
    final shown = plan.installments.take(_maxRows).toList();
    final hidden = plan.installments.length - shown.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.formPreviewTitle, style: theme.textTheme.titleSmall),
            const SizedBox(height: Spacing.xs),
            Text(
              l10n.formPreviewTotal(formatRupiah(plan.totalPayable)),
              key: const Key('preview-total'),
              style: theme.textTheme.titleMedium,
            ),
            for (final installment in shown)
              ListTile(
                key: Key('preview-row-${installment.seq}'),
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.formPreviewRow(installment.seq)),
                subtitle: Text(formatDate(installment.dueDate)),
                trailing: MoneyText(installment.amount),
              ),
            if (hidden > 0) Text(l10n.formPreviewMore(hidden)),
          ],
        ),
      ),
    );
  }
}
