/// An amount of Indonesian rupiah, stored as a whole number.
///
/// Money is never a `double`: see `docs/DATABASE.md`.
final class Money implements Comparable<Money> {
  /// Creates an amount of [rupiah].
  const Money(this.rupiah);

  /// The zero amount.
  static const Money zero = Money(0);

  /// Whole rupiah.
  final int rupiah;

  /// Whether this amount is below zero.
  bool get isNegative => rupiah < 0;

  /// Whether this amount is exactly zero.
  bool get isZero => rupiah == 0;

  /// Sum of two amounts.
  Money operator +(Money other) => Money(rupiah + other.rupiah);

  /// Difference of two amounts; may be negative.
  Money operator -(Money other) => Money(rupiah - other.rupiah);

  /// The amount with its sign flipped.
  Money operator -() => Money(-rupiah);

  @override
  int compareTo(Money other) => rupiah.compareTo(other.rupiah);

  @override
  bool operator ==(Object other) => other is Money && other.rupiah == rupiah;

  @override
  int get hashCode => rupiah.hashCode;

  @override
  String toString() => 'Money($rupiah)';
}
