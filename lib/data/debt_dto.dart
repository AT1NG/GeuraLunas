import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/money.dart';

Timestamp _ts(DateTime d) => Timestamp.fromDate(d);

DateTime _dt(Object? v) => (v! as Timestamp).toDate();

DateTime? _dtOrNull(Object? v) => v == null ? null : _dt(v);

Money _money(Object? v) => Money((v! as num).toInt());

/// Firestore map for [debt]. Null optional fields are left out, never stored
/// as null, so a full `set` also removes them.
Map<String, Object?> debtToMap(Debt debt) => {
  'direction': debt.direction.wire,
  'kind': debt.kind.wire,
  'counterpartyName': debt.counterpartyName,
  if (debt.note != null) 'note': debt.note,
  'principal': debt.principal.rupiah,
  'interestType': debt.interestType.wire,
  'interestRate': debt.interestRate,
  'adminFee': debt.adminFee.rupiah,
  if (debt.tenorCount != null) 'tenorCount': debt.tenorCount,
  'frequency': debt.frequency.wire,
  'startDate': _ts(debt.startDate),
  'totalPayable': debt.totalPayable.rupiah,
  'paidTotal': debt.paidTotal.rupiah,
  'remaining': debt.remaining.rupiah,
  if (debt.nextDueDate != null) 'nextDueDate': _ts(debt.nextDueDate!),
  'status': debt.status.wire,
  'createdAt': _ts(debt.createdAt),
  'updatedAt': _ts(debt.updatedAt),
  if (debt.settledAt != null) 'settledAt': _ts(debt.settledAt!),
};

Debt debtFromMap(String id, Map<String, Object?> m) => Debt(
  id: id,
  direction: DebtDirection.fromWire(m['direction']! as String),
  kind: DebtKind.fromWire(m['kind']! as String),
  counterpartyName: m['counterpartyName']! as String,
  note: m['note'] as String?,
  principal: _money(m['principal']),
  interestType: InterestType.fromWire(m['interestType']! as String),
  interestRate: (m['interestRate']! as num).toDouble(),
  adminFee: _money(m['adminFee']),
  tenorCount: (m['tenorCount'] as num?)?.toInt(),
  frequency: Frequency.fromWire(m['frequency']! as String),
  startDate: _dt(m['startDate']),
  totalPayable: _money(m['totalPayable']),
  paidTotal: _money(m['paidTotal']),
  remaining: _money(m['remaining']),
  nextDueDate: _dtOrNull(m['nextDueDate']),
  status: DebtStatus.fromWire(m['status']! as String),
  createdAt: _dt(m['createdAt']),
  updatedAt: _dt(m['updatedAt']),
  settledAt: _dtOrNull(m['settledAt']),
);

Map<String, Object?> installmentToMap(Installment i) => {
  'seq': i.seq,
  'dueDate': _ts(i.dueDate),
  'amount': i.amount.rupiah,
  'paidAmount': i.paidAmount.rupiah,
  'status': i.status.wire,
  if (i.paidAt != null) 'paidAt': _ts(i.paidAt!),
};

Installment installmentFromMap(Map<String, Object?> m) => Installment(
  seq: (m['seq']! as num).toInt(),
  dueDate: _dt(m['dueDate']),
  amount: _money(m['amount']),
  paidAmount: _money(m['paidAmount']),
  status: InstallmentStatus.fromWire(m['status']! as String),
  paidAt: _dtOrNull(m['paidAt']),
);

Map<String, Object?> paymentToMap(Payment p) => {
  'amount': p.amount.rupiah,
  'paidAt': _ts(p.paidAt),
  if (p.installmentSeq != null) 'installmentSeq': p.installmentSeq,
  if (p.note != null) 'note': p.note,
  'createdAt': _ts(p.createdAt ?? p.paidAt),
};

Payment paymentFromMap(String id, Map<String, Object?> m) => Payment(
  id: id,
  amount: _money(m['amount']),
  paidAt: _dt(m['paidAt']),
  installmentSeq: (m['installmentSeq'] as num?)?.toInt(),
  note: m['note'] as String?,
  createdAt: _dtOrNull(m['createdAt']),
);
