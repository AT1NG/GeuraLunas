import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/data/budget_data_source.dart';
import 'package:geuralunas/domain/budget/budget_cycle.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/repositories/expense_repository.dart';
import 'package:mocktail/mocktail.dart';

class _MockBudgetDataSource extends Mock implements BudgetDataSource {}

Future<void> pump() => Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late FakeFirebaseFirestore firestore;
  late ExpenseRepositoryImpl repo;
  final now = DateTime(2026, 11, 10, 14);
  final cycle = BudgetCycle.of(DateTime(2026, 11, 10), startDay: 1);

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repo = ExpenseRepositoryImpl(
      BudgetDataSource(firestore),
      currentUid: () => 'u1',
      now: () => now,
    );
  });

  test('addExpense writes the document and returns its id', () async {
    final id = await repo.addExpense(
      amount: const Money(25000),
      categoryId: 'makan',
      spentAt: DateTime(2026, 11, 9, 12),
      note: 'bakso',
    );
    await pump();

    final snap = await firestore.doc('users/u1/expenses/$id').get();
    final data = snap.data()!;
    expect(data['amount'], isA<int>());
    expect(data['amount'], 25000);
    expect(data['categoryId'], 'makan');
    expect(data['note'], 'bakso');
    expect(data['createdAt'], Timestamp.fromDate(now));
    expect(data['spentAt'], Timestamp.fromDate(DateTime(2026, 11, 9, 12)));
  });

  test('a blank note is stored as no note', () async {
    final id = await repo.addExpense(
      amount: const Money(1000),
      categoryId: 'makan',
      spentAt: now,
      note: '   ',
    );
    await pump();
    final data = (await firestore.doc('users/u1/expenses/$id').get()).data()!;
    expect(data.containsKey('note'), isFalse);
  });

  test('a note is trimmed', () async {
    final id = await repo.addExpense(
      amount: const Money(1000),
      categoryId: 'makan',
      spentAt: now,
      note: ' kopi ',
    );
    await pump();
    final data = (await firestore.doc('users/u1/expenses/$id').get()).data()!;
    expect(data['note'], 'kopi');
  });

  test('an amount of zero is refused before anything is written', () async {
    expect(
      () => repo.addExpense(
        amount: Money.zero,
        categoryId: 'makan',
        spentAt: now,
      ),
      throwsArgumentError,
    );
    await pump();
    expect(
      (await firestore.collection('users/u1/expenses').get()).docs,
      isEmpty,
    );
  });

  group('watchExpenses', () {
    Future<void> add(String id, DateTime at, {DateTime? created}) =>
        firestore.doc('users/u1/expenses/$id').set({
          'amount': 1000,
          'categoryId': 'makan',
          'spentAt': Timestamp.fromDate(at),
          'createdAt': Timestamp.fromDate(created ?? at),
        });

    test('returns only this cycle, to the last minute', () async {
      await add('before', DateTime(2026, 10, 31, 23, 59));
      await add('first', DateTime(2026, 11));
      await add('last', DateTime(2026, 11, 30, 23, 59));
      await add('after', DateTime(2026, 12));

      final list = await repo.watchExpenses(cycle).first;
      expect(list.map((e) => e.id).toSet(), {'first', 'last'});
    });

    test('newest first, ties broken by when they were recorded', () async {
      await add('old', DateTime(2026, 11, 2));
      await add(
        'same-a',
        DateTime(2026, 11, 5),
        created: DateTime(2026, 11, 5, 9),
      );
      await add(
        'same-b',
        DateTime(2026, 11, 5),
        created: DateTime(2026, 11, 5, 18),
      );
      await add('new', DateTime(2026, 11, 8));

      final ids = (await repo.watchExpenses(cycle).first).map((e) => e.id);
      expect(ids.toList(), ['new', 'same-b', 'same-a', 'old']);
    });
  });

  test('deleteExpense removes the document', () async {
    final id = await repo.addExpense(
      amount: const Money(1000),
      categoryId: 'makan',
      spentAt: now,
    );
    await pump();
    await repo.deleteExpense(id);
    await pump();
    expect(
      (await firestore.doc('users/u1/expenses/$id').get()).exists,
      isFalse,
    );
  });

  test('a rejected write is reported on writeErrors', () async {
    final ds = _MockBudgetDataSource();
    when(() => ds.newExpenseId(any())).thenReturn('e1');
    when(() => ds.write(any())).thenAnswer(
      (_) => Future<void>.error(Exception('permission-denied')),
    );
    final failing = ExpenseRepositoryImpl(ds, currentUid: () => 'u1');

    final error = failing.writeErrors.first;
    await failing.addExpense(
      amount: const Money(1000),
      categoryId: 'makan',
      spentAt: now,
    );
    expect(await error, isA<Exception>());
  });
}
