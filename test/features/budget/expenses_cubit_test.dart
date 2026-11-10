import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/budget/budget_cycle.dart';
import 'package:geuralunas/domain/budget/expense.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/features/budget/bloc/expenses_cubit.dart';

import '../../helpers/fakes.dart';

Expense expense(String id, DateTime spent, {DateTime? created}) => Expense(
  id: id,
  amount: const Money(1000),
  categoryId: 'makan',
  spentAt: spent,
  createdAt: created ?? spent,
);

void main() {
  late FakeExpenseRepository repository;
  final now = DateTime(2026, 11, 10, 14);

  setUp(() => repository = FakeExpenseRepository());

  test('start follows the expenses of the cycle that holds today', () async {
    final cubit = ExpensesCubit(repository, now: () => now)..start();
    await Future<void>.delayed(Duration.zero);

    expect(
      repository.watched.single,
      BudgetCycle.of(now, startDay: 1),
    );
    expect(cubit.state.status, ExpensesStatus.loaded);
    expect(cubit.state.cycle?.id, '2026-11');
    await cubit.close();
  });

  test('a start day other than 1 is used for the cycle', () async {
    final cubit = ExpensesCubit(repository, now: () => now, startDay: 25)
      ..start();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.cycle?.id, '2026-10');
    await cubit.close();
  });

  test('byDay groups by day, newest first', () async {
    final cubit = ExpensesCubit(repository, now: () => now)..start();
    repository.emit([
      expense('a', DateTime(2026, 11, 3, 9)),
      expense('b', DateTime(2026, 11, 8, 12)),
      expense('c', DateTime(2026, 11, 8, 18)),
    ]);
    await Future<void>.delayed(Duration.zero);

    final days = cubit.state.byDay;
    expect(days.keys.toList(), [DateTime(2026, 11, 8), DateTime(2026, 11, 3)]);
    expect(days[DateTime(2026, 11, 8)]!.map((e) => e.id), ['c', 'b']);
    await cubit.close();
  });

  test('delete asks the repository to remove the expense', () async {
    final cubit = ExpensesCubit(repository, now: () => now)..start();
    await cubit.delete('x1');
    expect(repository.deleted, ['x1']);
    await cubit.close();
  });

  group('refresh', () {
    test('follows a new cycle when the day rolls over', () async {
      var clock = DateTime(2026, 11, 30, 23, 50);
      final cubit = ExpensesCubit(repository, now: () => clock)..start();
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.cycle?.id, '2026-11');

      clock = DateTime(2026, 12, 1, 9);
      cubit.refresh();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.cycle?.id, '2026-12');
      expect(repository.watched.map((c) => c.id), ['2026-11', '2026-12']);
      await cubit.close();
    });

    test('does nothing while the cycle is the same', () async {
      final cubit = ExpensesCubit(repository, now: () => now)..start();
      await Future<void>.delayed(Duration.zero);
      cubit.refresh();
      await Future<void>.delayed(Duration.zero);
      expect(repository.watched, hasLength(1));
      await cubit.close();
    });
  });
}
