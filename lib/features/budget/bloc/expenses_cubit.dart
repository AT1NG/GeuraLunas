import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/domain/budget/budget_cycle.dart';
import 'package:geuralunas/domain/budget/expense.dart';
import 'package:geuralunas/repositories/expense_repository.dart';

/// Loading state of the expense list.
enum ExpensesStatus { loading, loaded, failure }

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int _newestFirst(Expense a, Expense b) {
  final bySpent = b.spentAt.compareTo(a.spentAt);
  return bySpent != 0 ? bySpent : b.createdAt.compareTo(a.createdAt);
}

final class ExpensesState extends Equatable {
  const ExpensesState({
    this.status = ExpensesStatus.loading,
    this.expenses = const [],
    this.cycle,
  });

  final ExpensesStatus status;

  /// Expenses of [cycle], newest first.
  final List<Expense> expenses;
  final BudgetCycle? cycle;

  /// [expenses] grouped by day, newest day first.
  Map<DateTime, List<Expense>> get byDay {
    final days = <DateTime, List<Expense>>{};
    for (final e in expenses) {
      days.putIfAbsent(_dateOnly(e.spentAt), () => []).add(e);
    }
    return days;
  }

  @override
  List<Object?> get props => [status, expenses, cycle];
}

/// The expenses of the budget cycle that holds today.
class ExpensesCubit extends Cubit<ExpensesState> {
  ExpensesCubit(
    this._repository, {
    DateTime Function()? now,
    this.startDay = defaultBudgetCycleStartDay,
  }) : _now = now ?? DateTime.now,
       super(const ExpensesState());

  final ExpenseRepository _repository;
  final DateTime Function() _now;

  /// Day of the month a cycle starts on.
  final int startDay;
  StreamSubscription<List<Expense>>? _subscription;

  /// Follows a new cycle when the day has rolled over since [start]; does
  /// nothing while the cycle is the same. Call it when the app comes back.
  void refresh() {
    if (BudgetCycle.of(_now(), startDay: startDay) == state.cycle) return;
    start();
  }

  void start() {
    final cycle = BudgetCycle.of(_now(), startDay: startDay);
    unawaited(_subscription?.cancel());
    _subscription = _repository
        .watchExpenses(cycle)
        .listen(
          (expenses) => emit(
            ExpensesState(
              status: ExpensesStatus.loaded,
              expenses: [...expenses]..sort(_newestFirst),
              cycle: cycle,
            ),
          ),
          onError: (Object _) => emit(
            ExpensesState(
              status: ExpensesStatus.failure,
              expenses: state.expenses,
              cycle: cycle,
            ),
          ),
        );
  }

  Future<void> delete(String id) => _repository.deleteExpense(id);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
