import 'package:flutter/material.dart';

/// Icons a category can use, by the name stored in Firestore.
const Map<String, IconData> categoryIcons = {
  'restaurant': Icons.restaurant,
  'directions_bus': Icons.directions_bus,
  'shopping_bag': Icons.shopping_bag,
  'receipt_long': Icons.receipt_long,
  'movie': Icons.movie,
  'favorite': Icons.favorite,
  'more_horiz': Icons.more_horiz,
  'cake': Icons.cake,
  'local_cafe': Icons.local_cafe,
  'school': Icons.school,
  'home': Icons.home,
  'pets': Icons.pets,
  'sports_esports': Icons.sports_esports,
  'savings': Icons.savings,
};

/// Colors a category can use, as `#RRGGBB`.
const List<String> categoryColors = [
  '#E57373',
  '#64B5F6',
  '#BA68C8',
  '#FFB74D',
  '#4DB6AC',
  '#F06292',
  '#90A4AE',
  '#81C784',
];

/// The icon for [name]; a plain label for names this version does not know.
IconData categoryIcon(String name) =>
    categoryIcons[name] ?? Icons.label_outline;

/// Parses `#RRGGBB`; falls back to grey for anything else.
Color categoryColor(String hex) {
  final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
  if (value == null || hex.length != 7) return Colors.blueGrey;
  return Color(0xFF000000 | value);
}
