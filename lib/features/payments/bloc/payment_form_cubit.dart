import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/debt/payments.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/features/auth/bloc/submit_status.dart';
import 'package:geuralunas/repositories/debt_repository.dart';
import 'package:geuralunas/shared/parse_amount.dart';

/// Why the amount or date is not acceptable.
enum PaymentFormError { invalidAmount, exceedsRemaining, futureDate }

/// Why saving failed.
enum PaymentFormFailure { unknown, exceedsRemaining }

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

final class PaymentFormState extends Equatable {
  const PaymentFormState({
    required this.amount,
    required this.date,
    required this.today,
    required this.remaining,
    this.note = '',
    this.installmentSeq,
    this.status = SubmitStatus.idle,
    this.failure,
    this.showErrors = false,
    this.settled = false,
    this.remainingAfter,
  });

  /// As typed, for example `300.000`.
  final String amount;
  final DateTime date;
  final DateTime today;

  /// What is still owed before this payment.
  final Money remaining;
  final String note;
  final int? installmentSeq;
  final SubmitStatus status;
  final PaymentFormFailure? failure;
  final bool showErrors;

  /// After a successful save: this payment paid everything off.
  final bool settled;

  /// After a successful save: what is left.
  final Money? remainingAfter;

  Money? get amountValue => parseAmount(amount);

  PaymentFormError? get amountError {
    final value = amountValue;
    if (value == null) return PaymentFormError.invalidAmount;
    if (value.rupiah > remaining.rupiah) {
      return PaymentFormError.exceedsRemaining;
    }
    return null;
  }

  PaymentFormError? get dateError => _dateOnly(date).isAfter(_dateOnly(today))
      ? PaymentFormError.futureDate
      : null;

  PaymentFormState copyWith({
    String? amount,
    DateTime? date,
    String? note,
    int? installmentSeq,
    bool clearInstallmentSeq = false,
    SubmitStatus? status,
    PaymentFormFailure? failure,
    bool clearFailure = false,
    bool? showErrors,
    bool? settled,
    Money? remainingAfter,
  }) => PaymentFormState(
    amount: amount ?? this.amount,
    date: date ?? this.date,
    today: today,
    remaining: remaining,
    note: note ?? this.note,
    installmentSeq: clearInstallmentSeq
        ? null
        : installmentSeq ?? this.installmentSeq,
    status: status ?? this.status,
    failure: clearFailure ? null : failure ?? this.failure,
    showErrors: showErrors ?? this.showErrors,
    settled: settled ?? this.settled,
    remainingAfter: remainingAfter ?? this.remainingAfter,
  );

  @override
  List<Object?> get props => [
    amount,
    date,
    today,
    remaining,
    note,
    installmentSeq,
    status,
    failure,
    showErrors,
    settled,
    remainingAfter,
  ];
}

class PaymentFormCubit extends Cubit<PaymentFormState> {
  PaymentFormCubit(
    this._repository, {
    required Debt debt,
    required List<Installment> installments,
    DateTime Function()? now,
  }) : _debt = debt,
       _installments = installments,
       super(_initial(debt, installments, _dateOnly((now ?? DateTime.now)())));

  final DebtRepository _repository;
  final Debt _debt;
  final List<Installment> _installments;

  /// The installment a payment most likely belongs to: the earliest due one
  /// that is not fully paid.
  static Installment? _nearestUnpaid(List<Installment> installments) {
    Installment? best;
    for (final i in installments) {
      if (i.status == InstallmentStatus.paid) continue;
      if (best == null ||
          i.dueDate.isBefore(best.dueDate) ||
          (i.dueDate == best.dueDate && i.seq < best.seq)) {
        best = i;
      }
    }
    return best;
  }

  static int _remainderOf(Installment i, Money limit) {
    final left = i.amount.rupiah - i.paidAmount.rupiah;
    return left < limit.rupiah ? left : limit.rupiah;
  }

  static PaymentFormState _initial(
    Debt debt,
    List<Installment> installments,
    DateTime today,
  ) {
    final nearest = _nearestUnpaid(installments);
    return PaymentFormState(
      amount:
          (nearest == null
                  ? debt.remaining.rupiah
                  : _remainderOf(nearest, debt.remaining))
              .toString(),
      installmentSeq: nearest?.seq,
      date: today,
      today: today,
      remaining: debt.remaining,
    );
  }

  /// The screen can be closed while a save is in flight; a late result must
  /// not throw.
  @override
  void emit(PaymentFormState state) {
    if (!isClosed) super.emit(state);
  }

  void amountChanged(String value) => emit(state.copyWith(amount: value));

  void dateChanged(DateTime value) =>
      emit(state.copyWith(date: _dateOnly(value)));

  void noteChanged(String value) => emit(state.copyWith(note: value));

  /// Picks the installment this payment is for, or `null` for automatic.
  void installmentSelected(int? seq) {
    if (seq == null) {
      emit(state.copyWith(clearInstallmentSeq: true));
      return;
    }
    final chosen = _installments.where((i) => i.seq == seq).firstOrNull;
    emit(
      state.copyWith(
        installmentSeq: seq,
        amount: chosen == null
            ? null
            : _remainderOf(chosen, _debt.remaining).toString(),
      ),
    );
  }

  Future<void> submit() async {
    if (state.status == SubmitStatus.submitting) return;
    final amount = state.amountValue;
    if (state.amountError != null ||
        state.dateError != null ||
        amount == null) {
      emit(state.copyWith(showErrors: true));
      return;
    }
    emit(state.copyWith(status: SubmitStatus.submitting, clearFailure: true));
    try {
      final note = state.note.trim();
      await _repository.recordPayment(
        debtId: _debt.id,
        amount: amount,
        paidAt: state.date,
        installmentSeq: state.installmentSeq,
        note: note.isEmpty ? null : note,
      );
      final after = Money(_debt.remaining.rupiah - amount.rupiah);
      emit(
        state.copyWith(
          status: SubmitStatus.success,
          remainingAfter: after,
          settled: after.isZero,
        ),
      );
    } on PaymentExceedsRemaining {
      emit(
        state.copyWith(
          status: SubmitStatus.failure,
          failure: PaymentFormFailure.exceedsRemaining,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          status: SubmitStatus.failure,
          failure: PaymentFormFailure.unknown,
        ),
      );
    }
  }
}
