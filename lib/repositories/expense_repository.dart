import 'dart:async';
import 'dart:developer' as developer;

import 'package:geuralunas/data/budget_data_source.dart';
import 'package:geuralunas/data/budget_dtos.dart';
import 'package:geuralunas/data/debt_data_source.dart';
import 'package:geuralunas/data/firestore_paths.dart';
import 'package:geuralunas/domain/budget/budget_cycle.dart';
import 'package:geuralunas/domain/budget/expense.dart';
import 'package:geuralunas/domain/money.dart';

/// The user's expenses.
abstract interface class ExpenseRepository {
  /// Expenses spent during [cycle], newest first.
  Stream<List<Expense>> watchExpenses(BudgetCycle cycle);

  /// Records an expense and returns its id. Throws [ArgumentError] when
  /// [amount] is not above zero.
  Future<String> addExpense({
    required Money amount,
    required String categoryId,
    required DateTime spentAt,
    String? note,
  });

  Future<void> deleteExpense(String id);

  /// Errors from writes that the server rejected after the call returned.
  Stream<Object> get writeErrors;
}

/// Writes with a batch that is started but not awaited (see ADR-013); the UI
/// follows the local streams instead.
class ExpenseRepositoryImpl implements ExpenseRepository {
  /// Creates the repository for the signed-in user.
  ExpenseRepositoryImpl(
    this._dataSource, {
    required String Function() currentUid,
    DateTime Function()? now,
  }) : _currentUid = currentUid,
       _now = now ?? DateTime.now;

  final BudgetDataSource _dataSource;
  final String Function() _currentUid;
  final DateTime Function() _now;
  final _errors = StreamController<Object>.broadcast();

  @override
  Stream<Object> get writeErrors => _errors.stream;

  @override
  Stream<List<Expense>> watchExpenses(BudgetCycle cycle) {
    final end = cycle.endInclusive;
    return _dataSource
        .watchExpenses(
          _currentUid(),
          from: cycle.start,
          toExclusive: DateTime(end.year, end.month, end.day + 1),
        )
        .map(
          (docs) =>
              [for (final d in docs) expenseFromMap(d.id, d.data)]
                ..sort(_newestFirst),
        );
  }

  @override
  Future<String> addExpense({
    required Money amount,
    required String categoryId,
    required DateTime spentAt,
    String? note,
  }) async {
    if (amount.rupiah <= 0) {
      throw ArgumentError.value(amount, 'amount', 'must be above zero');
    }
    final uid = _currentUid();
    final id = _dataSource.newExpenseId(uid);
    final trimmed = note?.trim();
    final expense = Expense(
      id: id,
      amount: amount,
      categoryId: categoryId,
      spentAt: spentAt,
      createdAt: _now(),
      note: trimmed == null || trimmed.isEmpty ? null : trimmed,
    );
    _commit([SetOp(FirestorePaths.expense(uid, id), expenseToMap(expense))]);
    return id;
  }

  @override
  Future<void> deleteExpense(String id) async {
    _commit([DeleteOp(FirestorePaths.expense(_currentUid(), id))]);
  }

  static int _newestFirst(Expense a, Expense b) {
    final bySpent = b.spentAt.compareTo(a.spentAt);
    return bySpent != 0 ? bySpent : b.createdAt.compareTo(a.createdAt);
  }

  void _commit(List<WriteOp> ops) {
    unawaited(
      _dataSource.write(ops).catchError((Object error, StackTrace stack) {
        developer.log(
          'Firestore write failed',
          name: 'ExpenseRepository',
          error: error,
          stackTrace: stack,
        );
        if (!_errors.isClosed) _errors.add(error);
      }),
    );
  }
}
