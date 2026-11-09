import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geuralunas/domain/debt/debt.dart';
import 'package:geuralunas/domain/debt/debt_enums.dart';
import 'package:geuralunas/domain/debt/debt_plan.dart';
import 'package:geuralunas/domain/debt/payments.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/features/auth/bloc/submit_status.dart';
import 'package:geuralunas/repositories/debt_repository.dart';
import 'package:geuralunas/shared/parse_amount.dart';

/// Form fields that can show an error.
enum DebtFormField { name, principal, interestRate, adminFee, tenor }

/// Why a field is not acceptable. The page turns these into text.
enum DebtFormError { required, invalidAmount, invalidNumber, belowPaid }

/// Why saving failed.
enum DebtFormFailure { unknown, belowPaid }

/// Tenor limit: 100 years of monthly installments.
const _maxTenor = 1200;

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String _plainNumber(double value) =>
    value == value.truncateToDouble() ? value.toInt().toString() : '$value';

class _Evaluation {
  _Evaluation({
    required this.errors,
    this.plan,
    this.principal,
    this.rate = 0,
    this.fee = Money.zero,
    this.tenor,
  });

  final Map<DebtFormField, DebtFormError> errors;
  final DebtPlan? plan;
  final Money? principal;
  final double rate;
  final Money fee;
  final int? tenor;
}

final class DebtFormState extends Equatable {
  DebtFormState({
    required this.startDate,
    this.direction = DebtDirection.owe,
    this.kind = DebtKind.pinjol,
    this.name = '',
    this.note = '',
    this.principal = '',
    this.interestType = InterestType.none,
    this.interestRate = '',
    this.adminFee = '',
    this.tenor = '',
    this.frequency = Frequency.monthly,
    this.firstDueDate,
    this.paidTotal = Money.zero,
    this.showErrors = false,
    this.status = SubmitStatus.idle,
    this.failure,
  });

  final DebtDirection direction;
  final DebtKind kind;
  final String name;
  final String note;
  final String principal;
  final InterestType interestType;
  final String interestRate;
  final String adminFee;

  /// Installments, or days for `flat_daily`.
  final String tenor;
  final Frequency frequency;
  final DateTime startDate;
  final DateTime? firstDueDate;

  /// What was already paid, when editing. The total cannot go below it.
  final Money paidTotal;

  /// Field errors are shown only after the first save attempt.
  final bool showErrors;
  final SubmitStatus status;
  final DebtFormFailure? failure;

  late final _Evaluation _eval = _evaluate();

  bool get isPersonal => kind == DebtKind.personal;

  /// A personal debt never carries interest.
  InterestType get effectiveInterestType =>
      isPersonal ? InterestType.none : interestType;

  Map<DebtFormField, DebtFormError> get errors => _eval.errors;

  /// Total and schedule for the current input; `null` until it is valid.
  DebtPlan? get plan => _eval.plan;

  Money? get principalValue => _eval.principal;
  double get rateValue => _eval.rate;
  Money get feeValue => _eval.fee;
  int? get tenorValue => _eval.tenor;

  Frequency get effectiveFrequency => isPersonal ? Frequency.once : frequency;

  _Evaluation _evaluate() {
    final errors = <DebtFormField, DebtFormError>{};
    if (name.trim().isEmpty) {
      errors[DebtFormField.name] = DebtFormError.required;
    }

    Money? principalMoney;
    if (principal.trim().isEmpty) {
      errors[DebtFormField.principal] = DebtFormError.required;
    } else {
      principalMoney = parseAmount(principal);
      if (principalMoney == null) {
        errors[DebtFormField.principal] = DebtFormError.invalidAmount;
      }
    }

    var rate = 0.0;
    if (effectiveInterestType != InterestType.none) {
      if (interestRate.trim().isEmpty) {
        errors[DebtFormField.interestRate] = DebtFormError.required;
      } else {
        final parsed = parseRate(interestRate);
        if (parsed == null) {
          errors[DebtFormField.interestRate] = DebtFormError.invalidNumber;
        } else {
          rate = parsed;
        }
      }
    }

    var fee = Money.zero;
    int? tenorCount;
    if (!isPersonal) {
      if (adminFee.trim().isNotEmpty) {
        final parsed = parseAmount(adminFee, allowZero: true);
        if (parsed == null) {
          errors[DebtFormField.adminFee] = DebtFormError.invalidAmount;
        } else {
          fee = parsed;
        }
      }
      final text = tenor.trim();
      if (text.isEmpty) {
        if (effectiveInterestType != InterestType.none) {
          errors[DebtFormField.tenor] = DebtFormError.required;
        }
      } else {
        final parsed = int.tryParse(text);
        if (parsed == null || parsed < 1 || parsed > _maxTenor) {
          errors[DebtFormField.tenor] = DebtFormError.invalidNumber;
        } else {
          tenorCount = parsed;
        }
      }
    }

    DebtPlan? plan;
    // The preview only depends on the money terms, so a missing name must
    // not hide it.
    final moneyTermsOk = errors.keys.every((k) => k == DebtFormField.name);
    if (moneyTermsOk && principalMoney != null) {
      plan = planDebt(
        principal: principalMoney,
        interestType: effectiveInterestType,
        interestRate: rate,
        adminFee: fee,
        frequency: effectiveFrequency,
        startDate: startDate,
        tenorCount: tenorCount,
        firstDueDate: firstDueDate,
      );
      if (paidTotal.rupiah > 0 && plan.totalPayable.rupiah < paidTotal.rupiah) {
        errors[DebtFormField.principal] = DebtFormError.belowPaid;
      }
    }

    return _Evaluation(
      errors: errors,
      plan: plan,
      principal: principalMoney,
      rate: rate,
      fee: fee,
      tenor: tenorCount,
    );
  }

  DebtFormState copyWith({
    DebtDirection? direction,
    DebtKind? kind,
    String? name,
    String? note,
    String? principal,
    InterestType? interestType,
    String? interestRate,
    String? adminFee,
    String? tenor,
    Frequency? frequency,
    DateTime? startDate,
    DateTime? firstDueDate,
    bool clearFirstDueDate = false,
    bool? showErrors,
    SubmitStatus? status,
    DebtFormFailure? failure,
    bool clearFailure = false,
  }) => DebtFormState(
    direction: direction ?? this.direction,
    kind: kind ?? this.kind,
    name: name ?? this.name,
    note: note ?? this.note,
    principal: principal ?? this.principal,
    interestType: interestType ?? this.interestType,
    interestRate: interestRate ?? this.interestRate,
    adminFee: adminFee ?? this.adminFee,
    tenor: tenor ?? this.tenor,
    frequency: frequency ?? this.frequency,
    startDate: startDate ?? this.startDate,
    firstDueDate: clearFirstDueDate ? null : firstDueDate ?? this.firstDueDate,
    paidTotal: paidTotal,
    showErrors: showErrors ?? this.showErrors,
    status: status ?? this.status,
    failure: clearFailure ? null : failure ?? this.failure,
  );

  @override
  List<Object?> get props => [
    direction,
    kind,
    name,
    note,
    principal,
    interestType,
    interestRate,
    adminFee,
    tenor,
    frequency,
    startDate,
    firstDueDate,
    paidTotal,
    showErrors,
    status,
    failure,
  ];
}

class DebtFormCubit extends Cubit<DebtFormState> {
  DebtFormCubit(this._repository, {Debt? editing, DateTime Function()? now})
    : _editing = editing,
      super(
        editing == null
            ? DebtFormState(startDate: _dateOnly((now ?? DateTime.now)()))
            : _fromDebt(editing),
      );

  final DebtRepository _repository;
  final Debt? _editing;

  static DebtFormState _fromDebt(Debt d) => DebtFormState(
    direction: d.direction,
    kind: d.kind,
    name: d.counterpartyName,
    note: d.note ?? '',
    principal: d.principal.rupiah.toString(),
    interestType: d.interestType,
    interestRate: d.interestRate == 0 ? '' : _plainNumber(d.interestRate),
    adminFee: d.adminFee.isZero ? '' : d.adminFee.rupiah.toString(),
    tenor: d.tenorCount?.toString() ?? '',
    frequency: d.frequency,
    startDate: _dateOnly(d.startDate),
    paidTotal: d.paidTotal,
  );

  /// The screen can be closed while a save is in flight; a late result must
  /// not throw.
  @override
  void emit(DebtFormState state) {
    if (!isClosed) super.emit(state);
  }

  void directionChanged(DebtDirection v) => emit(state.copyWith(direction: v));

  void kindChanged(DebtKind v) {
    if (v == DebtKind.personal) {
      emit(
        state.copyWith(
          kind: v,
          interestType: InterestType.none,
          interestRate: '',
          adminFee: '',
          tenor: '',
          frequency: Frequency.monthly,
        ),
      );
    } else {
      emit(state.copyWith(kind: v));
    }
  }

  void nameChanged(String v) => emit(state.copyWith(name: v));

  void noteChanged(String v) => emit(state.copyWith(note: v));

  void principalChanged(String v) => emit(state.copyWith(principal: v));

  void interestTypeChanged(InterestType v) =>
      emit(state.copyWith(interestType: v));

  void rateChanged(String v) => emit(state.copyWith(interestRate: v));

  void adminFeeChanged(String v) => emit(state.copyWith(adminFee: v));

  void tenorChanged(String v) => emit(state.copyWith(tenor: v));

  void frequencyChanged(Frequency v) => emit(state.copyWith(frequency: v));

  void startDateChanged(DateTime v) =>
      emit(state.copyWith(startDate: _dateOnly(v)));

  void firstDueDateChanged(DateTime? v) => emit(
    v == null
        ? state.copyWith(clearFirstDueDate: true)
        : state.copyWith(firstDueDate: _dateOnly(v)),
  );

  Future<void> submit() async {
    if (state.status == SubmitStatus.submitting) return;
    final plan = state.plan;
    if (state.errors.isNotEmpty || plan == null) {
      emit(state.copyWith(showErrors: true));
      return;
    }
    emit(state.copyWith(status: SubmitStatus.submitting, clearFailure: true));
    try {
      final editing = _editing;
      if (editing == null) {
        await _repository.addDebt(_newDebt());
      } else {
        await _update(editing, plan);
      }
      emit(state.copyWith(status: SubmitStatus.success));
    } on PaymentExceedsRemaining {
      emit(
        state.copyWith(
          status: SubmitStatus.failure,
          failure: DebtFormFailure.belowPaid,
        ),
      );
    } on Object {
      emit(
        state.copyWith(
          status: SubmitStatus.failure,
          failure: DebtFormFailure.unknown,
        ),
      );
    }
  }

  NewDebt _newDebt() {
    final s = state;
    return NewDebt(
      direction: s.direction,
      kind: s.kind,
      counterpartyName: s.name.trim(),
      note: s.note.trim().isEmpty ? null : s.note.trim(),
      principal: s.principalValue!,
      interestType: s.effectiveInterestType,
      interestRate: s.rateValue,
      adminFee: s.feeValue,
      tenorCount: s.tenorValue,
      frequency: s.effectiveFrequency,
      startDate: s.startDate,
      firstDueDate: s.firstDueDate,
    );
  }

  Future<void> _update(Debt editing, DebtPlan plan) {
    final s = state;
    final note = s.note.trim();
    final financeChanged =
        s.principalValue != editing.principal ||
        s.effectiveInterestType != editing.interestType ||
        s.rateValue != editing.interestRate ||
        s.feeValue != editing.adminFee ||
        s.tenorValue != editing.tenorCount ||
        plan.frequency != editing.frequency ||
        s.startDate != _dateOnly(editing.startDate) ||
        s.firstDueDate != null;

    var updated = editing.copyWith(
      counterpartyName: s.name.trim(),
      note: note,
      clearNote: note.isEmpty,
    );
    if (financeChanged) {
      updated = updated.copyWith(
        principal: s.principalValue,
        interestType: s.effectiveInterestType,
        interestRate: s.rateValue,
        adminFee: s.feeValue,
        tenorCount: s.tenorValue,
        clearTenorCount: s.tenorValue == null,
        frequency: plan.frequency,
        startDate: s.startDate,
        totalPayable: plan.totalPayable,
        clearNextDueDate: plan.installments.isEmpty,
      );
    }
    return _repository.updateDebt(
      updated,
      schedule: financeChanged ? plan.installments : null,
    );
  }
}
