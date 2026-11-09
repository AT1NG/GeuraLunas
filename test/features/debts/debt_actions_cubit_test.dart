import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/features/debts/bloc/debt_actions_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/debt_fixtures.dart';

final today = DateTime(2026, 12, 20, 14);

void main() {
  late MockDebtRepository repo;

  setUpAll(() {
    registerFallbackValue(Money.zero);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repo = MockDebtRepository();
    when(
      () => repo.setArchived(any(), archived: any(named: 'archived')),
    ).thenAnswer((_) async {});
    when(() => repo.deleteDebt(any())).thenAnswer((_) async {});
    when(
      () => repo.recordPayment(
        debtId: any(named: 'debtId'),
        amount: any(named: 'amount'),
        paidAt: any(named: 'paidAt'),
        installmentSeq: any(named: 'installmentSeq'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async {});
  });

  DebtActionsCubit build() => DebtActionsCubit(repo, 'd1', now: () => today);

  void debtIs(Debt? debt) =>
      when(() => repo.watchDebt('d1')).thenAnswer((_) => Stream.value(debt));

  test('starts idle', () {
    expect(build().state.status, ActionStatus.idle);
  });

  test('archive calls the repository and finishes', () async {
    final c = build();

    await c.archive();

    verify(() => repo.setArchived('d1', archived: true)).called(1);
    expect(c.state.status, ActionStatus.done);
    expect(c.state.action, DebtAction.archive);
  });

  test('unarchive restores the debt', () async {
    final c = build();

    await c.unarchive();

    verify(() => repo.setArchived('d1', archived: false)).called(1);
    expect(c.state.status, ActionStatus.done);
    expect(c.state.action, DebtAction.unarchive);
  });

  test('delete calls the repository and reports done', () async {
    final c = build();

    await c.delete();

    verify(() => repo.deleteDebt('d1')).called(1);
    expect(c.state.status, ActionStatus.done);
    expect(c.state.action, DebtAction.delete);
  });

  group('markSettled', () {
    test('records one payment for exactly the remaining amount', () async {
      debtIs(makeDebt(total: 900000, remaining: 450000));
      final c = build();

      await c.markSettled();

      verify(
        () => repo.recordPayment(
          debtId: 'd1',
          amount: const Money(450000),
          paidAt: DateTime(2026, 12, 20),
          installmentSeq: any(named: 'installmentSeq', that: isNull),
          note: 'Ditandai lunas',
        ),
      ).called(1);
      expect(c.state.status, ActionStatus.done);
      expect(c.state.action, DebtAction.markSettled);
    });

    test('an already settled debt does nothing', () async {
      debtIs(makeDebt(status: DebtStatus.settled, remaining: 0));
      final c = build();

      await c.markSettled();

      verifyNever(
        () => repo.recordPayment(
          debtId: any(named: 'debtId'),
          amount: any(named: 'amount'),
          paidAt: any(named: 'paidAt'),
          installmentSeq: any(named: 'installmentSeq'),
          note: any(named: 'note'),
        ),
      );
      expect(c.state.status, ActionStatus.done);
    });

    test('a debt that does not exist is a failure', () async {
      debtIs(null);
      final c = build();

      await c.markSettled();

      expect(c.state.status, ActionStatus.failure);
    });
  });

  group('failures', () {
    test('archive failing reports failure', () async {
      when(
        () => repo.setArchived(any(), archived: any(named: 'archived')),
      ).thenThrow(StateError('boom'));
      final c = build();

      await c.archive();

      expect(c.state.status, ActionStatus.failure);
      expect(c.state.action, DebtAction.archive);
    });

    test('delete failing reports failure', () async {
      when(() => repo.deleteDebt(any())).thenThrow(StateError('boom'));
      final c = build();

      await c.delete();

      expect(c.state.status, ActionStatus.failure);
    });

    test('markSettled failing reports failure', () async {
      debtIs(makeDebt());
      when(
        () => repo.recordPayment(
          debtId: any(named: 'debtId'),
          amount: any(named: 'amount'),
          paidAt: any(named: 'paidAt'),
          installmentSeq: any(named: 'installmentSeq'),
          note: any(named: 'note'),
        ),
      ).thenThrow(StateError('boom'));
      final c = build();

      await c.markSettled();

      expect(c.state.status, ActionStatus.failure);
    });

    test('a second action while one is running is ignored', () async {
      final c = build();

      await Future.wait([c.archive(), c.archive()]);

      verify(() => repo.setArchived('d1', archived: true)).called(1);
    });

    test('finishing after the cubit is closed does not throw', () async {
      final c = build();
      final pending = c.archive();
      await c.close();
      await expectLater(pending, completes);
    });
  });
}
