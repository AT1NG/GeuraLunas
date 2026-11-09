import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/debt/payments.dart';
import 'package:geuralunas/domain/debt/schedule.dart';
import 'package:geuralunas/domain/money.dart';

final now = DateTime(2026, 11, 20);

Debt baseDebt({
  int total = 900000,
  DebtStatus status = DebtStatus.active,
  DateTime? nextDue,
}) => Debt(
  id: 'd1',
  direction: DebtDirection.owe,
  kind: DebtKind.installment,
  counterpartyName: 'Paylater A',
  principal: Money(total),
  interestType: InterestType.none,
  interestRate: 0,
  adminFee: Money.zero,
  frequency: Frequency.monthly,
  startDate: DateTime(2026, 11),
  totalPayable: Money(total),
  paidTotal: Money.zero,
  remaining: Money(total),
  nextDueDate: nextDue,
  status: status,
  createdAt: DateTime(2026, 11),
  updatedAt: DateTime(2026, 11),
);

/// 3 installments of 300.000 due 5 Dec, 5 Jan, 5 Feb.
DebtState scheduled({DebtStatus status = DebtStatus.active}) {
  final installments = generateSchedule(
    totalPayable: const Money(900000),
    count: 3,
    frequency: Frequency.monthly,
    firstDueDate: DateTime(2026, 12, 5),
  );
  return DebtState(
    debt: baseDebt(status: status, nextDue: nextDueDate(installments)),
    installments: installments,
  );
}

/// A debt of 500.000 with no installments (e.g. a loan from a friend).
DebtState unscheduled() =>
    DebtState(debt: baseDebt(total: 500000), installments: const []);

Payment pay(
  String id,
  int amount, {
  int? seq,
  DateTime? at,
  DateTime? created,
}) => Payment(
  id: id,
  amount: Money(amount),
  paidAt: at ?? DateTime(2026, 11, 10),
  installmentSeq: seq,
  createdAt: created ?? DateTime(2026, 11, 10, 9),
);

void main() {
  group('applyPayment', () {
    test('paying a whole installment marks it paid and moves nextDueDate', () {
      final s = scheduled();
      final p = pay('p1', 300000, seq: 1);

      final result = applyPayment(
        state: s,
        existing: const [],
        payment: p,
        now: now,
      );

      expect(result.installments[0].status, InstallmentStatus.paid);
      expect(result.installments[0].paidAmount, const Money(300000));
      expect(result.installments[0].paidAt, p.paidAt);
      expect(result.installments[1].status, InstallmentStatus.pending);
      expect(result.debt.paidTotal, const Money(300000));
      expect(result.debt.remaining, const Money(600000));
      expect(result.debt.status, DebtStatus.active);
      expect(result.debt.nextDueDate, DateTime(2027, 1, 5));
    });

    test('a partial payment marks the installment partial', () {
      final result = applyPayment(
        state: scheduled(),
        existing: const [],
        payment: pay('p1', 100000, seq: 1),
        now: now,
      );

      final first = result.installments[0];
      expect(first.status, InstallmentStatus.partial);
      expect(first.paidAmount, const Money(100000));
      expect(first.amount - first.paidAmount, const Money(200000));
      expect(first.paidAt, isNull);
      expect(result.debt.nextDueDate, DateTime(2026, 12, 5));
      expect(result.debt.remaining, const Money(800000));
    });

    test('without installmentSeq it fills the earliest unpaid ones first', () {
      final result = applyPayment(
        state: scheduled(),
        existing: const [],
        payment: pay('p1', 450000),
        now: now,
      );

      expect(result.installments[0].status, InstallmentStatus.paid);
      expect(result.installments[1].status, InstallmentStatus.partial);
      expect(result.installments[1].paidAmount, const Money(150000));
      expect(result.installments[2].status, InstallmentStatus.pending);
    });

    test('targeting a later installment leaves the earlier ones alone', () {
      final result = applyPayment(
        state: scheduled(),
        existing: const [],
        payment: pay('p1', 300000, seq: 2),
        now: now,
      );

      expect(result.installments[0].status, InstallmentStatus.pending);
      expect(result.installments[1].status, InstallmentStatus.paid);
      expect(result.debt.nextDueDate, DateTime(2026, 12, 5));
    });

    test(
      'overflow beyond the targeted installment goes to the earliest unpaid',
      () {
        final result = applyPayment(
          state: scheduled(),
          existing: const [],
          payment: pay('p1', 400000, seq: 2),
          now: now,
        );

        expect(result.installments[1].status, InstallmentStatus.paid);
        expect(result.installments[0].status, InstallmentStatus.partial);
        expect(result.installments[0].paidAmount, const Money(100000));
      },
    );

    test('paying exactly the remaining amount settles the debt', () {
      final result = applyPayment(
        state: scheduled(),
        existing: const [],
        payment: pay('p1', 900000),
        now: now,
      );

      expect(result.debt.remaining, Money.zero);
      expect(result.debt.paidTotal, const Money(900000));
      expect(result.debt.status, DebtStatus.settled);
      expect(result.debt.settledAt, now);
      expect(result.debt.nextDueDate, isNull);
      expect(
        result.installments.every((i) => i.status == InstallmentStatus.paid),
        isTrue,
      );
    });

    test('one rupiah over the remaining amount is rejected', () {
      expect(
        () => applyPayment(
          state: scheduled(),
          existing: const [],
          payment: pay('p1', 900001),
          now: now,
        ),
        throwsA(
          isA<PaymentExceedsRemaining>().having(
            (e) => e.remaining,
            'remaining',
            const Money(900000),
          ),
        ),
      );
    });

    test('the limit follows the remaining amount after earlier payments', () {
      final s = scheduled();
      final first = pay('p1', 500000);
      final after = applyPayment(
        state: s,
        existing: const [],
        payment: first,
        now: now,
      );

      expect(
        () => applyPayment(
          state: after,
          existing: [first],
          payment: pay('p2', 400001),
          now: now,
        ),
        throwsA(
          isA<PaymentExceedsRemaining>().having(
            (e) => e.remaining,
            'remaining',
            const Money(400000),
          ),
        ),
      );
    });

    test('zero and negative amounts are rejected', () {
      for (final amount in [0, -1, -500000]) {
        expect(
          () => applyPayment(
            state: scheduled(),
            existing: const [],
            payment: pay('p1', amount),
            now: now,
          ),
          throwsA(isA<InvalidPaymentAmount>()),
          reason: 'amount=$amount',
        );
      }
    });

    test('an installment that does not exist is rejected', () {
      expect(
        () => applyPayment(
          state: scheduled(),
          existing: const [],
          payment: pay('p1', 100000, seq: 9),
          now: now,
        ),
        throwsA(
          isA<UnknownInstallment>().having((e) => e.seq, 'seq', 9),
        ),
      );
    });

    test('a debt without a schedule only changes its totals and status', () {
      final first = pay('p1', 200000);
      final partial = applyPayment(
        state: unscheduled(),
        existing: const [],
        payment: first,
        now: now,
      );

      expect(partial.installments, isEmpty);
      expect(partial.debt.paidTotal, const Money(200000));
      expect(partial.debt.remaining, const Money(300000));
      expect(partial.debt.nextDueDate, isNull);
      expect(partial.debt.status, DebtStatus.active);

      final done = applyPayment(
        state: partial,
        existing: [first],
        payment: pay('p2', 300000),
        now: now,
      );
      expect(done.debt.status, DebtStatus.settled);
      expect(done.debt.remaining, Money.zero);
    });

    test('an archived debt stays archived', () {
      final result = applyPayment(
        state: scheduled(status: DebtStatus.archived),
        existing: const [],
        payment: pay('p1', 900000),
        now: now,
      );

      expect(result.debt.status, DebtStatus.archived);
      expect(result.debt.remaining, Money.zero);
    });
  });

  group('revertPayment', () {
    final p1 = pay('p1', 300000, seq: 1, at: DateTime(2026, 12, 5));
    final p2 = pay('p2', 150000, at: DateTime(2027, 1, 6));
    final p3 = pay('p3', 450000, at: DateTime(2027, 1, 20));

    DebtState applyAll(List<Payment> payments) {
      var state = scheduled();
      final applied = <Payment>[];
      for (final p in payments) {
        state = applyPayment(
          state: state,
          existing: List.of(applied),
          payment: p,
          now: now,
        );
        applied.add(p);
      }
      return state;
    }

    test('removing the only payment restores the exact original state', () {
      final original = scheduled();
      final paid = applyAll([p1]);

      final restored = revertPayment(
        state: paid,
        existing: [p1],
        paymentId: 'p1',
        now: now,
      );

      expect(restored, original);
    });

    test('removing the last payment equals the state before it', () {
      final all = applyAll([p1, p2, p3]);
      final before = applyAll([p1, p2]);

      final restored = revertPayment(
        state: all,
        existing: [p1, p2, p3],
        paymentId: 'p3',
        now: now,
      );

      expect(restored, before);
    });

    test('removing a middle payment equals never having made it', () {
      final all = applyAll([p1, p2, p3]);
      final without = applyAll([p1, p3]);

      final restored = revertPayment(
        state: all,
        existing: [p1, p2, p3],
        paymentId: 'p2',
        now: now,
      );

      expect(restored, without);
    });

    test('removing a payment from a settled debt reactivates it', () {
      final settled = applyAll([p1, p2, p3]);
      expect(settled.debt.status, DebtStatus.settled);

      final restored = revertPayment(
        state: settled,
        existing: [p1, p2, p3],
        paymentId: 'p3',
        now: now,
      );

      expect(restored.debt.status, DebtStatus.active);
      expect(restored.debt.settledAt, isNull);
      expect(restored.debt.remaining, const Money(450000));
    });

    test('an archived debt stays archived', () {
      var state = scheduled(status: DebtStatus.archived);
      state = applyPayment(
        state: state,
        existing: const [],
        payment: p1,
        now: now,
      );

      final restored = revertPayment(
        state: state,
        existing: [p1],
        paymentId: 'p1',
        now: now,
      );

      expect(restored.debt.status, DebtStatus.archived);
    });

    test('an unknown payment id is rejected', () {
      expect(
        () => revertPayment(
          state: scheduled(),
          existing: const [],
          paymentId: 'missing',
          now: now,
        ),
        throwsArgumentError,
      );
    });
  });

  group('replayPayments', () {
    test('uses the current time for settledAt when now is not given', () {
      final s = scheduled();
      final before = DateTime.now();

      final result = replayPayments(
        debt: s.debt,
        installments: s.installments,
        payments: [pay('a', 900000)],
      );

      expect(result.debt.settledAt, isNotNull);
      expect(result.debt.settledAt!.isBefore(before), isFalse);
    });

    test('does not depend on the order of the list', () {
      final a = pay('a', 100000, at: DateTime(2026, 12));
      final b = pay('b', 250000, at: DateTime(2026, 12, 2));
      final c = pay('c', 300000, at: DateTime(2026, 12, 3));
      final s = scheduled();

      final forward = replayPayments(
        debt: s.debt,
        installments: s.installments,
        payments: [a, b, c],
        now: now,
      );
      final shuffled = replayPayments(
        debt: s.debt,
        installments: s.installments,
        payments: [c, a, b],
        now: now,
      );

      expect(shuffled, forward);
    });

    test('ignores whatever paid amounts the installments already hold', () {
      final s = scheduled();
      final dirty = s.installments
          .map(
            (i) => i.copyWith(
              paidAmount: i.amount,
              status: InstallmentStatus.paid,
            ),
          )
          .toList();

      final result = replayPayments(
        debt: s.debt,
        installments: dirty,
        payments: const [],
        now: now,
      );

      expect(result, s);
    });

    test('rejects payments that together exceed the total', () {
      final s = scheduled();
      expect(
        () => replayPayments(
          debt: s.debt,
          installments: s.installments,
          payments: [pay('a', 600000), pay('b', 400000)],
          now: now,
        ),
        throwsA(isA<PaymentExceedsRemaining>()),
      );
    });

    test('keeps the original settledAt when the debt stays settled', () {
      final settledAt = DateTime(2026, 11, 15);
      final s = scheduled();
      final debt = s.debt.copyWith(
        status: DebtStatus.settled,
        settledAt: settledAt,
      );

      final result = replayPayments(
        debt: debt,
        installments: s.installments,
        payments: [pay('a', 900000)],
        now: now,
      );

      expect(result.debt.settledAt, settledAt);
    });
  });

  group('payments pointing at an installment that no longer exists', () {
    test('replay falls back to the earliest unpaid installment', () {
      final s = scheduled();
      // The schedule used to be longer; seq 9 is gone now.
      final stale = pay('old', 450000, seq: 9);

      final result = replayPayments(
        debt: s.debt,
        installments: s.installments,
        payments: [stale],
        now: now,
      );

      expect(result.installments[0].status, InstallmentStatus.paid);
      expect(result.installments[1].status, InstallmentStatus.partial);
      expect(result.debt.paidTotal, const Money(450000));
      expect(result.debt.remaining, const Money(450000));
    });

    test('a brand new payment for a missing installment is still refused', () {
      expect(
        () => applyPayment(
          state: scheduled(),
          existing: const [],
          payment: pay('p1', 100000, seq: 9),
          now: now,
        ),
        throwsA(isA<UnknownInstallment>()),
      );
    });
  });
}
