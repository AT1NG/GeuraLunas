import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/repositories/debt_repository.dart';

/// Loading state of the detail screen.
enum DebtDetailStatus { loading, loaded, notFound, failure }

final class DebtDetailState extends Equatable {
  const DebtDetailState({
    this.debt,
    this.installments = const [],
    this.payments = const [],
    this.status = DebtDetailStatus.loading,
  });

  final Debt? debt;

  /// Ordered by installment number.
  final List<Installment> installments;

  /// Ordered by payment date, oldest first.
  final List<Payment> payments;
  final DebtDetailStatus status;

  /// Fraction paid, 0..1; 0 while loading or when the total is 0.
  double get progress {
    final d = debt;
    if (d == null || d.totalPayable.rupiah <= 0) return 0;
    return (d.paidTotal.rupiah / d.totalPayable.rupiah).clamp(0, 1);
  }

  DebtDetailState copyWith({
    Debt? debt,
    List<Installment>? installments,
    List<Payment>? payments,
    DebtDetailStatus? status,
    bool clearDebt = false,
  }) => DebtDetailState(
    debt: clearDebt ? null : debt ?? this.debt,
    installments: installments ?? this.installments,
    payments: payments ?? this.payments,
    status: status ?? this.status,
  );

  @override
  List<Object?> get props => [debt, installments, payments, status];
}

class DebtDetailCubit extends Cubit<DebtDetailState> {
  DebtDetailCubit(this._repository, this._debtId)
    : super(const DebtDetailState());

  final DebtRepository _repository;
  final String _debtId;
  final _subscriptions = <StreamSubscription<Object?>>[];

  /// Starts listening to the debt, its installments and its payments.
  void start() {
    unawaited(_cancel());
    _subscriptions
      ..add(
        _repository
            .watchDebt(_debtId)
            .listen(_onDebt, onError: (Object _) => _fail()),
      )
      ..add(
        _repository
            .watchInstallments(_debtId)
            .listen(
              (list) => emit(
                state.copyWith(
                  installments: [...list]
                    ..sort((a, b) => a.seq.compareTo(b.seq)),
                ),
              ),
              onError: (Object _) => _fail(),
            ),
      )
      ..add(
        _repository
            .watchPayments(_debtId)
            .listen(
              (list) => emit(state.copyWith(payments: _byDate(list))),
              onError: (Object _) => _fail(),
            ),
      );
  }

  /// Oldest first, whatever order the repository delivers.
  static List<Payment> _byDate(List<Payment> payments) {
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    return [...payments]..sort((a, b) {
      final byPaid = a.paidAt.compareTo(b.paidAt);
      if (byPaid != 0) return byPaid;
      return (a.createdAt ?? epoch).compareTo(b.createdAt ?? epoch);
    });
  }

  /// Removes a payment (and restores the debt). Returns `false` on failure.
  Future<bool> deletePayment(String paymentId) async {
    try {
      await _repository.deletePayment(debtId: _debtId, paymentId: paymentId);
      return true;
    } on Object {
      return false;
    }
  }

  void _onDebt(Debt? debt) {
    if (debt == null) {
      emit(state.copyWith(clearDebt: true, status: DebtDetailStatus.notFound));
    } else {
      emit(state.copyWith(debt: debt, status: DebtDetailStatus.loaded));
    }
  }

  void _fail() => emit(state.copyWith(status: DebtDetailStatus.failure));

  Future<void> _cancel() async {
    final all = List.of(_subscriptions);
    _subscriptions.clear();
    for (final s in all) {
      await s.cancel();
    }
  }

  @override
  Future<void> close() async {
    await _cancel();
    return super.close();
  }
}
