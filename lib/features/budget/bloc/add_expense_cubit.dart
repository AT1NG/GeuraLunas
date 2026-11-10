import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/features/auth/bloc/submit_status.dart';
import 'package:geuralunas/repositories/expense_repository.dart';
import 'package:geuralunas/shared/parse_amount.dart';

/// Why the expense cannot be saved yet.
enum AddExpenseError { amountRequired, amountInvalid, categoryRequired }

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

final class AddExpenseState extends Equatable {
  const AddExpenseState({
    required this.date,
    this.amount = '',
    this.categoryId,
    this.note = '',
    this.error,
    this.status = SubmitStatus.idle,
  });

  /// As typed, for example `25.000`.
  final String amount;
  final String? categoryId;

  /// The day the money was spent.
  final DateTime date;
  final String note;
  final AddExpenseError? error;
  final SubmitStatus status;

  AddExpenseState copyWith({
    String? amount,
    String? categoryId,
    DateTime? date,
    String? note,
    AddExpenseError? error,
    SubmitStatus? status,
    bool clearError = false,
  }) => AddExpenseState(
    amount: amount ?? this.amount,
    categoryId: categoryId ?? this.categoryId,
    date: date ?? this.date,
    note: note ?? this.note,
    error: clearError ? null : error ?? this.error,
    status: status ?? this.status,
  );

  @override
  List<Object?> get props => [amount, categoryId, date, note, error, status];
}

/// State of the quick "record an expense" sheet.
class AddExpenseCubit extends Cubit<AddExpenseState> {
  AddExpenseCubit(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now,
      super(AddExpenseState(date: _dateOnly((now ?? DateTime.now)())));

  final ExpenseRepository _repository;
  final DateTime Function() _now;

  void amountChanged(String value) =>
      emit(state.copyWith(amount: value, clearError: true));

  void categorySelected(String id) =>
      emit(state.copyWith(categoryId: id, clearError: true));

  void dateChanged(DateTime date) =>
      emit(state.copyWith(date: _dateOnly(date)));

  void noteChanged(String value) => emit(state.copyWith(note: value));

  Future<void> submit() async {
    if (state.status == SubmitStatus.submitting) return;
    final amount = parseAmount(state.amount);
    final categoryId = state.categoryId;
    if (state.amount.trim().isEmpty) {
      emit(state.copyWith(error: AddExpenseError.amountRequired));
      return;
    }
    if (amount == null) {
      emit(state.copyWith(error: AddExpenseError.amountInvalid));
      return;
    }
    if (categoryId == null) {
      emit(state.copyWith(error: AddExpenseError.categoryRequired));
      return;
    }

    emit(state.copyWith(status: SubmitStatus.submitting, clearError: true));
    final clock = _now();
    final day = state.date;
    final note = state.note.trim();
    try {
      await _repository.addExpense(
        amount: amount,
        categoryId: categoryId,
        spentAt: DateTime(
          day.year,
          day.month,
          day.day,
          clock.hour,
          clock.minute,
        ),
        note: note.isEmpty ? null : note,
      );
      emit(state.copyWith(status: SubmitStatus.success));
    } on Object {
      emit(state.copyWith(status: SubmitStatus.failure));
    }
  }
}
