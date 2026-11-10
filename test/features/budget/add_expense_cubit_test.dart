import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/features/auth/bloc/submit_status.dart';
import 'package:geuralunas/features/budget/bloc/add_expense_cubit.dart';

import '../../helpers/fakes.dart';

void main() {
  late FakeExpenseRepository repository;
  late AddExpenseCubit cubit;
  final now = DateTime(2026, 11, 10, 14, 30);

  setUp(() {
    repository = FakeExpenseRepository();
    cubit = AddExpenseCubit(repository, now: () => now);
  });

  tearDown(() => cubit.close());

  test('starts today with nothing filled in', () {
    expect(cubit.state.date, DateTime(2026, 11, 10));
    expect(cubit.state.amount, '');
    expect(cubit.state.categoryId, isNull);
    expect(cubit.state.status, SubmitStatus.idle);
  });

  group('validation', () {
    test('a blank amount is required', () async {
      cubit.categorySelected('makan');
      await cubit.submit();
      expect(cubit.state.error, AddExpenseError.amountRequired);
      expect(repository.added, isEmpty);
    });

    for (final bad in ['0', 'abc', '1.5', '1000000000000']) {
      test('"$bad" is not a valid amount', () async {
        cubit
          ..categorySelected('makan')
          ..amountChanged(bad);
        await cubit.submit();
        expect(cubit.state.error, AddExpenseError.amountInvalid);
        expect(repository.added, isEmpty);
      });
    }

    test('a category is required', () async {
      cubit.amountChanged('25.000');
      await cubit.submit();
      expect(cubit.state.error, AddExpenseError.categoryRequired);
      expect(repository.added, isEmpty);
    });

    test('typing clears the error', () async {
      await cubit.submit();
      expect(cubit.state.error, isNotNull);
      cubit.amountChanged('1');
      expect(cubit.state.error, isNull);
    });
  });

  group('saving', () {
    test('a grouped amount is saved as whole rupiah, today, no note', () async {
      cubit
        ..amountChanged('1.500.000')
        ..categorySelected('transport');
      await cubit.submit();

      expect(repository.added, hasLength(1));
      final saved = repository.added.single;
      expect(saved.amount, const Money(1500000));
      expect(saved.categoryId, 'transport');
      expect(saved.spentAt, DateTime(2026, 11, 10, 14, 30));
      expect(saved.note, isNull);
      expect(cubit.state.status, SubmitStatus.success);
    });

    test('a pasted Rp amount is accepted', () async {
      cubit
        ..amountChanged('Rp 25.000')
        ..categorySelected('makan');
      await cubit.submit();
      expect(repository.added.single.amount, const Money(25000));
    });

    test('another date keeps the time of day', () async {
      cubit
        ..amountChanged('1000')
        ..categorySelected('makan')
        ..dateChanged(DateTime(2026, 11, 8));
      await cubit.submit();
      expect(repository.added.single.spentAt, DateTime(2026, 11, 8, 14, 30));
    });

    test('a note is sent trimmed and a blank note is sent as null', () async {
      cubit
        ..amountChanged('1000')
        ..categorySelected('makan')
        ..noteChanged('  bakso  ');
      await cubit.submit();
      expect(repository.added.single.note, 'bakso');

      final again = AddExpenseCubit(repository, now: () => now)
        ..amountChanged('1000')
        ..categorySelected('makan')
        ..noteChanged('   ');
      await again.submit();
      expect(repository.added.last.note, isNull);
      await again.close();
    });

    test('a repository failure ends as a failure, not a crash', () async {
      final failing = AddExpenseCubit(_FailingExpenses(), now: () => now)
        ..amountChanged('1000')
        ..categorySelected('makan');
      await failing.submit();
      expect(failing.state.status, SubmitStatus.failure);
      await failing.close();
    });
  });
}

class _FailingExpenses extends FakeExpenseRepository {
  @override
  Future<String> addExpense({
    required Money amount,
    required String categoryId,
    required DateTime spentAt,
    String? note,
  }) async => throw Exception('boom');
}
