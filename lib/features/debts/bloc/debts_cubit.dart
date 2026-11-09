import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/repositories/debt_repository.dart';

/// Which debts the list shows.
enum DebtFilter { active, settled }

/// Loading state of the list.
enum DebtsStatus { loading, loaded, failure }

final class DebtsState extends Equatable {
  const DebtsState({
    this.owe = const [],
    this.lent = const [],
    this.oweRemaining = Money.zero,
    this.lentRemaining = Money.zero,
    this.filter = DebtFilter.active,
    this.status = DebtsStatus.loading,
  });

  /// Debts I owe (shown, sorted).
  final List<Debt> owe;

  /// Debts others owe me (shown, sorted).
  final List<Debt> lent;

  /// Sum of `remaining` over [owe].
  final Money oweRemaining;

  /// Sum of `remaining` over [lent].
  final Money lentRemaining;
  final DebtFilter filter;
  final DebtsStatus status;

  @override
  List<Object?> get props => [
    owe,
    lent,
    oweRemaining,
    lentRemaining,
    filter,
    status,
  ];
}

class DebtsCubit extends Cubit<DebtsState> {
  DebtsCubit(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(const DebtsState());

  final DebtRepository _repository;
  final DateTime Function() _now;
  StreamSubscription<List<Debt>>? _subscription;
  List<Debt> _all = const [];

  /// Starts listening to the repository.
  void start() {
    unawaited(_subscription?.cancel());
    _subscription = _repository.watchDebts().listen((debts) {
      _all = debts;
      _publish(status: DebtsStatus.loaded);
    }, onError: (Object _) => emit(_copy(status: DebtsStatus.failure)));
  }

  void setFilter(DebtFilter filter) => _publish(filter: filter);

  void _publish({DebtFilter? filter, DebtsStatus? status}) {
    final selected = filter ?? state.filter;
    final wanted = selected == DebtFilter.active
        ? DebtStatus.active
        : DebtStatus.settled;
    final today = _now();

    List<Debt> pick(DebtDirection direction) =>
        _all
            .where((d) => d.direction == direction && d.status == wanted)
            .toList()
          ..sort((a, b) => _compare(a, b, today));

    final owe = pick(DebtDirection.owe);
    final lent = pick(DebtDirection.lent);
    emit(
      DebtsState(
        owe: owe,
        lent: lent,
        oweRemaining: _sum(owe),
        lentRemaining: _sum(lent),
        filter: selected,
        status: status ?? state.status,
      ),
    );
  }

  DebtsState _copy({DebtsStatus? status}) => DebtsState(
    owe: state.owe,
    lent: state.lent,
    oweRemaining: state.oweRemaining,
    lentRemaining: state.lentRemaining,
    filter: state.filter,
    status: status ?? state.status,
  );

  static Money _sum(List<Debt> debts) =>
      debts.fold(Money.zero, (total, d) => total + d.remaining);

  /// Overdue first, then nearest due date (undated last), then name.
  static int _compare(Debt a, Debt b, DateTime today) {
    final aLate = a.isOverdue(today);
    final bLate = b.isOverdue(today);
    if (aLate != bLate) return aLate ? -1 : 1;
    final ad = a.nextDueDate;
    final bd = b.nextDueDate;
    if (ad != null && bd != null) {
      final byDate = ad.compareTo(bd);
      if (byDate != 0) return byDate;
    } else if (ad != null) {
      return -1;
    } else if (bd != null) {
      return 1;
    }
    return a.counterpartyName.toLowerCase().compareTo(
      b.counterpartyName.toLowerCase(),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
