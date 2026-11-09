import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/debt/schedule.dart';
import 'package:geuralunas/domain/money.dart';

/// Why a payment could not be applied.
sealed class PaymentError implements Exception {
  const PaymentError();
}

/// The amount is zero or negative.
final class InvalidPaymentAmount extends PaymentError {
  const InvalidPaymentAmount();
}

/// The payment is larger than what is still owed.
final class PaymentExceedsRemaining extends PaymentError {
  const PaymentExceedsRemaining({required this.remaining});

  /// What is still owed at that point.
  final Money remaining;
}

/// The payment points at an installment that does not exist.
final class UnknownInstallment extends PaymentError {
  const UnknownInstallment({required this.seq});

  final int seq;
}

/// A debt together with its installments.
final class DebtState extends Equatable {
  const DebtState({required this.debt, required this.installments});

  final Debt debt;
  final List<Installment> installments;

  @override
  List<Object?> get props => [debt, installments];
}

int _byTime(Payment a, Payment b) {
  final epoch = DateTime.fromMillisecondsSinceEpoch(0);
  final byPaid = a.paidAt.compareTo(b.paidAt);
  if (byPaid != 0) return byPaid;
  final byCreated = (a.createdAt ?? epoch).compareTo(b.createdAt ?? epoch);
  if (byCreated != 0) return byCreated;
  return a.id.compareTo(b.id);
}

/// Rebuilds the state from zero by applying [payments] in time order.
///
/// Whatever paid amounts [installments] already hold are ignored. A payment
/// with an `installmentSeq` fills that installment first; anything left (and
/// every payment without a seq) fills the earliest unpaid installments.
/// Applying and reverting both go through here, so reverting a payment gives
/// exactly the state that never had it.
DebtState replayPayments({
  required Debt debt,
  required List<Installment> installments,
  required List<Payment> payments,
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final total = debt.totalPayable.rupiah;
  final count = installments.length;

  final order = List<int>.generate(count, (i) => i)
    ..sort((a, b) => installments[a].seq.compareTo(installments[b].seq));
  final paid = List<int>.filled(count, 0);
  final paidAt = List<DateTime?>.filled(count, null);

  int fill(int index, int left, DateTime at) {
    final room = installments[index].amount.rupiah - paid[index];
    final take = math.min(room, left);
    if (take <= 0) return left;
    paid[index] += take;
    if (paid[index] == installments[index].amount.rupiah) paidAt[index] = at;
    return left - take;
  }

  var running = 0;
  for (final p in [...payments]..sort(_byTime)) {
    final amount = p.amount.rupiah;
    if (amount <= 0) throw const InvalidPaymentAmount();
    if (amount > total - running) {
      throw PaymentExceedsRemaining(remaining: Money(total - running));
    }
    running += amount;
    if (count == 0) continue;

    var left = amount;
    final seq = p.installmentSeq;
    if (seq != null) {
      // A stored payment may point at an installment that an edit removed;
      // it then falls back to the earliest unpaid ones like any other.
      final target = installments.indexWhere((i) => i.seq == seq);
      if (target >= 0) left = fill(target, left, p.paidAt);
    }
    for (final index in order) {
      if (left == 0) break;
      left = fill(index, left, p.paidAt);
    }
  }

  final rebuilt = [
    for (var i = 0; i < count; i++)
      installments[i].copyWith(
        paidAmount: Money(paid[i]),
        status: paid[i] == 0
            ? InstallmentStatus.pending
            : paid[i] == installments[i].amount.rupiah
            ? InstallmentStatus.paid
            : InstallmentStatus.partial,
        paidAt: paidAt[i],
        clearPaidAt: paidAt[i] == null,
      ),
  ];

  final remaining = Money(math.max(0, total - running));
  var status = debt.status;
  var settledAt = debt.settledAt;
  var clearSettledAt = false;
  if (status != DebtStatus.archived) {
    if (remaining.isZero) {
      if (status == DebtStatus.active) {
        status = DebtStatus.settled;
        settledAt = clock;
      } else {
        settledAt ??= clock;
      }
    } else if (status == DebtStatus.settled) {
      status = DebtStatus.active;
      clearSettledAt = true;
    }
  }

  final DateTime? due;
  if (remaining.isZero) {
    due = null;
  } else if (count > 0) {
    due = nextDueDate(rebuilt);
  } else {
    due = debt.nextDueDate;
  }

  return DebtState(
    debt: debt.copyWith(
      paidTotal: Money(running),
      remaining: remaining,
      status: status,
      settledAt: settledAt,
      clearSettledAt: clearSettledAt,
      nextDueDate: due,
      clearNextDueDate: due == null,
    ),
    installments: rebuilt,
  );
}

/// Applies [payment] on top of [existing] payments.
///
/// Throws [InvalidPaymentAmount], [PaymentExceedsRemaining] or
/// [UnknownInstallment].
DebtState applyPayment({
  required DebtState state,
  required List<Payment> existing,
  required Payment payment,
  DateTime? now,
}) {
  if (payment.amount.rupiah <= 0) throw const InvalidPaymentAmount();
  if (payment.amount.rupiah > state.debt.remaining.rupiah) {
    throw PaymentExceedsRemaining(remaining: state.debt.remaining);
  }
  final seq = payment.installmentSeq;
  if (seq != null &&
      state.installments.isNotEmpty &&
      !state.installments.any((i) => i.seq == seq)) {
    throw UnknownInstallment(seq: seq);
  }
  return replayPayments(
    debt: state.debt,
    installments: state.installments,
    payments: [...existing, payment],
    now: now,
  );
}

/// Removes the payment with [paymentId] and returns the state without it.
DebtState revertPayment({
  required DebtState state,
  required List<Payment> existing,
  required String paymentId,
  DateTime? now,
}) {
  if (!existing.any((p) => p.id == paymentId)) {
    throw ArgumentError.value(paymentId, 'paymentId', 'no such payment');
  }
  return replayPayments(
    debt: state.debt,
    installments: state.installments,
    payments: existing.where((p) => p.id != paymentId).toList(),
    now: now,
  );
}
