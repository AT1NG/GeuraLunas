import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/data/debt_data_source.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/debt/payments.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/repositories/debt_repository.dart';

/// A server that never answers, like being offline.
class _NeverAnswersDataSource extends DebtDataSource {
  _NeverAnswersDataSource(super.firestore);

  @override
  Future<void> write(List<WriteOp> ops) => Completer<void>().future;
}

/// Remembers every batch that was written.
class _RecordingDataSource extends DebtDataSource {
  _RecordingDataSource(super.firestore);

  final batches = <List<WriteOp>>[];

  @override
  Future<void> write(List<WriteOp> ops) {
    batches.add(ops);
    return super.write(ops);
  }
}

class _FailingDataSource extends DebtDataSource {
  _FailingDataSource(super.firestore);

  @override
  Future<void> write(List<WriteOp> ops) =>
      Future<void>.error(StateError('permission-denied'));
}

final clock = DateTime(2026, 11, 9, 10);

NewDebt installmentDebt({
  String name = 'Paylater A',
  int principal = 900000,
  int tenor = 3,
  DateTime? start,
}) => NewDebt(
  direction: DebtDirection.owe,
  kind: DebtKind.installment,
  counterpartyName: name,
  principal: Money(principal),
  tenorCount: tenor,
  frequency: Frequency.monthly,
  startDate: start ?? DateTime(2026, 11, 5),
);

void main() {
  late FakeFirebaseFirestore fake;
  late DebtRepositoryImpl repo;

  DebtRepositoryImpl repoFor(String uid) => DebtRepositoryImpl(
    DebtDataSource(fake),
    currentUid: () => uid,
    now: () => clock,
  );

  setUp(() {
    fake = FakeFirebaseFirestore();
    repo = repoFor('u1');
  });

  Future<Debt> debtOf(String id) async => (await repo.watchDebt(id).first)!;
  Future<List<Installment>> installmentsOf(String id) =>
      repo.watchInstallments(id).first;
  Future<List<Payment>> paymentsOf(String id) => repo.watchPayments(id).first;

  Future<String> add(NewDebt input) async {
    final id = await repo.addDebt(input);
    await pumpEventQueue();
    return id;
  }

  group('addDebt', () {
    test('creates the debt and all installments together', () async {
      final id = await add(installmentDebt());

      final debt = await debtOf(id);
      final installments = await installmentsOf(id);

      expect(debt.counterpartyName, 'Paylater A');
      expect(debt.totalPayable, const Money(900000));
      expect(debt.remaining, const Money(900000));
      expect(debt.paidTotal, Money.zero);
      expect(debt.status, DebtStatus.active);
      expect(debt.nextDueDate, DateTime(2026, 12, 5));
      expect(debt.createdAt, clock);
      expect(installments.length, 3);
      expect(installments.fold(0, (s, i) => s + i.amount.rupiah), 900000);
      expect(installments.map((i) => i.seq), [1, 2, 3]);

      final raw = await fake
          .collection('users/u1/debts/$id/installments')
          .get();
      expect(raw.docs.map((d) => d.id).toList()..sort(), ['001', '002', '003']);
    });

    test('computes interest into the total', () async {
      final id = await add(
        NewDebt(
          direction: DebtDirection.owe,
          kind: DebtKind.pinjol,
          counterpartyName: 'Pinjol B',
          principal: const Money(1000000),
          interestType: InterestType.flatMonthly,
          interestRate: 3,
          tenorCount: 3,
          frequency: Frequency.monthly,
          startDate: DateTime(2026, 11, 9),
        ),
      );

      expect((await debtOf(id)).totalPayable, const Money(1090000));
    });

    test('flat daily uses tenor as days and one installment', () async {
      final id = await add(
        NewDebt(
          direction: DebtDirection.owe,
          kind: DebtKind.pinjol,
          counterpartyName: 'Pinjol C',
          principal: const Money(1000000),
          interestType: InterestType.flatDaily,
          interestRate: 0.4,
          tenorCount: 30,
          frequency: Frequency.weekly,
          startDate: DateTime(2026, 11),
        ),
      );

      final debt = await debtOf(id);
      final installments = await installmentsOf(id);
      expect(debt.totalPayable, const Money(1120000));
      expect(debt.frequency, Frequency.once);
      expect(installments.single.dueDate, DateTime(2026, 12));
      expect(installments.single.amount, const Money(1120000));
    });

    test('without tenor or due date there is no schedule', () async {
      final id = await add(
        NewDebt(
          direction: DebtDirection.lent,
          kind: DebtKind.personal,
          counterpartyName: 'Budi',
          principal: const Money(100000),
          frequency: Frequency.once,
          startDate: DateTime(2026, 11, 9),
        ),
      );

      expect(await installmentsOf(id), isEmpty);
      expect((await debtOf(id)).nextDueDate, isNull);
    });

    test('a due date without tenor makes a single installment', () async {
      final id = await add(
        NewDebt(
          direction: DebtDirection.lent,
          kind: DebtKind.personal,
          counterpartyName: 'Budi',
          principal: const Money(100000),
          frequency: Frequency.once,
          startDate: DateTime(2026, 11, 9),
          firstDueDate: DateTime(2026, 11, 20),
        ),
      );

      final installments = await installmentsOf(id);
      expect(installments.single.dueDate, DateTime(2026, 11, 20));
      expect(installments.single.amount, const Money(100000));
      expect((await debtOf(id)).nextDueDate, DateTime(2026, 11, 20));
    });

    test('honours an explicit first due date', () async {
      final id = await add(
        NewDebt(
          direction: DebtDirection.owe,
          kind: DebtKind.installment,
          counterpartyName: 'Toko X',
          principal: const Money(600000),
          tenorCount: 2,
          frequency: Frequency.monthly,
          startDate: DateTime(2026, 11, 9),
          firstDueDate: DateTime(2026, 11, 25),
        ),
      );

      expect(
        (await installmentsOf(id)).map((i) => i.dueDate),
        [DateTime(2026, 11, 25), DateTime(2026, 12, 25)],
      );
    });

    test('trims the name and drops a blank note', () async {
      final id = await add(
        NewDebt(
          direction: DebtDirection.owe,
          kind: DebtKind.personal,
          counterpartyName: '  Rani  ',
          note: '   ',
          principal: const Money(50000),
          frequency: Frequency.once,
          startDate: DateTime(2026, 11, 9),
        ),
      );

      final debt = await debtOf(id);
      expect(debt.counterpartyName, 'Rani');
      expect(debt.note, isNull);
    });

    test('rejects a non-positive principal', () {
      expect(
        () => repo.addDebt(installmentDebt(principal: 0)),
        throwsArgumentError,
      );
    });
  });

  group('recordPayment', () {
    test('writes payment, installment and debt together', () async {
      final id = await add(installmentDebt());

      await repo.recordPayment(
        debtId: id,
        amount: const Money(300000),
        paidAt: DateTime(2026, 12, 5),
        installmentSeq: 1,
        note: 'cicilan 1',
      );
      await pumpEventQueue();

      final debt = await debtOf(id);
      final installments = await installmentsOf(id);
      final payments = await paymentsOf(id);

      expect(payments.single.amount, const Money(300000));
      expect(payments.single.note, 'cicilan 1');
      expect(payments.single.createdAt, clock);
      expect(installments[0].status, InstallmentStatus.paid);
      expect(installments[1].status, InstallmentStatus.pending);
      expect(debt.paidTotal, const Money(300000));
      expect(debt.remaining, const Money(600000));
      expect(debt.nextDueDate, DateTime(2027, 1, 5));
      expect(debt.updatedAt, clock);
    });

    test('over the remaining amount throws and writes nothing', () async {
      final id = await add(installmentDebt());
      final before = await debtOf(id);

      await expectLater(
        repo.recordPayment(
          debtId: id,
          amount: const Money(900001),
          paidAt: DateTime(2026, 12, 5),
        ),
        throwsA(isA<PaymentExceedsRemaining>()),
      );
      await pumpEventQueue();

      expect(await paymentsOf(id), isEmpty);
      expect(await debtOf(id), before);
    });

    test('the last payment settles the debt', () async {
      final id = await add(installmentDebt());

      await repo.recordPayment(
        debtId: id,
        amount: const Money(900000),
        paidAt: DateTime(2026, 12, 5),
      );
      await pumpEventQueue();

      final debt = await debtOf(id);
      expect(debt.status, DebtStatus.settled);
      expect(debt.remaining, Money.zero);
      expect(debt.settledAt, clock);
      expect(debt.nextDueDate, isNull);
    });

    test('an unknown debt is reported', () async {
      await expectLater(
        repo.recordPayment(
          debtId: 'missing',
          amount: const Money(1),
          paidAt: DateTime(2026, 12, 5),
        ),
        throwsA(isA<DebtNotFound>()),
      );
    });
  });

  group('deletePayment', () {
    test('restores every value exactly as before the payment', () async {
      final id = await add(installmentDebt());
      final debtBefore = await debtOf(id);
      final installmentsBefore = await installmentsOf(id);

      await repo.recordPayment(
        debtId: id,
        amount: const Money(450000),
        paidAt: DateTime(2026, 12, 5),
      );
      await pumpEventQueue();
      final paymentId = (await paymentsOf(id)).single.id;

      await repo.deletePayment(debtId: id, paymentId: paymentId);
      await pumpEventQueue();

      expect(await paymentsOf(id), isEmpty);
      expect(await installmentsOf(id), installmentsBefore);
      final after = await debtOf(id);
      expect(after.remaining, debtBefore.remaining);
      expect(after.paidTotal, debtBefore.paidTotal);
      expect(after.nextDueDate, debtBefore.nextDueDate);
      expect(after.status, debtBefore.status);
    });

    test('reactivates a settled debt', () async {
      final id = await add(installmentDebt());
      await repo.recordPayment(
        debtId: id,
        amount: const Money(900000),
        paidAt: DateTime(2026, 12, 5),
      );
      await pumpEventQueue();
      final paymentId = (await paymentsOf(id)).single.id;

      await repo.deletePayment(debtId: id, paymentId: paymentId);
      await pumpEventQueue();

      final debt = await debtOf(id);
      expect(debt.status, DebtStatus.active);
      expect(debt.settledAt, isNull);
      expect(debt.remaining, const Money(900000));
    });
  });

  group('updateDebt', () {
    test('saves changed fields and stamps updatedAt', () async {
      final id = await add(installmentDebt());
      final debt = await debtOf(id);

      await repo.updateDebt(
        debt.copyWith(counterpartyName: 'Paylater B', note: 'baru'),
      );
      await pumpEventQueue();

      final saved = await debtOf(id);
      expect(saved.counterpartyName, 'Paylater B');
      expect(saved.note, 'baru');
      expect(saved.updatedAt, clock);
    });

    test('with a new schedule it replays existing payments', () async {
      final id = await add(installmentDebt());
      await repo.recordPayment(
        debtId: id,
        amount: const Money(300000),
        paidAt: DateTime(2026, 12, 5),
      );
      await pumpEventQueue();
      final debt = await debtOf(id);

      // Two installments of 450.000 instead of three of 300.000.
      await repo.updateDebt(
        debt.copyWith(tenorCount: 2),
        schedule: [
          Installment(
            seq: 1,
            dueDate: DateTime(2026, 12, 5),
            amount: const Money(450000),
          ),
          Installment(
            seq: 2,
            dueDate: DateTime(2027, 1, 5),
            amount: const Money(450000),
          ),
        ],
      );
      await pumpEventQueue();

      final installments = await installmentsOf(id);
      expect(installments.length, 2);
      expect(installments[0].status, InstallmentStatus.partial);
      expect(installments[0].paidAmount, const Money(300000));
      expect((await debtOf(id)).remaining, const Money(600000));
      final raw = await fake
          .collection('users/u1/debts/$id/installments')
          .get();
      expect(raw.docs.map((d) => d.id).toList()..sort(), ['001', '002']);
    });

    test('refuses a total below what is already paid', () async {
      final id = await add(installmentDebt());
      await repo.recordPayment(
        debtId: id,
        amount: const Money(600000),
        paidAt: DateTime(2026, 12, 5),
      );
      await pumpEventQueue();
      final debt = await debtOf(id);

      await expectLater(
        repo.updateDebt(
          debt.copyWith(totalPayable: const Money(300000)),
          schedule: [
            Installment(
              seq: 1,
              dueDate: DateTime(2026, 12, 5),
              amount: const Money(300000),
            ),
          ],
        ),
        throwsA(isA<PaymentExceedsRemaining>()),
      );
    });
  });

  group('archive and delete', () {
    test('setArchived archives and restores the right status', () async {
      final id = await add(installmentDebt());

      await repo.setArchived(id, archived: true);
      await pumpEventQueue();
      expect((await debtOf(id)).status, DebtStatus.archived);

      await repo.setArchived(id, archived: false);
      await pumpEventQueue();
      expect((await debtOf(id)).status, DebtStatus.active);
    });

    test('unarchiving a fully paid debt makes it settled', () async {
      final id = await add(installmentDebt());
      await repo.recordPayment(
        debtId: id,
        amount: const Money(900000),
        paidAt: DateTime(2026, 12, 5),
      );
      await pumpEventQueue();
      await repo.setArchived(id, archived: true);
      await pumpEventQueue();
      await repo.setArchived(id, archived: false);
      await pumpEventQueue();

      expect((await debtOf(id)).status, DebtStatus.settled);
    });

    test('deleteDebt removes the debt and its subcollections', () async {
      final id = await add(installmentDebt());
      await repo.recordPayment(
        debtId: id,
        amount: const Money(100000),
        paidAt: DateTime(2026, 12, 5),
      );
      await pumpEventQueue();

      await repo.deleteDebt(id);
      await pumpEventQueue();

      expect(await repo.watchDebt(id).first, isNull);
      expect((await fake.collection('users/u1/debts').get()).docs, isEmpty);
      expect(
        (await fake.collection('users/u1/debts/$id/installments').get()).docs,
        isEmpty,
      );
      expect(
        (await fake.collection('users/u1/debts/$id/payments').get()).docs,
        isEmpty,
      );
    });

    test('deleteDebt handles more than one batch of installments', () async {
      final id = await add(installmentDebt(principal: 5000000, tenor: 500));

      await repo.deleteDebt(id);
      await pumpEventQueue();

      expect(
        (await fake.collection('users/u1/debts/$id/installments').get()).docs,
        isEmpty,
      );
    });
  });

  group('watching', () {
    test(
      'debts are sorted by next due date, then name, undated last',
      () async {
        await add(installmentDebt(name: 'Zeta', start: DateTime(2026, 11, 20)));
        await add(
          installmentDebt(name: 'Alpha', start: DateTime(2026, 11, 20)),
        );
        await add(installmentDebt(name: 'Early', start: DateTime(2026, 11)));
        await add(
          NewDebt(
            direction: DebtDirection.lent,
            kind: DebtKind.personal,
            counterpartyName: 'No date',
            principal: const Money(10000),
            frequency: Frequency.once,
            startDate: DateTime(2026, 11, 9),
          ),
        );

        final names = (await repo.watchDebts().first)
            .map((d) => d.counterpartyName)
            .toList();
        expect(names, ['Early', 'Alpha', 'Zeta', 'No date']);
      },
    );

    test('installments come ordered by seq and payments by date', () async {
      final id = await add(installmentDebt());
      await repo.recordPayment(
        debtId: id,
        amount: const Money(100000),
        paidAt: DateTime(2026, 12, 9),
      );
      await pumpEventQueue();
      await repo.recordPayment(
        debtId: id,
        amount: const Money(50000),
        paidAt: DateTime(2026, 12),
      );
      await pumpEventQueue();

      expect((await installmentsOf(id)).map((i) => i.seq), [1, 2, 3]);
      expect((await paymentsOf(id)).map((p) => p.amount.rupiah), [
        50000,
        100000,
      ]);
    });

    test('watchDebt emits null for a debt that does not exist', () async {
      expect(await repo.watchDebt('nope').first, isNull);
    });

    test('each user only sees their own data', () async {
      await add(installmentDebt());

      expect(await repo.watchDebts().first, hasLength(1));
      expect(await repoFor('u2').watchDebts().first, isEmpty);
    });
  });

  group('offline (the server never answers)', () {
    DebtRepositoryImpl offline() => DebtRepositoryImpl(
      _NeverAnswersDataSource(fake),
      currentUid: () => 'u1',
      now: () => clock,
    );

    test('addDebt returns without waiting for the server', () async {
      final id = await offline()
          .addDebt(installmentDebt())
          .timeout(const Duration(seconds: 2));
      expect(id, isNotEmpty);
    });

    test('recordPayment returns without waiting for the server', () async {
      final id = await add(installmentDebt());

      await offline()
          .recordPayment(
            debtId: id,
            amount: const Money(100000),
            paidAt: DateTime(2026, 12, 5),
          )
          .timeout(const Duration(seconds: 2));
    });

    test('deletePayment returns without waiting for the server', () async {
      final id = await add(installmentDebt());
      await repo.recordPayment(
        debtId: id,
        amount: const Money(100000),
        paidAt: DateTime(2026, 12, 5),
      );
      await pumpEventQueue();
      final paymentId = (await paymentsOf(id)).single.id;

      await offline()
          .deletePayment(debtId: id, paymentId: paymentId)
          .timeout(const Duration(seconds: 2));
    });
  });

  group('schedule dates', () {
    test(
      'monthly from 31 Jan keeps the 31st: 28 Feb, 31 Mar, 30 Apr',
      () async {
        final id = await add(
          installmentDebt(
            principal: 400000,
            tenor: 4,
            start: DateTime(2026, 1, 31),
          ),
        );

        expect((await installmentsOf(id)).map((i) => i.dueDate), [
          DateTime(2026, 2, 28),
          DateTime(2026, 3, 31),
          DateTime(2026, 4, 30),
          DateTime(2026, 5, 31),
        ]);
        expect((await debtOf(id)).nextDueDate, DateTime(2026, 2, 28));
      },
    );
  });

  group('what gets written', () {
    late _RecordingDataSource recording;
    late DebtRepositoryImpl recordingRepo;

    setUp(() {
      recording = _RecordingDataSource(fake);
      recordingRepo = DebtRepositoryImpl(
        recording,
        currentUid: () => 'u1',
        now: () => clock,
      );
    });

    test('a payment writes only the installments that changed', () async {
      final id = await recordingRepo.addDebt(
        installmentDebt(principal: 1000000, tenor: 100),
      );
      await pumpEventQueue();
      recording.batches.clear();

      await recordingRepo.recordPayment(
        debtId: id,
        amount: const Money(5000),
        paidAt: DateTime(2026, 12, 5),
      );
      await pumpEventQueue();

      // The payment, the one installment it touched, and the debt.
      expect(recording.batches.single, hasLength(3));
    });

    test(
      'deleting a payment writes only the installments that changed',
      () async {
        final id = await recordingRepo.addDebt(
          installmentDebt(principal: 1000000, tenor: 100),
        );
        await pumpEventQueue();
        await recordingRepo.recordPayment(
          debtId: id,
          amount: const Money(5000),
          paidAt: DateTime(2026, 12, 5),
        );
        await pumpEventQueue();
        final paymentId = (await paymentsOf(id)).single.id;
        recording.batches.clear();

        await recordingRepo.deletePayment(debtId: id, paymentId: paymentId);
        await pumpEventQueue();

        expect(recording.batches.single, hasLength(3));
      },
    );

    test(
      'a name-only edit leaves money fields written by someone else alone',
      () async {
        final id = await add(installmentDebt());
        final stale = await debtOf(id);

        // Another device records a payment while the edit form is open.
        await repo.recordPayment(
          debtId: id,
          amount: const Money(300000),
          paidAt: DateTime(2026, 12, 5),
        );
        await pumpEventQueue();

        await repo.updateDebt(stale.copyWith(counterpartyName: 'Nama baru'));
        await pumpEventQueue();

        final saved = await debtOf(id);
        expect(saved.counterpartyName, 'Nama baru');
        expect(saved.paidTotal, const Money(300000));
        expect(saved.remaining, const Money(600000));
      },
    );

    test('a name-only edit can remove the note', () async {
      final id = await add(
        NewDebt(
          direction: DebtDirection.owe,
          kind: DebtKind.personal,
          counterpartyName: 'Rani',
          note: 'catatan lama',
          principal: const Money(50000),
          frequency: Frequency.once,
          startDate: DateTime(2026, 11, 9),
        ),
      );
      final debt = await debtOf(id);
      expect(debt.note, 'catatan lama');

      await repo.updateDebt(debt.copyWith(clearNote: true));
      await pumpEventQueue();

      expect((await debtOf(id)).note, isNull);
    });
  });

  group('write errors', () {
    test('a failed commit is reported on writeErrors, not thrown', () async {
      final failing = DebtRepositoryImpl(
        _FailingDataSource(fake),
        currentUid: () => 'u1',
        now: () => clock,
      );
      final errors = <Object>[];
      final sub = failing.writeErrors.listen(errors.add);

      await failing.addDebt(installmentDebt());
      await pumpEventQueue();

      expect(errors, hasLength(1));
      expect(errors.single, isA<StateError>());
      await sub.cancel();
    });
  });
}
