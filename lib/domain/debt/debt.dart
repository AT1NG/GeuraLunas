import 'package:equatable/equatable.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/money.dart';

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// One scheduled installment of a [Debt].
final class Installment extends Equatable {
  const Installment({
    required this.seq,
    required this.dueDate,
    required this.amount,
    this.paidAmount = Money.zero,
    this.status = InstallmentStatus.pending,
    this.paidAt,
  });

  /// 1-based order within the debt.
  final int seq;
  final DateTime dueDate;
  final Money amount;
  final Money paidAmount;
  final InstallmentStatus status;
  final DateTime? paidAt;

  Installment copyWith({
    Money? paidAmount,
    InstallmentStatus? status,
    DateTime? paidAt,
    bool clearPaidAt = false,
  }) => Installment(
    seq: seq,
    dueDate: dueDate,
    amount: amount,
    paidAmount: paidAmount ?? this.paidAmount,
    status: status ?? this.status,
    paidAt: clearPaidAt ? null : paidAt ?? this.paidAt,
  );

  @override
  List<Object?> get props => [
    seq,
    dueDate,
    amount,
    paidAmount,
    status,
    paidAt,
  ];
}

/// A recorded payment. For a `lent` debt it means "received".
final class Payment extends Equatable {
  const Payment({
    required this.id,
    required this.amount,
    required this.paidAt,
    this.installmentSeq,
    this.note,
    this.createdAt,
  });

  final String id;
  final Money amount;
  final DateTime paidAt;
  final int? installmentSeq;
  final String? note;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
    id,
    amount,
    paidAt,
    installmentSeq,
    note,
    createdAt,
  ];
}

/// A debt or receivable (see `docs/DATABASE.md` 3.2).
final class Debt extends Equatable {
  const Debt({
    required this.id,
    required this.direction,
    required this.kind,
    required this.counterpartyName,
    required this.principal,
    required this.interestType,
    required this.interestRate,
    required this.adminFee,
    required this.frequency,
    required this.startDate,
    required this.totalPayable,
    required this.paidTotal,
    required this.remaining,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.note,
    this.tenorCount,
    this.nextDueDate,
    this.settledAt,
  });

  final String id;
  final DebtDirection direction;
  final DebtKind kind;
  final String counterpartyName;
  final String? note;
  final Money principal;
  final InterestType interestType;

  /// Percent per period; 0 when [interestType] is `none`.
  final double interestRate;
  final Money adminFee;
  final int? tenorCount;
  final Frequency frequency;
  final DateTime startDate;
  final Money totalPayable;
  final Money paidTotal;
  final Money remaining;
  final DateTime? nextDueDate;
  final DebtStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? settledAt;

  /// Overdue is derived: active and the next due date is before today.
  bool isOverdue(DateTime today) {
    final due = nextDueDate;
    if (status != DebtStatus.active || due == null) return false;
    return _dateOnly(due).isBefore(_dateOnly(today));
  }

  Debt copyWith({
    String? counterpartyName,
    String? note,
    Money? principal,
    InterestType? interestType,
    double? interestRate,
    Money? adminFee,
    int? tenorCount,
    Frequency? frequency,
    DateTime? startDate,
    Money? totalPayable,
    Money? paidTotal,
    Money? remaining,
    DateTime? nextDueDate,
    DebtStatus? status,
    DateTime? updatedAt,
    DateTime? settledAt,
    bool clearNextDueDate = false,
    bool clearSettledAt = false,
  }) => Debt(
    id: id,
    direction: direction,
    kind: kind,
    counterpartyName: counterpartyName ?? this.counterpartyName,
    note: note ?? this.note,
    principal: principal ?? this.principal,
    interestType: interestType ?? this.interestType,
    interestRate: interestRate ?? this.interestRate,
    adminFee: adminFee ?? this.adminFee,
    tenorCount: tenorCount ?? this.tenorCount,
    frequency: frequency ?? this.frequency,
    startDate: startDate ?? this.startDate,
    totalPayable: totalPayable ?? this.totalPayable,
    paidTotal: paidTotal ?? this.paidTotal,
    remaining: remaining ?? this.remaining,
    nextDueDate: clearNextDueDate ? null : nextDueDate ?? this.nextDueDate,
    status: status ?? this.status,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    settledAt: clearSettledAt ? null : settledAt ?? this.settledAt,
  );

  @override
  List<Object?> get props => [
    id,
    direction,
    kind,
    counterpartyName,
    note,
    principal,
    interestType,
    interestRate,
    adminFee,
    tenorCount,
    frequency,
    startDate,
    totalPayable,
    paidTotal,
    remaining,
    nextDueDate,
    status,
    createdAt,
    updatedAt,
    settledAt,
  ];
}
