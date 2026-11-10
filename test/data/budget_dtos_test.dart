import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/data/budget_dtos.dart';
import 'package:geuralunas/data/firestore_paths.dart';
import 'package:geuralunas/domain/budget/category.dart';
import 'package:geuralunas/domain/budget/expense.dart';
import 'package:geuralunas/domain/money.dart';

void main() {
  test('paths for categories and expenses', () {
    expect(FirestorePaths.categories('u1'), 'users/u1/categories');
    expect(FirestorePaths.category('u1', 'makan'), 'users/u1/categories/makan');
    expect(FirestorePaths.expenses('u1'), 'users/u1/expenses');
    expect(FirestorePaths.expense('u1', 'e1'), 'users/u1/expenses/e1');
  });

  group('category', () {
    test('round trip', () {
      const category = Category(
        id: 'jajan',
        name: 'Jajan',
        icon: 'cake',
        colorHex: '#112233',
        sortOrder: 7,
        archived: true,
      );
      final map = categoryToMap(category);
      expect(map, {
        'name': 'Jajan',
        'icon': 'cake',
        'colorHex': '#112233',
        'sortOrder': 7,
        'isDefault': false,
        'archived': true,
      });
      expect(categoryFromMap('jajan', map), category);
    });

    test('missing optional flags read as false', () {
      final category = categoryFromMap('x', {
        'name': 'X',
        'icon': 'cake',
        'colorHex': '#000000',
        'sortOrder': 1,
      });
      expect(category.isDefault, isFalse);
      expect(category.archived, isFalse);
    });
  });

  group('expense', () {
    final spentAt = DateTime(2026, 11, 10, 8, 30);
    final createdAt = DateTime(2026, 11, 10, 9);

    test('round trip with a note', () {
      final expense = Expense(
        id: 'e1',
        amount: const Money(25000),
        categoryId: 'makan',
        spentAt: spentAt,
        createdAt: createdAt,
        note: 'bakso',
      );
      final map = expenseToMap(expense);
      expect(map['amount'], isA<int>());
      expect(map['amount'], 25000);
      expect(map['spentAt'], Timestamp.fromDate(spentAt));
      expect(map['note'], 'bakso');
      expect(expenseFromMap('e1', map), expense);
    });

    test('a missing note is left out, not stored as null', () {
      final expense = Expense(
        id: 'e2',
        amount: const Money(1000),
        categoryId: 'makan',
        spentAt: spentAt,
        createdAt: createdAt,
      );
      final map = expenseToMap(expense);
      expect(map.containsKey('note'), isFalse);
      expect(expenseFromMap('e2', map).note, isNull);
    });

    test('an amount stored as a double still reads as whole rupiah', () {
      final expense = expenseFromMap('e3', {
        'amount': 1500.0,
        'categoryId': 'makan',
        'spentAt': Timestamp.fromDate(spentAt),
        'createdAt': Timestamp.fromDate(createdAt),
      });
      expect(expense.amount, const Money(1500));
    });
  });
}
