T _parse<T extends Enum>(
  List<T> values,
  String Function(T) wire,
  String value,
  String name,
) {
  for (final v in values) {
    if (wire(v) == value) return v;
  }
  throw ArgumentError.value(value, name, 'unknown value');
}

/// Who owes whom.
enum DebtDirection {
  /// I owe someone.
  owe('owe'),

  /// Someone owes me.
  lent('lent')
  ;

  const DebtDirection(this.wire);

  /// Value stored in Firestore.
  final String wire;

  /// Parses a stored value; throws [ArgumentError] if unknown.
  static DebtDirection fromWire(String value) =>
      _parse(values, (e) => e.wire, value, 'DebtDirection');
}

/// Kind of debt.
enum DebtKind {
  pinjol('pinjol'),
  installment('installment'),
  personal('personal')
  ;

  const DebtKind(this.wire);

  final String wire;

  static DebtKind fromWire(String value) =>
      _parse(values, (e) => e.wire, value, 'DebtKind');
}

/// How interest is calculated.
enum InterestType {
  none('none'),
  flatMonthly('flat_monthly'),
  flatDaily('flat_daily'),
  reducingMonthly('reducing_monthly')
  ;

  const InterestType(this.wire);

  final String wire;

  static InterestType fromWire(String value) =>
      _parse(values, (e) => e.wire, value, 'InterestType');
}

/// Payment frequency.
enum Frequency {
  monthly('monthly'),
  weekly('weekly'),
  once('once')
  ;

  const Frequency(this.wire);

  final String wire;

  static Frequency fromWire(String value) =>
      _parse(values, (e) => e.wire, value, 'Frequency');
}

/// Stored status of a debt. "Overdue" is derived, never stored.
enum DebtStatus {
  active('active'),
  settled('settled'),
  archived('archived')
  ;

  const DebtStatus(this.wire);

  final String wire;

  static DebtStatus fromWire(String value) =>
      _parse(values, (e) => e.wire, value, 'DebtStatus');
}

/// Status of one installment.
enum InstallmentStatus {
  pending('pending'),
  partial('partial'),
  paid('paid')
  ;

  const InstallmentStatus(this.wire);

  final String wire;

  static InstallmentStatus fromWire(String value) =>
      _parse(values, (e) => e.wire, value, 'InstallmentStatus');
}
