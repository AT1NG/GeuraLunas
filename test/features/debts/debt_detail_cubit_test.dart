import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/features/debts/bloc/debt_detail_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/debt_fixtures.dart';

void main() {
  late MockDebtRepository repo;
  late StreamController<Debt?> debtStream;
  late StreamController<List<Installment>> installmentStream;
  late StreamController<List<Payment>> paymentStream;

  setUp(() {
    repo = MockDebtRepository();
    debtStream = StreamController<Debt?>();
    installmentStream = StreamController<List<Installment>>();
    paymentStream = StreamController<List<Payment>>();
    when(() => repo.watchDebt('d1')).thenAnswer((_) => debtStream.stream);
    when(
      () => repo.watchInstallments('d1'),
    ).thenAnswer((_) => installmentStream.stream);
    when(
      () => repo.watchPayments('d1'),
    ).thenAnswer((_) => paymentStream.stream);
  });

  tearDown(() {
    // Not awaited: closing a controller nobody listened to never completes.
    unawaited(debtStream.close());
    unawaited(installmentStream.close());
    unawaited(paymentStream.close());
  });

  DebtDetailCubit build() => DebtDetailCubit(repo, 'd1');

  Installment installment(int seq) => Installment(
    seq: seq,
    dueDate: DateTime(2026, 12, seq),
    amount: const Money(100000),
  );

  Payment payment(String id) => Payment(
    id: id,
    amount: const Money(50000),
    paidAt: DateTime(2026, 11, 20),
  );

  test('starts loading', () {
    expect(build().state.status, DebtDetailStatus.loading);
  });

  test('combines debt, installments and payments', () async {
    final cubit = build()..start();

    debtStream.add(makeDebt());
    installmentStream.add([installment(1), installment(2)]);
    paymentStream.add([payment('p1')]);
    await pumpEventQueue();

    expect(cubit.state.status, DebtDetailStatus.loaded);
    expect(cubit.state.debt!.counterpartyName, 'Pinjol B');
    expect(cubit.state.installments.map((i) => i.seq), [1, 2]);
    expect(cubit.state.payments.map((p) => p.id), ['p1']);
    await cubit.close();
  });

  test('sorts installments by number and payments oldest first', () async {
    final cubit = build()..start();
    debtStream.add(makeDebt());
    installmentStream.add([installment(3), installment(1), installment(2)]);
    paymentStream.add([
      Payment(id: 'late', amount: const Money(1), paidAt: DateTime(2026, 12)),
      Payment(id: 'early', amount: const Money(1), paidAt: DateTime(2026, 11)),
    ]);
    await pumpEventQueue();

    expect(cubit.state.installments.map((i) => i.seq), [1, 2, 3]);
    expect(cubit.state.payments.map((p) => p.id), ['early', 'late']);
    await cubit.close();
  });

  test('is loaded as soon as the debt arrives', () async {
    final cubit = build()..start();

    debtStream.add(makeDebt());
    await pumpEventQueue();

    expect(cubit.state.status, DebtDetailStatus.loaded);
    expect(cubit.state.installments, isEmpty);
    expect(cubit.state.payments, isEmpty);
    await cubit.close();
  });

  test('follows later changes', () async {
    final cubit = build()..start();
    debtStream.add(makeDebt());
    await pumpEventQueue();

    debtStream.add(makeDebt(remaining: 1000000));
    paymentStream.add([payment('p1'), payment('p2')]);
    await pumpEventQueue();

    expect(cubit.state.debt!.remaining, const Money(1000000));
    expect(cubit.state.payments, hasLength(2));
    await cubit.close();
  });

  group('progress', () {
    test('is 0.5 at half', () async {
      final cubit = build()..start();
      debtStream.add(makeDebt(remaining: 1000000));
      await pumpEventQueue();

      expect(cubit.state.progress, 0.5);
      await cubit.close();
    });

    test('is 0 when nothing is paid, 1 when settled', () async {
      final cubit = build()..start();
      debtStream.add(makeDebt(remaining: 2000000));
      await pumpEventQueue();
      expect(cubit.state.progress, 0);

      debtStream.add(makeDebt(remaining: 0));
      await pumpEventQueue();
      expect(cubit.state.progress, 1);
      await cubit.close();
    });

    test('is 0 while loading or when the total is 0', () async {
      final cubit = build()..start();
      expect(cubit.state.progress, 0);

      debtStream.add(makeDebt(total: 0, remaining: 0));
      await pumpEventQueue();
      expect(cubit.state.progress, 0);
      await cubit.close();
    });
  });

  test('notFound when the debt does not exist', () async {
    final cubit = build()..start();

    debtStream.add(null);
    await pumpEventQueue();

    expect(cubit.state.status, DebtDetailStatus.notFound);
    expect(cubit.state.debt, isNull);
    await cubit.close();
  });

  test('failure when a stream errors', () async {
    final cubit = build()..start();

    debtStream.addError(StateError('offline'));
    await pumpEventQueue();

    expect(cubit.state.status, DebtDetailStatus.failure);
    await cubit.close();
  });

  test('failure when the payments stream errors', () async {
    final cubit = build()..start();
    debtStream.add(makeDebt());
    await pumpEventQueue();

    paymentStream.addError(StateError('boom'));
    await pumpEventQueue();

    expect(cubit.state.status, DebtDetailStatus.failure);
    await cubit.close();
  });

  test('cancels all subscriptions on close', () async {
    final cubit = build()..start();
    expect(debtStream.hasListener, isTrue);
    expect(installmentStream.hasListener, isTrue);
    expect(paymentStream.hasListener, isTrue);

    await cubit.close();

    expect(debtStream.hasListener, isFalse);
    expect(installmentStream.hasListener, isFalse);
    expect(paymentStream.hasListener, isFalse);
  });
}
