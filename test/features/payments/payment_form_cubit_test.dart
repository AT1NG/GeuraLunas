import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/debt/payments.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/features/auth/bloc/submit_status.dart';
import 'package:geuralunas/features/payments/bloc/payment_form_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/debt_fixtures.dart';

final today = DateTime(2026, 12, 20, 14);

Installment inst(
  int seq, {
  int amount = 300000,
  int paid = 0,
  InstallmentStatus status = InstallmentStatus.pending,
}) => Installment(
  seq: seq,
  dueDate: DateTime(2026, 12, seq * 5),
  amount: Money(amount),
  paidAmount: Money(paid),
  status: status,
);

void main() {
  late MockDebtRepository repo;

  setUpAll(() {
    registerFallbackValue(Money.zero);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    repo = MockDebtRepository();
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

  Debt debt({int remaining = 600000}) =>
      makeDebt(total: 900000, remaining: remaining);

  PaymentFormCubit cubit({
    Debt? forDebt,
    List<Installment> installments = const [],
  }) => PaymentFormCubit(
    repo,
    debt: forDebt ?? debt(),
    installments: installments,
    now: () => today,
  );

  group('defaults', () {
    test('amount is the remainder of the nearest unpaid installment', () {
      final c = cubit(
        installments: [
          inst(1, paid: 300000, status: InstallmentStatus.paid),
          inst(2, paid: 100000, status: InstallmentStatus.partial),
          inst(3),
        ],
      );

      expect(c.state.amount, '200000');
      expect(c.state.installmentSeq, 2);
    });

    test('amount is the whole remainder when there is no schedule', () {
      final c = cubit();
      expect(c.state.amount, '600000');
      expect(c.state.installmentSeq, isNull);
    });

    test('never defaults above what is still owed', () {
      final c = cubit(
        forDebt: debt(remaining: 100000),
        installments: [inst(1)],
      );
      expect(c.state.amount, '100000');
    });

    test('the date defaults to today', () {
      expect(cubit().state.date, DateTime(2026, 12, 20));
    });
  });

  group('validation', () {
    test('an empty, zero or unreadable amount is rejected', () {
      final c = cubit();
      for (final bad in ['', '0', 'abc', '-5', '1.5']) {
        c.amountChanged(bad);
        expect(
          c.state.amountError,
          PaymentFormError.invalidAmount,
          reason: bad,
        );
      }
      c.amountChanged('250.000');
      expect(c.state.amountError, isNull);
    });

    test('one rupiah over the remaining amount is rejected', () {
      final c = cubit()..amountChanged('600.001');
      expect(c.state.amountError, PaymentFormError.exceedsRemaining);
      c.amountChanged('600.000');
      expect(c.state.amountError, isNull);
    });

    test('a date in the future is rejected, today and the past are fine', () {
      final c = cubit()..dateChanged(DateTime(2026, 12, 21));
      expect(c.state.dateError, PaymentFormError.futureDate);
      c.dateChanged(DateTime(2026, 12, 20, 23, 59));
      expect(c.state.dateError, isNull);
      c.dateChanged(DateTime(2026, 1, 5));
      expect(c.state.dateError, isNull);
    });
  });

  group('choosing an installment', () {
    test('sets the amount to that installment remainder', () {
      final c = cubit(
        installments: [
          inst(1),
          inst(2, paid: 50000, status: InstallmentStatus.partial),
        ],
      )..installmentSelected(2);

      expect(c.state.installmentSeq, 2);
      expect(c.state.amount, '250000');
    });

    test('choosing automatic keeps the typed amount', () {
      final c = cubit(installments: [inst(1)])
        ..amountChanged('123.000')
        ..installmentSelected(null);

      expect(c.state.installmentSeq, isNull);
      expect(c.state.amount, '123.000');
    });
  });

  group('submit', () {
    test('with an invalid amount it shows errors and writes nothing', () async {
      final c = cubit()..amountChanged('');

      await c.submit();

      expect(c.state.showErrors, isTrue);
      expect(c.state.status, SubmitStatus.idle);
      verifyNever(
        () => repo.recordPayment(
          debtId: any(named: 'debtId'),
          amount: any(named: 'amount'),
          paidAt: any(named: 'paidAt'),
          installmentSeq: any(named: 'installmentSeq'),
          note: any(named: 'note'),
        ),
      );
    });

    test('records the payment and reports what is left', () async {
      final c = cubit(installments: [inst(1)])
        ..amountChanged('200.000')
        ..noteChanged('  transfer  ');

      await c.submit();

      verify(
        () => repo.recordPayment(
          debtId: 'd1',
          amount: const Money(200000),
          paidAt: DateTime(2026, 12, 20),
          installmentSeq: 1,
          note: 'transfer',
        ),
      ).called(1);
      expect(c.state.status, SubmitStatus.success);
      expect(c.state.remainingAfter, const Money(400000));
      expect(c.state.settled, isFalse);
    });

    test('paying exactly the remaining amount reports settled', () async {
      final c = cubit()..amountChanged('600.000');

      await c.submit();

      expect(c.state.status, SubmitStatus.success);
      expect(c.state.settled, isTrue);
      expect(c.state.remainingAfter, Money.zero);
    });

    test('tapping twice records the payment once', () async {
      final c = cubit();

      await Future.wait([c.submit(), c.submit()]);

      verify(
        () => repo.recordPayment(
          debtId: any(named: 'debtId'),
          amount: any(named: 'amount'),
          paidAt: any(named: 'paidAt'),
          installmentSeq: any(named: 'installmentSeq'),
          note: any(named: 'note'),
        ),
      ).called(1);
    });

    test('a blank note is sent as null', () async {
      final c = cubit()..noteChanged('   ');

      await c.submit();

      verify(
        () => repo.recordPayment(
          debtId: 'd1',
          amount: const Money(600000),
          paidAt: DateTime(2026, 12, 20),
          installmentSeq: any(named: 'installmentSeq', that: isNull),
          note: any(named: 'note', that: isNull),
        ),
      ).called(1);
    });

    test(
      'the repository refusing the amount shows an exceeds failure',
      () async {
        when(
          () => repo.recordPayment(
            debtId: any(named: 'debtId'),
            amount: any(named: 'amount'),
            paidAt: any(named: 'paidAt'),
            installmentSeq: any(named: 'installmentSeq'),
            note: any(named: 'note'),
          ),
        ).thenThrow(const PaymentExceedsRemaining(remaining: Money(1)));
        final c = cubit();

        await c.submit();

        expect(c.state.status, SubmitStatus.failure);
        expect(c.state.failure, PaymentFormFailure.exceedsRemaining);
      },
    );

    test(
      'any other error shows a generic failure and keeps the input',
      () async {
        when(
          () => repo.recordPayment(
            debtId: any(named: 'debtId'),
            amount: any(named: 'amount'),
            paidAt: any(named: 'paidAt'),
            installmentSeq: any(named: 'installmentSeq'),
            note: any(named: 'note'),
          ),
        ).thenThrow(StateError('boom'));
        final c = cubit()..amountChanged('100.000');

        await c.submit();

        expect(c.state.status, SubmitStatus.failure);
        expect(c.state.failure, PaymentFormFailure.unknown);
        expect(c.state.amount, '100.000');
      },
    );

    test('finishing after the cubit is closed does not throw', () async {
      final c = cubit();
      final pending = c.submit();
      await c.close();
      await expectLater(pending, completes);
    });
  });
}
