import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/shared/formatters/rupiah.dart';

void main() {
  setUpAll(initializeFormatting);

  group('formatRupiah', () {
    test('formats thousands with dots', () {
      expect(formatRupiah(const Money(1250000)), 'Rp1.250.000');
    });

    test('formats zero', () {
      expect(formatRupiah(Money.zero), 'Rp0');
    });

    test('formats values below one thousand', () {
      expect(formatRupiah(const Money(950)), 'Rp950');
    });

    test('puts minus sign before Rp for negatives', () {
      expect(formatRupiah(const Money(-1000)), '-Rp1.000');
    });

    test('formats very large values', () {
      expect(formatRupiah(const Money(999999999999)), 'Rp999.999.999.999');
    });
  });

  group('formatDate', () {
    test('formats day, short Indonesian month, year', () {
      expect(formatDate(DateTime(2026, 11, 9)), '9 Nov 2026');
    });
  });

  test('formats a very large negative amount', () {
    expect(formatRupiah(const Money(-999999999999)), '-Rp999.999.999.999');
  });
}
