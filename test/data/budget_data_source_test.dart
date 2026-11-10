import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/data/budget_data_source.dart';
import 'package:geuralunas/data/debt_data_source.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late BudgetDataSource ds;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    ds = BudgetDataSource(firestore);
  });

  Future<void> addExpense(String id, DateTime at) =>
      firestore.doc('users/u1/expenses/$id').set({
        'amount': 1000,
        'categoryId': 'makan',
        'spentAt': Timestamp.fromDate(at),
        'createdAt': Timestamp.fromDate(at),
      });

  test('watchExpenses returns only the half-open range', () async {
    await addExpense('before', DateTime(2026, 10, 31, 23, 59));
    await addExpense('first', DateTime(2026, 11));
    await addExpense('last', DateTime(2026, 11, 30, 23, 59));
    await addExpense('after', DateTime(2026, 12));

    final docs = await ds
        .watchExpenses(
          'u1',
          from: DateTime(2026, 11),
          toExclusive: DateTime(2026, 12),
        )
        .first;
    expect(docs.map((d) => d.id).toSet(), {'first', 'last'});
  });

  test('expenses of another user are not returned', () async {
    await firestore.doc('users/u2/expenses/x').set({
      'amount': 1,
      'categoryId': 'makan',
      'spentAt': Timestamp.fromDate(DateTime(2026, 11, 5)),
      'createdAt': Timestamp.fromDate(DateTime(2026, 11, 5)),
    });
    final docs = await ds
        .watchExpenses(
          'u1',
          from: DateTime(2026, 11),
          toExclusive: DateTime(2026, 12),
        )
        .first;
    expect(docs, isEmpty);
  });

  test('getCategories and watchCategories read the collection', () async {
    await firestore.doc('users/u1/categories/makan').set({'name': 'Makan'});
    expect((await ds.getCategories('u1')).single.id, 'makan');
    expect((await ds.watchCategories('u1').first).single.data['name'], 'Makan');
  });

  test('new ids are unique and non-empty', () {
    final a = ds.newExpenseId('u1');
    final b = ds.newExpenseId('u1');
    expect(a, isNotEmpty);
    expect(a, isNot(b));
    expect(ds.newCategoryId('u1'), isNotEmpty);
  });

  test('write applies set, merge and delete', () async {
    await firestore.doc('users/u1/categories/old').set({'name': 'Old'});
    await firestore.doc('users/u1/categories/keep').set({
      'name': 'Keep',
      'archived': false,
    });

    await ds.write(const [
      SetOp('users/u1/categories/new', {'name': 'New'}),
      MergeOp('users/u1/categories/keep', {'archived': true}),
      DeleteOp('users/u1/categories/old'),
    ]);

    expect((await firestore.doc('users/u1/categories/new').get()).exists, true);
    final keep = await firestore.doc('users/u1/categories/keep').get();
    expect(keep.data(), {'name': 'Keep', 'archived': true});
    expect(
      (await firestore.doc('users/u1/categories/old').get()).exists,
      false,
    );
  });
}
