import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/money.dart';

Debt debt({
  DebtStatus status = DebtStatus.active,
  DateTime? nextDueDate,
}) => Debt(
  id: 'd1',
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
  nextDueDate: nextDueDate,
  status: status,
  createdAt: DateTime(2026, 11),
  updatedAt: DateTime(2026, 11),
);

void main() {
  group('isOverdue', () {
    final today = DateTime(2026, 11, 9, 15, 30);

    test('active with due date before today is overdue', () {
      expect(debt(nextDueDate: DateTime(2026, 11, 8)).isOverdue(today), isTrue);
    });

    test('due today is not overdue, whatever the time of day', () {
      expect(
        debt(nextDueDate: DateTime(2026, 11, 9, 8)).isOverdue(today),
        isFalse,
      );
      expect(
        debt(nextDueDate: DateTime(2026, 11, 9, 23, 59)).isOverdue(today),
        isFalse,
      );
    });

    test('due in the future is not overdue', () {
      expect(
        debt(nextDueDate: DateTime(2026, 11, 10)).isOverdue(today),
        isFalse,
      );
    });

    test('settled and archived are never overdue', () {
      final past = DateTime(2026);
      expect(
        debt(status: DebtStatus.settled, nextDueDate: past).isOverdue(today),
        isFalse,
      );
      expect(
        debt(status: DebtStatus.archived, nextDueDate: past).isOverdue(today),
        isFalse,
      );
    });

    test('no due date is never overdue', () {
      expect(debt().isOverdue(today), isFalse);
    });
  });

  group('copyWith', () {
    test('changes only the given fields', () {
      final original = debt(nextDueDate: DateTime(2026, 12));
      final changed = original.copyWith(
        remaining: const Money(500000),
        status: DebtStatus.settled,
      );
      expect(changed.remaining, const Money(500000));
      expect(changed.status, DebtStatus.settled);
      expect(changed.counterpartyName, original.counterpartyName);
      expect(changed.nextDueDate, original.nextDueDate);
    });

    test('can clear nullable fields explicitly', () {
      final original = debt(nextDueDate: DateTime(2026, 12));
      expect(original.copyWith(clearNextDueDate: true).nextDueDate, isNull);
    });
  });

  group('Debt equality', () {
    test('equal when all fields are equal, different when one differs', () {
      expect(debt(), debt());
      expect(debt().hashCode, debt().hashCode);
      expect(debt(), isNot(debt(status: DebtStatus.settled)));
      expect(debt(), isNot(debt().copyWith(note: 'x')));
    });

    test('copyWith can replace every changeable field', () {
      final changed = debt().copyWith(
        counterpartyName: 'Budi',
        note: 'catatan',
        principal: const Money(2),
        interestType: InterestType.flatMonthly,
        interestRate: 3,
        adminFee: const Money(4),
        tenorCount: 5,
        frequency: Frequency.weekly,
        startDate: DateTime(2027),
        totalPayable: const Money(6),
        paidTotal: const Money(7),
        remaining: const Money(8),
        nextDueDate: DateTime(2027, 2),
        status: DebtStatus.settled,
        updatedAt: DateTime(2027, 3),
        settledAt: DateTime(2027, 4),
      );
      expect(changed.counterpartyName, 'Budi');
      expect(changed.note, 'catatan');
      expect(changed.tenorCount, 5);
      expect(changed.settledAt, DateTime(2027, 4));
      expect(changed.copyWith(clearSettledAt: true).settledAt, isNull);
    });
  });

  group('Installment', () {
    test('copyWith can clear paidAt', () {
      final paid = Installment(
        seq: 1,
        dueDate: DateTime(2026, 12),
        amount: const Money(100),
        paidAt: DateTime(2026, 12, 2),
      );
      expect(paid.copyWith(clearPaidAt: true).paidAt, isNull);
      expect(paid.copyWith().paidAt, DateTime(2026, 12, 2));
    });

    test('has value equality and copyWith', () {
      final a = Installment(
        seq: 1,
        dueDate: DateTime(2026, 12),
        amount: const Money(100),
      );
      expect(
        a,
        Installment(
          seq: 1,
          dueDate: DateTime(2026, 12),
          amount: const Money(100),
        ),
      );
      expect(
        a.copyWith(paidAmount: const Money(40)).paidAmount,
        const Money(40),
      );
      expect(a.status, InstallmentStatus.pending);
      expect(a.paidAmount, Money.zero);
    });
  });

  group('enum wire values', () {
    test('match the database spec exactly', () {
      expect(DebtDirection.owe.wire, 'owe');
      expect(DebtDirection.lent.wire, 'lent');
      expect(DebtKind.installment.wire, 'installment');
      expect(InterestType.flatMonthly.wire, 'flat_monthly');
      expect(InterestType.flatDaily.wire, 'flat_daily');
      expect(InterestType.reducingMonthly.wire, 'reducing_monthly');
      expect(Frequency.once.wire, 'once');
      expect(DebtStatus.archived.wire, 'archived');
      expect(InstallmentStatus.partial.wire, 'partial');
    });

    test('round trip through fromWire for every value', () {
      for (final e in DebtDirection.values) {
        expect(DebtDirection.fromWire(e.wire), e);
      }
      for (final e in DebtKind.values) {
        expect(DebtKind.fromWire(e.wire), e);
      }
      for (final e in InterestType.values) {
        expect(InterestType.fromWire(e.wire), e);
      }
      for (final e in Frequency.values) {
        expect(Frequency.fromWire(e.wire), e);
      }
      for (final e in DebtStatus.values) {
        expect(DebtStatus.fromWire(e.wire), e);
      }
      for (final e in InstallmentStatus.values) {
        expect(InstallmentStatus.fromWire(e.wire), e);
      }
    });

    test('fromWire rejects unknown values', () {
      expect(() => DebtDirection.fromWire('nope'), throwsArgumentError);
      expect(() => DebtKind.fromWire(''), throwsArgumentError);
      expect(() => InterestType.fromWire('flatMonthly'), throwsArgumentError);
      expect(() => Frequency.fromWire('daily'), throwsArgumentError);
      expect(() => DebtStatus.fromWire('ACTIVE'), throwsArgumentError);
      expect(() => InstallmentStatus.fromWire('late'), throwsArgumentError);
    });
  });

  group('Payment', () {
    test('has value equality', () {
      final a = Payment(
        id: 'p1',
        amount: const Money(100),
        paidAt: DateTime(2026, 11, 9),
      );
      expect(
        a,
        Payment(
          id: 'p1',
          amount: const Money(100),
          paidAt: DateTime(2026, 11, 9),
        ),
      );
    });
  });
}
