import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/features/debts/bloc/debts_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/debt_fixtures.dart';

final today = DateTime(2026, 11, 9, 14);

void main() {
  late MockDebtRepository repo;
  setUp(() => repo = MockDebtRepository());

  DebtsCubit build() => DebtsCubit(repo, now: () => today);

  void stream(List<Debt> debts) =>
      when(() => repo.watchDebts()).thenAnswer((_) => Stream.value(debts));

  test('starts loading', () {
    expect(build().state.status, DebtsStatus.loading);
  });

  blocTest<DebtsCubit, DebtsState>(
    'groups debts by direction',
    setUp: () => stream([
      makeDebt(id: 'a'),
      makeDebt(id: 'b', direction: DebtDirection.lent, name: 'Budi'),
    ]),
    build: build,
    act: (c) => c.start(),
    expect: () => [
      isA<DebtsState>()
          .having((s) => s.status, 'status', DebtsStatus.loaded)
          .having((s) => s.owe.map((d) => d.id), 'owe', ['a'])
          .having((s) => s.lent.map((d) => d.id), 'lent', ['b']),
    ],
  );

  blocTest<DebtsCubit, DebtsState>(
    'filter settled shows only settled debts',
    setUp: () => stream([
      makeDebt(id: 'active'),
      makeDebt(id: 'done', status: DebtStatus.settled, remaining: 0),
    ]),
    build: build,
    act: (c) async {
      c.start();
      await Future<void>.delayed(Duration.zero);
      c.setFilter(DebtFilter.settled);
    },
    skip: 1,
    expect: () => [
      isA<DebtsState>()
          .having((s) => s.filter, 'filter', DebtFilter.settled)
          .having((s) => s.owe.map((d) => d.id), 'owe', ['done']),
    ],
  );

  blocTest<DebtsCubit, DebtsState>(
    'active filter is the default and hides settled',
    setUp: () => stream([
      makeDebt(id: 'active'),
      makeDebt(id: 'done', status: DebtStatus.settled, remaining: 0),
    ]),
    build: build,
    act: (c) => c.start(),
    expect: () => [
      isA<DebtsState>()
          .having((s) => s.filter, 'filter', DebtFilter.active)
          .having((s) => s.owe.map((d) => d.id), 'owe', ['active']),
    ],
  );

  blocTest<DebtsCubit, DebtsState>(
    'archived debts are hidden in both filters',
    setUp: () => stream([
      makeDebt(id: 'old', status: DebtStatus.archived),
      makeDebt(id: 'live'),
    ]),
    build: build,
    act: (c) async {
      c.start();
      await Future<void>.delayed(Duration.zero);
      c.setFilter(DebtFilter.settled);
    },
    expect: () => [
      isA<DebtsState>().having((s) => s.owe.map((d) => d.id), 'owe', ['live']),
      isA<DebtsState>().having((s) => s.owe, 'owe', isEmpty),
    ],
  );

  blocTest<DebtsCubit, DebtsState>(
    'overdue first, then nearest due date, then name',
    setUp: () => stream([
      makeDebt(id: 'later', name: 'Zeta', nextDue: DateTime(2026, 11, 30)),
      makeDebt(id: 'none', name: 'Alpha'),
      makeDebt(id: 'soon', name: 'Beta', nextDue: DateTime(2026, 11, 12)),
      makeDebt(id: 'late', name: 'Gamma', nextDue: DateTime(2026, 11, 2)),
      makeDebt(id: 'soon2', name: 'Alpha2', nextDue: DateTime(2026, 11, 12)),
    ]),
    build: build,
    act: (c) => c.start(),
    expect: () => [
      isA<DebtsState>().having((s) => s.owe.map((d) => d.id), 'order', [
        'late',
        'soon2',
        'soon',
        'later',
        'none',
      ]),
    ],
  );

  blocTest<DebtsCubit, DebtsState>(
    'totals sum the remaining amount of the shown group',
    setUp: () => stream([
      makeDebt(id: 'a'),
      makeDebt(id: 'b', remaining: 500000),
      makeDebt(
        id: 'c',
        direction: DebtDirection.lent,
        remaining: 250000,
      ),
      makeDebt(id: 'done', status: DebtStatus.settled, remaining: 0),
    ]),
    build: build,
    act: (c) => c.start(),
    expect: () => [
      isA<DebtsState>()
          .having((s) => s.oweRemaining, 'owe', const Money(2000000))
          .having((s) => s.lentRemaining, 'lent', const Money(250000)),
    ],
  );

  blocTest<DebtsCubit, DebtsState>(
    'emits failure when the stream errors',
    setUp: () => when(
      () => repo.watchDebts(),
    ).thenAnswer((_) => Stream.error(StateError('offline'))),
    build: build,
    act: (c) => c.start(),
    expect: () => [
      isA<DebtsState>().having((s) => s.status, 'status', DebtsStatus.failure),
    ],
  );

  blocTest<DebtsCubit, DebtsState>(
    'follows later updates from the stream',
    setUp: () {
      final controller = StreamController<List<Debt>>();
      when(() => repo.watchDebts()).thenAnswer((_) => controller.stream);
      addTearDown(controller.close);
      Future<void>.delayed(Duration.zero, () {
        controller
          ..add([makeDebt(id: 'a')])
          ..add([makeDebt(id: 'a'), makeDebt(id: 'b', name: 'B')]);
      });
    },
    build: build,
    act: (c) => c.start(),
    wait: const Duration(milliseconds: 20),
    expect: () => [
      isA<DebtsState>().having((s) => s.owe.length, 'first', 1),
      isA<DebtsState>().having((s) => s.owe.length, 'second', 2),
    ],
  );
}
