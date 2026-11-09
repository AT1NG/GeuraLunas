import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/money.dart';

void main() {
  group('Money', () {
    test('adds', () {
      expect(const Money(100) + const Money(50), const Money(150));
    });

    test('subtracts to negative', () {
      expect((const Money(10) - const Money(30)).isNegative, isTrue);
    });

    test('negation', () {
      expect(-const Money(5), const Money(-5));
    });

    test('zero is zero', () {
      expect(Money.zero.isZero, isTrue);
      expect(const Money(1).isZero, isFalse);
    });

    test('equality by value', () {
      expect(const Money(7), const Money(7));
      expect(const Money(7).hashCode, const Money(7).hashCode);
      expect(const Money(7) == const Money(8), isFalse);
    });

    test('compares', () {
      expect(const Money(1).compareTo(const Money(2)), lessThan(0));
      expect(const Money(2).compareTo(const Money(1)), greaterThan(0));
      expect(const Money(2).compareTo(const Money(2)), 0);
    });
  });
}
