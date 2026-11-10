import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geuralunas/domain/budget/category.dart';
import 'package:geuralunas/domain/budget/expense.dart';
import 'package:geuralunas/domain/money.dart';

Timestamp _ts(DateTime d) => Timestamp.fromDate(d);

DateTime _dt(Object? v) => (v! as Timestamp).toDate();

Money _money(Object? v) => Money((v! as num).toInt());

/// Firestore map for [category].
Map<String, Object?> categoryToMap(Category category) => {
  'name': category.name,
  'icon': category.icon,
  'colorHex': category.colorHex,
  'sortOrder': category.sortOrder,
  'isDefault': category.isDefault,
  'archived': category.archived,
};

/// Reads a category document.
Category categoryFromMap(String id, Map<String, Object?> data) => Category(
  id: id,
  name: data['name']! as String,
  icon: data['icon']! as String,
  colorHex: data['colorHex']! as String,
  sortOrder: (data['sortOrder']! as num).toInt(),
  isDefault: data['isDefault'] as bool? ?? false,
  archived: data['archived'] as bool? ?? false,
);

/// Firestore map for [expense]. A missing note is left out, never stored as
/// null.
Map<String, Object?> expenseToMap(Expense expense) => {
  'amount': expense.amount.rupiah,
  'categoryId': expense.categoryId,
  'spentAt': _ts(expense.spentAt),
  'createdAt': _ts(expense.createdAt),
  if (expense.note != null) 'note': expense.note,
};

/// Reads an expense document.
Expense expenseFromMap(String id, Map<String, Object?> data) => Expense(
  id: id,
  amount: _money(data['amount']),
  categoryId: data['categoryId']! as String,
  spentAt: _dt(data['spentAt']),
  createdAt: _dt(data['createdAt']),
  note: data['note'] as String?,
);
