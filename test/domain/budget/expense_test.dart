import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/budget/expense.dart';
import 'package:geuralunas/domain/money.dart';

Expense make({Money amount = const Money(25000), String? note}) => Expense(
  id: 'e1',
  amount: amount,
  categoryId: 'makan',
  spentAt: DateTime(2026, 11, 10),
  createdAt: DateTime(2026, 11, 10, 12),
  note: note,
);

void main() {
  test('a zero amount is rejected', () {
    expect(() => make(amount: Money.zero), throwsArgumentError);
  });

  test('a negative amount is rejected', () {
    expect(
      () => make(amount: const Money(-5)),
      throwsArgumentError,
    );
  });

  test('expenses with the same values are equal', () {
    expect(make(note: 'bakso'), make(note: 'bakso'));
    expect(make(note: 'bakso'), isNot(make()));
  });
}
