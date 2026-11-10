import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/budget/category.dart';

void main() {
  test('there are seven default categories with fixed ids, in order', () {
    expect(defaultCategories.map((c) => c.id), [
      'makan',
      'transport',
      'belanja',
      'tagihan',
      'hiburan',
      'kesehatan',
      'lainnya',
    ]);
    expect(defaultCategories.map((c) => c.name), [
      'Makan',
      'Transport',
      'Belanja',
      'Tagihan',
      'Hiburan',
      'Kesehatan',
      'Lainnya',
    ]);
    expect(defaultCategories.map((c) => c.sortOrder), [0, 1, 2, 3, 4, 5, 6]);
    expect(defaultCategories.every((c) => c.isDefault), isTrue);
    expect(defaultCategories.every((c) => !c.archived), isTrue);
  });

  test('default colors are #RRGGBB', () {
    final hex = RegExp(r'^#[0-9A-Fa-f]{6}$');
    expect(defaultCategories.every((c) => hex.hasMatch(c.colorHex)), isTrue);
  });

  test('copyWith archived changes only archived', () {
    final original = defaultCategories.first;
    final archived = original.copyWith(archived: true);
    expect(archived.archived, isTrue);
    expect(archived.id, original.id);
    expect(archived.name, original.name);
    expect(archived.sortOrder, original.sortOrder);
    expect(archived.isDefault, isTrue);
  });

  test('copyWith name changes only the name', () {
    final renamed = defaultCategories.first.copyWith(name: 'Jajan');
    expect(renamed.name, 'Jajan');
    expect(renamed.archived, isFalse);
  });

  test('categories with the same values are equal', () {
    expect(defaultCategories.first, defaultCategories.first.copyWith());
  });
}
