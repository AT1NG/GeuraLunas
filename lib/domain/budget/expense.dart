import 'package:equatable/equatable.dart';
import 'package:geuralunas/domain/money.dart';

/// Money spent on something other than paying a debt.
final class Expense extends Equatable {
  /// Creates an expense. Throws [ArgumentError] when [amount] is not above
  /// zero, in release builds too (so the constructor is not `const`).
  Expense({
    required this.id,
    required Money amount,
    required this.categoryId,
    required this.spentAt,
    required this.createdAt,
    this.note,
  }) : amount = _requirePositive(amount);

  static Money _requirePositive(Money amount) {
    if (amount.rupiah <= 0) {
      throw ArgumentError.value(amount, 'amount', 'must be above zero');
    }
    return amount;
  }

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
