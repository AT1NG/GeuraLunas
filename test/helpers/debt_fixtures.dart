import 'dart:async';

import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/repositories/debt_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockDebtRepository extends Mock implements DebtRepository {}

Debt makeDebt({
  String id = 'd1',
  String name = 'Pinjol B',
  DebtDirection direction = DebtDirection.owe,
  DebtKind kind = DebtKind.pinjol,
  DebtStatus status = DebtStatus.active,
  int total = 2000000,
  int remaining = 1500000,
  DateTime? nextDue,
}) => Debt(
  id: id,
  direction: direction,
  kind: kind,
  counterpartyName: name,
  principal: Money(total),
  interestType: InterestType.none,
  interestRate: 0,
  adminFee: Money.zero,
  frequency: Frequency.monthly,
  startDate: DateTime(2026, 10),
  totalPayable: Money(total),
  paidTotal: Money(total - remaining),
  remaining: Money(remaining),
  nextDueDate: nextDue,
  status: status,
  createdAt: DateTime(2026, 10),
  updatedAt: DateTime(2026, 10),
);

/// In-memory repository for widget tests. Only `watchDebts` is implemented;
/// later tasks extend what is needed.
class FakeDebtRepository implements DebtRepository {
  FakeDebtRepository({
    List<Debt> debts = const [],
    Map<String, List<Installment>> installments = const {},
    Map<String, List<Payment>> payments = const {},
  }) : _debts = debts,
       _installments = installments,
       _payments = payments;

  List<Debt> _debts;
  final Map<String, List<Installment>> _installments;
  final Map<String, List<Payment>> _payments;
  final _controller = StreamController<List<Debt>>.broadcast();

  /// When set, `watchDebts` fails with this error.
  Object? streamError;

  void emit(List<Debt> debts) {
    _debts = debts;
    _controller.add(debts);
  }

  @override
  Stream<List<Debt>> watchDebts() {
    final error = streamError;
    if (error != null) return Stream<List<Debt>>.error(error);
    return () async* {
      yield _debts;
      yield* _controller.stream;
    }();
  }

  /// Set to make `addDebt` and `updateDebt` fail.
  Object? addError;

  NewDebt? added;
  Debt? updated;
  List<Installment>? updatedSchedule;

  @override
  Future<String> addDebt(NewDebt input) {
    final error = addError;
    if (error != null) return Future<String>.error(error);
    added = input;
    return Future.value('new-id');
  }

  @override
  Future<void> updateDebt(Debt debt, {List<Installment>? schedule}) {
    final error = addError;
    if (error != null) return Future<void>.error(error);
    updated = debt;
    updatedSchedule = schedule;
    return Future.value();
  }

  @override
  Stream<Debt?> watchDebt(String debtId) =>
      Stream.value(_debts.where((d) => d.id == debtId).firstOrNull);

  @override
  Stream<List<Installment>> watchInstallments(String debtId) =>
      Stream.value(_installments[debtId] ?? const []);

  @override
  Stream<List<Payment>> watchPayments(String debtId) =>
      Stream.value(_payments[debtId] ?? const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError(
    'FakeDebtRepository.${invocation.memberName} is not implemented',
  );
}
