import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geuralunas/data/debt_data_source.dart';
import 'package:geuralunas/data/firestore_paths.dart';

/// Thin wrapper over Firestore for categories and expenses.
class BudgetDataSource {
  /// Creates the data source.
  BudgetDataSource(FirebaseFirestore firestore) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String path) =>
      _firestore.collection(path);

  List<RawDoc> _docs(QuerySnapshot<Map<String, dynamic>> s) => [
    for (final d in s.docs)
      (id: d.id, data: Map<String, Object?>.from(d.data())),
  ];

  /// A fresh category id.
  String newCategoryId(String uid) =>
      _collection(FirestorePaths.categories(uid)).doc().id;

  /// A fresh expense id.
  String newExpenseId(String uid) =>
      _collection(FirestorePaths.expenses(uid)).doc().id;

  /// All categories, archived ones included.
  Stream<List<RawDoc>> watchCategories(String uid) =>
      _collection(FirestorePaths.categories(uid)).snapshots().map(_docs);

  /// One read of all categories.
  Future<List<RawDoc>> getCategories(String uid) async =>
      _docs(await _collection(FirestorePaths.categories(uid)).get());

  /// Expenses with `spentAt` in `[from, toExclusive)`.
  Stream<List<RawDoc>> watchExpenses(
    String uid, {
    required DateTime from,
    required DateTime toExclusive,
  }) => _collection(FirestorePaths.expenses(uid))
      .where('spentAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
      .where('spentAt', isLessThan: Timestamp.fromDate(toExclusive))
      .snapshots()
      .map(_docs);

  /// Applies [ops]; see [writeBatches].
  Future<void> write(List<WriteOp> ops) => writeBatches(_firestore, ops);
}
