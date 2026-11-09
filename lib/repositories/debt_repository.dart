import 'dart:async';
import 'dart:developer' as developer;

import 'package:geuralunas/data/debt_data_source.dart';
import 'package:geuralunas/data/debt_dto.dart';
import 'package:geuralunas/data/firestore_paths.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/debt/debt_plan.dart';
import 'package:geuralunas/domain/debt/payments.dart';
import 'package:geuralunas/domain/debt/schedule.dart';
import 'package:geuralunas/domain/money.dart';

/// The debt (or its owner's data) does not exist.
final class DebtNotFound implements Exception {
  const DebtNotFound(this.debtId);

  final String debtId;

  @override
  String toString() => 'DebtNotFound($debtId)';
}

/// Input for creating a debt. The schedule and totals are derived.
final class NewDebt {
  const NewDebt({
    required this.direction,
    required this.kind,
    required this.counterpartyName,
    required this.principal,
    required this.frequency,
    required this.startDate,
    this.interestType = InterestType.none,
    this.interestRate = 0,
    this.adminFee = Money.zero,
    this.tenorCount,
    this.note,
    this.firstDueDate,
  });

  final DebtDirection direction;
  final DebtKind kind;
  final String counterpartyName;
  final String? note;
  final Money principal;
  final InterestType interestType;
  final double interestRate;
  final Money adminFee;

  /// Number of installments, or the number of days for `flat_daily`.
  final int? tenorCount;
  final Frequency frequency;
  final DateTime startDate;

  /// Due date of the first installment; defaults to one period after
  /// [startDate]. With no [tenorCount], a date here makes a single installment.
  final DateTime? firstDueDate;
}

abstract interface class DebtRepository {
  Stream<List<Debt>> watchDebts();

  /// Emits `null` while the debt does not exist.
  Stream<Debt?> watchDebt(String debtId);

  /// Ordered by installment number.
  Stream<List<Installment>> watchInstallments(String debtId);

  /// Ordered by payment date, oldest first.
  Stream<List<Payment>> watchPayments(String debtId);

  /// Errors from writes that the server rejected after the call returned.
  Stream<Object> get writeErrors;

  /// Creates the debt and its whole schedule in one batch; returns the id.
  Future<String> addDebt(NewDebt input);

  /// Saves [debt]. With a [schedule], installments are replaced and replayed
  /// against the existing payments. Without one, only the name, note and
  /// `updatedAt` are written (merged), so money fields that changed elsewhere
  /// in the meantime are not overwritten with stale values.
  Future<void> updateDebt(Debt debt, {List<Installment>? schedule});

  Future<void> recordPayment({
    required String debtId,
    required Money amount,
    required DateTime paidAt,
    int? installmentSeq,
    String? note,
  });

  Future<void> deletePayment({
    required String debtId,
    required String paymentId,
  });

  Future<void> setArchived(String debtId, {required bool archived});

  /// Deletes the debt with its installments and payments.
  Future<void> deleteDebt(String debtId);
}

/// Reads current state with `get()` and writes with a batch.
///
/// Batches, not transactions: transactions need a connection, and this must
/// work offline. Writes are started but not awaited, because Firestore only
/// completes a commit once the server answers. The UI follows the local
/// streams instead; rejected writes show up on [writeErrors].
class DebtRepositoryImpl implements DebtRepository {
  DebtRepositoryImpl(
    this._dataSource, {
    required String Function() currentUid,
    DateTime Function()? now,
  }) : _currentUid = currentUid,
       _now = now ?? DateTime.now;

  final DebtDataSource _dataSource;
  final String Function() _currentUid;
  final DateTime Function() _now;
  final _errors = StreamController<Object>.broadcast();

  @override
  Stream<Object> get writeErrors => _errors.stream;

  @override
  Stream<List<Debt>> watchDebts() => _dataSource
      .watchDebts(_currentUid())
      .map(
        (docs) =>
            [for (final d in docs) debtFromMap(d.id, d.data)]
              ..sort(_byDueThenName),
      );

  @override
  Stream<Debt?> watchDebt(String debtId) => _dataSource
      .watchDebt(_currentUid(), debtId)
      .map((d) => d == null ? null : debtFromMap(d.id, d.data));

  @override
  Stream<List<Installment>> watchInstallments(String debtId) => _dataSource
      .watchInstallments(_currentUid(), debtId)
      .map(
        (docs) =>
            [for (final d in docs) installmentFromMap(d.data)]
              ..sort((a, b) => a.seq.compareTo(b.seq)),
      );

  @override
  Stream<List<Payment>> watchPayments(String debtId) => _dataSource
      .watchPayments(_currentUid(), debtId)
      .map(
        (docs) =>
            [for (final d in docs) paymentFromMap(d.id, d.data)]
              ..sort(_paymentOrder),
      );

  @override
  Future<String> addDebt(NewDebt input) async {
    final uid = _currentUid();
    final now = _now();
    final plan = planDebt(
      principal: input.principal,
      interestType: input.interestType,
      interestRate: input.interestRate,
      adminFee: input.adminFee,
      frequency: input.frequency,
      startDate: input.startDate,
      tenorCount: input.tenorCount,
      firstDueDate: input.firstDueDate,
    );
    final installments = plan.installments;

    final id = _dataSource.newDebtId(uid);
    final debt = Debt(
      id: id,
      direction: input.direction,
      kind: input.kind,
      counterpartyName: input.counterpartyName.trim(),
      note: _cleanNote(input.note),
      principal: input.principal,
      interestType: input.interestType,
      interestRate: input.interestRate,
      adminFee: input.adminFee,
      tenorCount: input.tenorCount,
      frequency: plan.frequency,
      startDate: input.startDate,
      totalPayable: plan.totalPayable,
      paidTotal: Money.zero,
      remaining: plan.totalPayable,
      nextDueDate: nextDueDate(installments),
      status: DebtStatus.active,
      createdAt: now,
      updatedAt: now,
    );

    _commit([
      SetOp(FirestorePaths.debt(uid, id), debtToMap(debt)),
      ..._installmentOps(uid, id, installments),
    ]);
    return id;
  }

  @override
  Future<void> updateDebt(Debt debt, {List<Installment>? schedule}) async {
    final uid = _currentUid();
    final now = _now();
    if (schedule == null) {
      _commit([
        MergeOp(
          FirestorePaths.debt(uid, debt.id),
          debtNamePatch(debt.copyWith(updatedAt: now)),
        ),
      ]);
      return;
    }

    final payments = await _loadPayments(uid, debt.id);
    final oldInstallments = await _dataSource.getInstallments(uid, debt.id);
    final state = replayPayments(
      debt: debt,
      installments: schedule,
      payments: payments,
      now: now,
    );
    final keep = {for (final i in state.installments) i.seq};
    _commit([
      SetOp(
        FirestorePaths.debt(uid, debt.id),
        debtToMap(state.debt.copyWith(updatedAt: now)),
      ),
      ..._installmentOps(uid, debt.id, state.installments),
      for (final old in oldInstallments)
        if (!keep.contains(installmentFromMap(old.data).seq))
          DeleteOp('${FirestorePaths.installments(uid, debt.id)}/${old.id}'),
    ]);
  }

  @override
  Future<void> recordPayment({
    required String debtId,
    required Money amount,
    required DateTime paidAt,
    int? installmentSeq,
    String? note,
  }) async {
    final uid = _currentUid();
    final now = _now();
    final state = await _loadState(uid, debtId);
    final existing = await _loadPayments(uid, debtId);
    final payment = Payment(
      id: _dataSource.newPaymentId(uid, debtId),
      amount: amount,
      paidAt: paidAt,
      installmentSeq: installmentSeq,
      note: _cleanNote(note),
      createdAt: now,
    );

    final result = applyPayment(
      state: state,
      existing: existing,
      payment: payment,
      now: now,
    );

    _commit([
      SetOp(
        FirestorePaths.payment(uid, debtId, payment.id),
        paymentToMap(payment),
      ),
      ..._installmentOps(
        uid,
        debtId,
        _changed(state.installments, result.installments),
      ),
      SetOp(
        FirestorePaths.debt(uid, debtId),
        debtToMap(result.debt.copyWith(updatedAt: now)),
      ),
    ]);
  }

  @override
  Future<void> deletePayment({
    required String debtId,
    required String paymentId,
  }) async {
    final uid = _currentUid();
    final now = _now();
    final state = await _loadState(uid, debtId);
    final existing = await _loadPayments(uid, debtId);

    final result = revertPayment(
      state: state,
      existing: existing,
      paymentId: paymentId,
      now: now,
    );

    _commit([
      DeleteOp(FirestorePaths.payment(uid, debtId, paymentId)),
      ..._installmentOps(
        uid,
        debtId,
        _changed(state.installments, result.installments),
      ),
      SetOp(
        FirestorePaths.debt(uid, debtId),
        debtToMap(result.debt.copyWith(updatedAt: now)),
      ),
    ]);
  }

  @override
  Future<void> setArchived(String debtId, {required bool archived}) async {
    final uid = _currentUid();
    final debt = (await _loadState(uid, debtId)).debt;
    final restored = debt.remaining.isZero
        ? DebtStatus.settled
        : DebtStatus.active;
    _commit([
      SetOp(
        FirestorePaths.debt(uid, debtId),
        debtToMap(
          debt.copyWith(
            status: archived ? DebtStatus.archived : restored,
            updatedAt: _now(),
          ),
        ),
      ),
    ]);
  }

  @override
  Future<void> deleteDebt(String debtId) async {
    final uid = _currentUid();
    final installments = await _dataSource.getInstallments(uid, debtId);
    final payments = await _dataSource.getPayments(uid, debtId);
    _commit([
      for (final p in payments)
        DeleteOp('${FirestorePaths.payments(uid, debtId)}/${p.id}'),
      for (final i in installments)
        DeleteOp('${FirestorePaths.installments(uid, debtId)}/${i.id}'),
      DeleteOp(FirestorePaths.debt(uid, debtId)),
    ]);
  }

  Future<DebtState> _loadState(String uid, String debtId) async {
    final raw = await _dataSource.getDebt(uid, debtId);
    if (raw == null) throw DebtNotFound(debtId);
    final installments = await _dataSource.getInstallments(uid, debtId);
    return DebtState(
      debt: debtFromMap(raw.id, raw.data),
      installments: [for (final i in installments) installmentFromMap(i.data)]
        ..sort((a, b) => a.seq.compareTo(b.seq)),
    );
  }

  Future<List<Payment>> _loadPayments(String uid, String debtId) async {
    final raw = await _dataSource.getPayments(uid, debtId);
    return [for (final p in raw) paymentFromMap(p.id, p.data)];
  }

  /// Only the installments whose stored values differ from [before]; a long
  /// schedule would otherwise be rewritten in full for every payment.
  static List<Installment> _changed(
    List<Installment> before,
    List<Installment> after,
  ) {
    final old = {for (final i in before) i.seq: i};
    return [
      for (final i in after)
        if (old[i.seq] != i) i,
    ];
  }

  List<WriteOp> _installmentOps(
    String uid,
    String debtId,
    List<Installment> installments,
  ) => [
    for (final i in installments)
      SetOp(
        FirestorePaths.installment(uid, debtId, i.seq),
        installmentToMap(i),
      ),
  ];

  /// Starts the writes without waiting for the server (see class docs).
  void _commit(List<WriteOp> ops) {
    unawaited(
      _dataSource.write(ops).catchError((Object error, StackTrace stack) {
        developer.log(
          'Firestore write failed',
          name: 'DebtRepository',
          error: error,
          stackTrace: stack,
        );
        if (!_errors.isClosed) _errors.add(error);
      }),
    );
  }

  static String? _cleanNote(String? note) {
    final trimmed = note?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static int _byDueThenName(Debt a, Debt b) {
    final ad = a.nextDueDate;
    final bd = b.nextDueDate;
    if (ad != null && bd != null) {
      final byDate = ad.compareTo(bd);
      if (byDate != 0) return byDate;
    } else if (ad != null) {
      return -1;
    } else if (bd != null) {
      return 1;
    }
    return a.counterpartyName.toLowerCase().compareTo(
      b.counterpartyName.toLowerCase(),
    );
  }

  static int _paymentOrder(Payment a, Payment b) {
    final byPaid = a.paidAt.compareTo(b.paidAt);
    if (byPaid != 0) return byPaid;
    final epoch = DateTime.fromMillisecondsSinceEpoch(0);
    return (a.createdAt ?? epoch).compareTo(b.createdAt ?? epoch);
  }
}
