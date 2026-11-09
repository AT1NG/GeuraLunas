import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/data/debt_dto.dart';
import 'package:geuralunas/data/firestore_paths.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/money.dart';

Debt fullDebt() => Debt(
  id: 'd1',
  direction: DebtDirection.lent,
  kind: DebtKind.personal,
  counterpartyName: 'Budi',
  note: 'untuk servis motor',
  principal: const Money(999999999999),
  interestType: InterestType.flatDaily,
  interestRate: 0.4,
  adminFee: const Money(15000),
  tenorCount: 30,
  frequency: Frequency.once,
  startDate: DateTime(2026, 11, 9),
  totalPayable: const Money(1120000),
  paidTotal: const Money(20000),
  remaining: const Money(1100000),
  nextDueDate: DateTime(2026, 12, 9),
  status: DebtStatus.settled,
  createdAt: DateTime(2026, 11, 9, 10),
  updatedAt: DateTime(2026, 11, 10, 11),
  settledAt: DateTime(2026, 11, 11, 12),
);

Debt minimalDebt() => Debt(
  id: 'd2',
  direction: DebtDirection.owe,
  kind: DebtKind.pinjol,
  counterpartyName: 'Pinjol B',
  principal: const Money(1000000),
  interestType: InterestType.none,
  interestRate: 0,
  adminFee: Money.zero,
  frequency: Frequency.monthly,
  startDate: DateTime(2026, 11),
  totalPayable: const Money(1000000),
  paidTotal: Money.zero,
  remaining: const Money(1000000),
  status: DebtStatus.active,
  createdAt: DateTime(2026, 11),
  updatedAt: DateTime(2026, 11),
);

void main() {
  group('Debt', () {
    test('round trips with every field set', () {
      final debt = fullDebt();
      expect(debtFromMap('d1', debtToMap(debt)), debt);
    });

    test('round trips with optional fields missing', () {
      final debt = minimalDebt();
      expect(debtFromMap('d2', debtToMap(debt)), debt);
    });

    test('omits null optional fields instead of storing null', () {
      final map = debtToMap(minimalDebt());
      for (final key in ['note', 'tenorCount', 'nextDueDate', 'settledAt']) {
        expect(map.containsKey(key), isFalse, reason: key);
      }
    });

    test(
      'stores enums by wire value, money as int and dates as timestamps',
      () {
        final map = debtToMap(fullDebt());
        expect(map['direction'], 'lent');
        expect(map['interestType'], 'flat_daily');
        expect(map['status'], 'settled');
        expect(map['principal'], 999999999999);
        expect(map['startDate'], isA<Timestamp>());
      },
    );

    test('only writes keys the security rules allow', () {
      const allowed = {
        'direction',
        'kind',
        'counterpartyName',
        'note',
        'principal',
        'interestType',
        'interestRate',
        'adminFee',
        'tenorCount',
        'frequency',
        'startDate',
        'totalPayable',
        'paidTotal',
        'remaining',
        'nextDueDate',
        'status',
        'createdAt',
        'updatedAt',
        'settledAt',
      };
      expect(allowed.containsAll(debtToMap(fullDebt()).keys), isTrue);
    });

    test(
      'reads a whole-number interest rate that Firestore returns as int',
      () {
        final map = debtToMap(minimalDebt())..['interestRate'] = 0;
        expect(debtFromMap('d2', map).interestRate, 0.0);
      },
    );
  });

  group('Installment', () {
    test('round trips paid and unpaid', () {
      final unpaid = Installment(
        seq: 1,
        dueDate: DateTime(2026, 12, 5),
        amount: const Money(300000),
      );
      final paid = Installment(
        seq: 2,
        dueDate: DateTime(2027, 1, 5),
        amount: const Money(300000),
        paidAmount: const Money(300000),
        status: InstallmentStatus.paid,
        paidAt: DateTime(2027, 1, 4),
      );
      expect(installmentFromMap(installmentToMap(unpaid)), unpaid);
      expect(installmentFromMap(installmentToMap(paid)), paid);
      expect(installmentToMap(unpaid).containsKey('paidAt'), isFalse);
    });
  });

  group('Payment', () {
    test('round trips with and without optional fields', () {
      final full = Payment(
        id: 'p1',
        amount: const Money(250000),
        paidAt: DateTime(2026, 12),
        installmentSeq: 2,
        note: 'transfer',
        createdAt: DateTime(2026, 12, 1, 9),
      );
      final bare = Payment(
        id: 'p2',
        amount: const Money(1),
        paidAt: DateTime(2026, 12, 2),
        createdAt: DateTime(2026, 12, 2, 9),
      );
      expect(paymentFromMap('p1', paymentToMap(full)), full);
      expect(paymentFromMap('p2', paymentToMap(bare)), bare);
      expect(paymentToMap(bare).containsKey('note'), isFalse);
      expect(paymentToMap(bare).containsKey('installmentSeq'), isFalse);
    });
  });

  group('FirestorePaths', () {
    test('zero-pads installment ids to three digits', () {
      expect(FirestorePaths.installmentId(1), '001');
      expect(FirestorePaths.installmentId(7), '007');
      expect(FirestorePaths.installmentId(42), '042');
      expect(FirestorePaths.installmentId(123), '123');
    });

    test('builds document paths under the user', () {
      expect(FirestorePaths.debts('u1'), 'users/u1/debts');
      expect(FirestorePaths.debt('u1', 'd1'), 'users/u1/debts/d1');
      expect(
        FirestorePaths.installments('u1', 'd1'),
        'users/u1/debts/d1/installments',
      );
      expect(
        FirestorePaths.installment('u1', 'd1', 3),
        'users/u1/debts/d1/installments/003',
      );
      expect(
        FirestorePaths.payments('u1', 'd1'),
        'users/u1/debts/d1/payments',
      );
      expect(
        FirestorePaths.payment('u1', 'd1', 'p9'),
        'users/u1/debts/d1/payments/p9',
      );
    });
  });
}
