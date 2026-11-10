import 'dart:async';
import 'dart:developer' as developer;

import 'package:geuralunas/data/budget_data_source.dart';
import 'package:geuralunas/data/budget_dtos.dart';
import 'package:geuralunas/data/debt_data_source.dart';
import 'package:geuralunas/data/firestore_paths.dart';
import 'package:geuralunas/domain/budget/category.dart';

/// The user's spending categories.
abstract interface class CategoryRepository {
  /// All categories, archived ones included, ordered by `sortOrder`.
  Stream<List<Category>> watchCategories();

  /// Writes the default categories when the account has none. Safe to call
  /// again and from several places at once.
  Future<void> ensureDefaults();

  /// Adds a category after the existing ones and returns its id.
  Future<String> add({
    required String name,
    required String icon,
    required String colorHex,
  });

  Future<void> rename(String id, String name);

  /// Categories are archived, never deleted, so old expenses keep a name.
  Future<void> setArchived(String id, {required bool archived});

  /// Errors from writes that the server rejected after the call returned.
  Stream<Object> get writeErrors;
}

/// Reads with `get()` and writes with a batch that is started but not awaited
/// (see ADR-013). Calls run one after another so seeding and `sortOrder`
/// never race with each other.
class CategoryRepositoryImpl implements CategoryRepository {
  /// Creates the repository for the signed-in user.
  CategoryRepositoryImpl(
    this._dataSource, {
    required String Function() currentUid,
  }) : _currentUid = currentUid;

  final BudgetDataSource _dataSource;
  final String Function() _currentUid;
  final _errors = StreamController<Object>.broadcast();
  Future<void> _queue = Future<void>.value();
  String? _seededFor;

  @override
  Stream<Object> get writeErrors => _errors.stream;

  Future<T> _serial<T>(Future<T> Function() job) {
    final run = _queue.then((_) => job());
    _queue = run.then((_) {}, onError: (Object _) {});
    return run;
  }

  @override
  Stream<List<Category>> watchCategories() => _dataSource
      .watchCategories(_currentUid())
      .map(
        (docs) =>
            [for (final d in docs) categoryFromMap(d.id, d.data)]
              ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      );

  @override
  Future<void> ensureDefaults() => _serial(() async {
    final uid = _currentUid();
    if (_seededFor == uid) return;
    final existing = await _dataSource.getCategories(uid);
    if (existing.isEmpty) {
      _commit([
        for (final c in defaultCategories)
          SetOp(FirestorePaths.category(uid, c.id), categoryToMap(c)),
      ]);
    }
    _seededFor = uid;
  });

  @override
  Future<String> add({
    required String name,
    required String icon,
    required String colorHex,
  }) => _serial(() async {
    final uid = _currentUid();
    final existing = await _dataSource.getCategories(uid);
    var next = 0;
    for (final d in existing) {
      final order = (d.data['sortOrder'] as num?)?.toInt() ?? 0;
      if (order >= next) next = order + 1;
    }
    final id = _dataSource.newCategoryId(uid);
    _commit([
      SetOp(
        FirestorePaths.category(uid, id),
        categoryToMap(
          Category(
            id: id,
            name: name,
            icon: icon,
            colorHex: colorHex,
            sortOrder: next,
          ),
        ),
      ),
    ]);
    return id;
  });

  @override
  Future<void> rename(String id, String name) => _serial(() async {
    _commit([
      MergeOp(FirestorePaths.category(_currentUid(), id), {'name': name}),
    ]);
  });

  @override
  Future<void> setArchived(String id, {required bool archived}) =>
      _serial(() async {
        _commit([
          MergeOp(FirestorePaths.category(_currentUid(), id), {
            'archived': archived,
          }),
        ]);
      });

  void _commit(List<WriteOp> ops) {
    unawaited(
      _dataSource.write(ops).catchError((Object error, StackTrace stack) {
        developer.log(
          'Firestore write failed',
          name: 'CategoryRepository',
          error: error,
          stackTrace: stack,
        );
        if (!_errors.isClosed) _errors.add(error);
      }),
    );
  }
}
