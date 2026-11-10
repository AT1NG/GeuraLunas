import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/domain/budget/category.dart';
import 'package:geuralunas/repositories/category_repository.dart';

/// Loading state of the category list.
enum CategoriesStatus { loading, loaded, failure }

final class CategoriesState extends Equatable {
  const CategoriesState({
    this.status = CategoriesStatus.loading,
    this.categories = const [],
  });

  final CategoriesStatus status;

  /// Every category, archived ones included, ordered by `sortOrder`.
  final List<Category> categories;

  /// Categories to pick from.
  List<Category> get active => [
    for (final c in categories)
      if (!c.archived) c,
  ];

  /// Categories hidden from pickers.
  List<Category> get archived => [
    for (final c in categories)
      if (c.archived) c,
  ];

  @override
  List<Object?> get props => [status, categories];
}

/// Owns the category list for the screens that show or change it.
class CategoriesCubit extends Cubit<CategoriesState> {
  CategoriesCubit(this._repository) : super(const CategoriesState());

  final CategoryRepository _repository;
  StreamSubscription<List<Category>>? _subscription;

  /// Makes sure the default categories exist, then follows the list.
  Future<void> start() async {
    try {
      await _repository.ensureDefaults();
    } on Object {
      // Offline or rejected: show whatever the stream has.
    }
    await _subscription?.cancel();
    _subscription = _repository.watchCategories().listen(
      (categories) => emit(
        CategoriesState(
          status: CategoriesStatus.loaded,
          categories: categories,
        ),
      ),
      onError: (Object _) => emit(
        CategoriesState(
          status: CategoriesStatus.failure,
          categories: state.categories,
        ),
      ),
    );
  }

  Future<void> add({
    required String name,
    required String icon,
    required String colorHex,
  }) => _repository.add(name: name, icon: icon, colorHex: colorHex);

  Future<void> rename(String id, String name) => _repository.rename(id, name);

  Future<void> setArchived(String id, {required bool archived}) =>
      _repository.setArchived(id, archived: archived);

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
