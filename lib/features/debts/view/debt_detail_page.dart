import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/app/theme/spacing.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/features/debts/bloc/debt_actions_cubit.dart';
import 'package:geuralunas/features/debts/bloc/debt_detail_cubit.dart';
import 'package:geuralunas/features/debts/widgets/debt_status.dart';
import 'package:geuralunas/features/payments/view/settled_celebration.dart';
import 'package:geuralunas/l10n/l10n.dart';
import 'package:geuralunas/repositories/debt_repository.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';
import 'package:geuralunas/shared/widgets/confirm_dialog.dart';
import 'package:geuralunas/shared/widgets/money_text.dart';
import 'package:geuralunas/shared/widgets/progress_bar.dart';
import 'package:geuralunas/shared/widgets/status_chip.dart';
import 'package:go_router/go_router.dart';

/// One debt: remaining amount, schedule and payment history.
class DebtDetailPage extends StatelessWidget {
  /// Creates the page for the debt with [debtId].
  const DebtDetailPage({required this.debtId, super.key});

  /// Id of the debt to show.
  final String debtId;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<DebtRepository>();
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => DebtDetailCubit(repository, debtId)..start(),
        ),
        BlocProvider(create: (context) => DebtActionsCubit(repository, debtId)),
      ],
      child: _DebtDetailView(debtId: debtId),
    );
  }
}

class _DebtDetailView extends StatelessWidget {
  const _DebtDetailView({required this.debtId});

  final String debtId;

  void _onActionResult(BuildContext context, DebtActionsState state) {
    final l10n = context.l10n;
    if (state.status == ActionStatus.failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.actionFailed)),
      );
      return;
    }
    switch (state.action) {
      case DebtAction.markSettled:
        final debt = context.read<DebtDetailCubit>().state.debt;
        unawaited(
          showSettledCelebration(
            context,
            isOwe: debt?.direction != DebtDirection.lent,
          ),
        );
      case DebtAction.archive || DebtAction.unarchive || DebtAction.delete:
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/debts');
        }
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocListener<DebtActionsCubit, DebtActionsState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          (current.status == ActionStatus.done ||
              current.status == ActionStatus.failure),
      listener: _onActionResult,
      child: BlocBuilder<DebtDetailCubit, DebtDetailState>(
        builder: (context, state) {
          final debt = state.debt;
          return Scaffold(
            key: const Key('debt-detail-page'),
            appBar: AppBar(
              title: Text(debt?.counterpartyName ?? ''),
              actions: [
                if (debt != null)
                  PopupMenuButton<_MenuAction>(
                    key: const Key('detail-menu'),
                    tooltip: l10n.detailMenu,
                    onSelected: (action) => unawaited(
                      _handleMenu(context, action, debt),
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: _MenuAction.edit,
                        child: Text(l10n.detailEdit),
                      ),
                      if (debt.status == DebtStatus.active)
                        PopupMenuItem(
                          value: _MenuAction.settle,
                          child: Text(l10n.detailMenuSettle),
                        ),
                      if (debt.status != DebtStatus.archived)
                        PopupMenuItem(
                          value: _MenuAction.archive,
                          child: Text(l10n.detailMenuArchive),
                        ),
                      PopupMenuItem(
                        value: _MenuAction.delete,
                        child: Text(l10n.detailMenuDelete),
                      ),
                    ],
                  ),
              ],
            ),
            body: switch (state.status) {
              DebtDetailStatus.loading => const Center(
                child: CircularProgressIndicator(),
              ),
              DebtDetailStatus.failure => _Message(
                text: l10n.debtsLoadError,
                messageKey: const Key('detail-error'),
              ),
              DebtDetailStatus.notFound => _Message(
                text: l10n.formNotFound,
                messageKey: const Key('detail-not-found'),
              ),
              DebtDetailStatus.loaded => _Content(state: state, debt: debt!),
            },
          );
        },
      ),
    );
  }

  Future<void> _handleMenu(
    BuildContext context,
    _MenuAction action,
    Debt debt,
  ) async {
    final l10n = context.l10n;
    final actions = context.read<DebtActionsCubit>();
    switch (action) {
      case _MenuAction.edit:
        await context.push('/debts/$debtId/edit');
      case _MenuAction.settle:
        final ok = await ConfirmDialog.show(
          context,
          title: l10n.actionSettleTitle,
          body: l10n.actionSettleBody(formatRupiah(debt.remaining)),
          confirmLabel: l10n.actionSettleConfirm,
        );
        if (ok) await actions.markSettled();
      case _MenuAction.archive:
        final ok = await ConfirmDialog.show(
          context,
          title: l10n.actionArchiveTitle,
          body: l10n.actionArchiveBody,
          confirmLabel: l10n.actionArchiveConfirm,
        );
        if (ok) await actions.archive();
      case _MenuAction.delete:
        final ok = await ConfirmDialog.show(
          context,
          title: l10n.actionDeleteTitle,
          body: l10n.actionDeleteBody,
          confirmLabel: l10n.actionDeleteConfirm,
        );
        if (ok) await actions.delete();
    }
  }
}

enum _MenuAction { edit, settle, archive, delete }

Future<void> _confirmDelete(BuildContext context, String paymentId) async {
  final l10n = context.l10n;
  final cubit = context.read<DebtDetailCubit>();
  final messenger = ScaffoldMessenger.of(context);
  final confirmed = await ConfirmDialog.show(
    context,
    title: l10n.paymentDeleteTitle,
    body: l10n.paymentDeleteBody,
    confirmLabel: l10n.paymentDeleteConfirm,
  );
  if (!confirmed) return;
  final done = await cubit.deletePayment(paymentId);
  if (!done) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.paymentDeleteFailed)));
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.messageKey});

  final String text;
  final Key messageKey;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Text(text, key: messageKey, textAlign: TextAlign.center),
    ),
  );
}

class _Content extends StatelessWidget {
  const _Content({required this.state, required this.debt});

  final DebtDetailState state;
  final Debt debt;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isOwe = debt.direction == DebtDirection.owe;
    final kind = switch (debt.kind) {
      DebtKind.pinjol => l10n.detailKindPinjol,
      DebtKind.installment => l10n.detailKindInstallment,
      DebtKind.personal => l10n.detailKindPersonal,
    };
    final direction = isOwe
        ? l10n.detailDirectionOwe
        : l10n.detailDirectionLent;
    final paid = formatRupiah(debt.paidTotal);
    final total = formatRupiah(debt.totalPayable);
    final settled = debt.status == DebtStatus.settled;

    return ListView(
      padding: const EdgeInsets.all(Spacing.md),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(Spacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.counterpartyName,
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  l10n.detailKindDirection(kind, direction),
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: Spacing.sm),
                StatusChip(statusKindOf(debt, DateTime.now())),
                const SizedBox(height: Spacing.md),
                Text(
                  isOwe ? l10n.detailRemainingOwe : l10n.detailRemainingLent,
                  style: theme.textTheme.bodyMedium,
                ),
                MoneyText(
                  debt.remaining,
                  style: theme.textTheme.headlineLarge,
                ),
                const SizedBox(height: Spacing.md),
                Semantics(
                  container: true,
                  label: l10n.detailProgressSemantics(paid, total),
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProgressBar(value: state.progress),
                      const SizedBox(height: Spacing.xs),
                      Text(l10n.detailPaidOf(paid, total)),
                    ],
                  ),
                ),
                if (settled) ...[
                  const SizedBox(height: Spacing.md),
                  Text(
                    isOwe ? l10n.detailSettledOwe : l10n.detailSettledLent,
                    key: const Key('detail-settled'),
                    style: theme.textTheme.titleMedium,
                  ),
                ] else if (debt.status == DebtStatus.active) ...[
                  const SizedBox(height: Spacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      key: const Key('detail-pay'),
                      onPressed: () => context.push('/debts/${debt.id}/pay'),
                      child: Text(
                        isOwe ? l10n.detailPayOwe : l10n.detailPayLent,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: Spacing.md),
        Text(l10n.detailScheduleTitle, style: theme.textTheme.titleMedium),
        if (state.installments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            child: Text(l10n.detailNoSchedule),
          )
        else
          for (final installment in state.installments)
            _InstallmentTile(installment: installment),
        const SizedBox(height: Spacing.md),
        Text(
          isOwe ? l10n.detailPaymentsOwe : l10n.detailPaymentsLent,
          style: theme.textTheme.titleMedium,
        ),
        if (state.payments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            child: Text(l10n.detailNoPayments),
          )
        else
          for (final payment in state.payments.reversed)
            _PaymentTile(
              payment: payment,
              onDelete: () => _confirmDelete(context, payment.id),
            ),
      ],
    );
  }
}

class _InstallmentTile extends StatelessWidget {
  const _InstallmentTile({required this.installment});

  final Installment installment;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (icon, status) = switch (installment.status) {
      InstallmentStatus.paid => (
        Icons.check_circle_outline,
        l10n.installmentPaid,
      ),
      InstallmentStatus.partial => (
        Icons.timelapse,
        l10n.installmentPartial(
          formatRupiah(installment.paidAmount),
          formatRupiah(installment.amount),
        ),
      ),
      InstallmentStatus.pending => (
        Icons.circle_outlined,
        l10n.installmentPending,
      ),
    };
    return ListTile(
      key: Key('installment-${installment.seq}'),
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(l10n.installmentTitle(installment.seq)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.installmentDue(formatDate(installment.dueDate))),
          Text(status, key: Key('installment-${installment.seq}-status')),
        ],
      ),
      trailing: MoneyText(installment.amount),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({required this.payment, required this.onDelete});

  final Payment payment;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final note = payment.note;
    return ListTile(
      key: Key('payment-${payment.id}'),
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.payments_outlined),
      trailing: IconButton(
        key: Key('payment-delete-${payment.id}'),
        tooltip: context.l10n.paymentDeleteTooltip,
        icon: const Icon(Icons.delete_outline),
        onPressed: onDelete,
      ),
      title: MoneyText(payment.amount),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(formatDate(payment.paidAt)),
          if (note != null) Text(note),
        ],
      ),
    );
  }
}
