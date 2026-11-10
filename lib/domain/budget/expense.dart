import 'package:equatable/equatable.dart';
import 'package:geuralunas/domain/money.dart';

/// Money spent on something other than paying a debt.
final class Expense extends Equatable {
  /// Creates an expense; [amount] must be above zero (so it is not `const`).
  Expense({
    required this.id,
    required this.amount,
    required this.categoryId,
    required this.spentAt,
    required this.createdAt,
    this.note,
  }) : assert(amount.rupiah > 0, 'An expense must be above zero');

  final String id;
  final Money amount;
  final String categoryId;

  /// When the money was spent.
  final DateTime spentAt;

  /// When the expense was recorded.
  final DateTime createdAt;
  final String? note;

  @override
  List<Object?> get props => [id, amount, categoryId, spentAt, createdAt, note];
}
