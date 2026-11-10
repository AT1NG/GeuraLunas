import 'package:equatable/equatable.dart';

/// A group for spending, such as food or transport.
///
/// Categories are never deleted, only archived, so an old expense always has a
/// category to name.
final class Category extends Equatable {
  /// Creates a category.
  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorHex,
    required this.sortOrder,
    this.isDefault = false,
    this.archived = false,
  });

  /// Document id; fixed for default categories.
  final String id;
  final String name;

  /// Icon name, one of the names the UI knows.
  final String icon;

  /// Color as `#RRGGBB`.
  final String colorHex;
  final int sortOrder;

  /// Whether the app created it.
  final bool isDefault;

  /// Archived categories are hidden from pickers but keep their expenses.
  final bool archived;

  /// A copy with a new [name] and/or [archived] flag.
  Category copyWith({String? name, bool? archived}) => Category(
    id: id,
    name: name ?? this.name,
    icon: icon,
    colorHex: colorHex,
    sortOrder: sortOrder,
    isDefault: isDefault,
    archived: archived ?? this.archived,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    icon,
    colorHex,
    sortOrder,
    isDefault,
    archived,
  ];
}

/// Categories every account starts with, with fixed ids so that seeding twice
/// writes the same documents.
const List<Category> defaultCategories = [
  Category(
    id: 'makan',
    name: 'Makan',
    icon: 'restaurant',
    colorHex: '#E57373',
    sortOrder: 0,
    isDefault: true,
  ),
  Category(
    id: 'transport',
    name: 'Transport',
    icon: 'directions_bus',
    colorHex: '#64B5F6',
    sortOrder: 1,
    isDefault: true,
  ),
  Category(
    id: 'belanja',
    name: 'Belanja',
    icon: 'shopping_bag',
    colorHex: '#BA68C8',
    sortOrder: 2,
    isDefault: true,
  ),
  Category(
    id: 'tagihan',
    name: 'Tagihan',
    icon: 'receipt_long',
    colorHex: '#FFB74D',
    sortOrder: 3,
    isDefault: true,
  ),
  Category(
    id: 'hiburan',
    name: 'Hiburan',
    icon: 'movie',
    colorHex: '#4DB6AC',
    sortOrder: 4,
    isDefault: true,
  ),
  Category(
    id: 'kesehatan',
    name: 'Kesehatan',
    icon: 'favorite',
    colorHex: '#F06292',
    sortOrder: 5,
    isDefault: true,
  ),
  Category(
    id: 'lainnya',
    name: 'Lainnya',
    icon: 'more_horiz',
    colorHex: '#90A4AE',
    sortOrder: 6,
    isDefault: true,
  ),
];
