import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/domain/money.dart';
import 'package:geuralunas/shared/parse_amount.dart';

void main() {
  group('parseAmount accepts', () {
    const valid = {
      '1.500.000': 1500000,
      '1500000': 1500000,
      'Rp 1.500.000': 1500000,
      'Rp1.500.000': 1500000,
      'rp1.500.000': 1500000,
      ' 2000 ': 2000,
      '1': 1,
      '999': 999,
      '1.000': 1000,
      '999.999.999.999': 999999999999,
      '999999999999': 999999999999,
    };
    for (final MapEntry(key: input, value: expected) in valid.entries) {
      test('"$input"', () {
        expect(parseAmount(input), Money(expected));
      });
    }
  });

  group('parseAmount rejects', () {
    const invalid = [
      '',
      '   ',
      'abc',
      '0',
      '000',
      '-5',
      '1.5',
      '1.50.000',
      '1,500',
      '1.000.000.000.000',
      '1000000000000',
      'Rp',
      '12a',
      '1 000',
    ];
    for (final input in invalid) {
      test('"$input"', () {
        expect(parseAmount(input), isNull);
      });
    }
  });

  group('allowZero', () {
    test('accepts zero', () {
      expect(parseAmount('0', allowZero: true), Money.zero);
      expect(parseAmount('Rp 0', allowZero: true), Money.zero);
    });

    test('still rejects garbage and negatives', () {
      expect(parseAmount('x', allowZero: true), isNull);
      expect(parseAmount('-1', allowZero: true), isNull);
    });
  });

  group('parseRate', () {
    test('accepts whole numbers and decimals with dot or comma', () {
      expect(parseRate('3'), 3.0);
      expect(parseRate('0.4'), 0.4);
      expect(parseRate('0,4'), 0.4);
      expect(parseRate(' 1,5 '), 1.5);
      expect(parseRate('0'), 0.0);
    });

    test('rejects blank, negative, text and out of range', () {
      expect(parseRate(''), isNull);
      expect(parseRate('-1'), isNull);
      expect(parseRate('abc'), isNull);
      expect(parseRate('1000.5'), isNull);
      expect(parseRate('1,2,3'), isNull);
    });
  });

  group('formatThousands', () {
    test('groups digits with dots', () {
      expect(formatThousands('1500000'), '1.500.000');
      expect(formatThousands('999'), '999');
      expect(formatThousands('1000'), '1.000');
      expect(formatThousands(''), '');
    });

    test('keeps only digits', () {
      expect(formatThousands('Rp 1.500.000'), '1.500.000');
      expect(formatThousands('abc'), '');
    });
  });
}
