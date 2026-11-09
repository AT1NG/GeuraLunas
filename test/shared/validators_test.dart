import 'package:flutter_test/flutter_test.dart';
import 'package:geuralunas/shared/validators.dart';

void main() {
  group('validateEmail', () {
    test('empty is required', () {
      expect(validateEmail(''), ValidationError.required);
      expect(validateEmail(null), ValidationError.required);
    });
    test('trims and ignores case', () {
      expect(validateEmail(' Rani@Mail.COM '), isNull);
    });
    test('missing domain is invalid', () {
      expect(validateEmail('rani@'), ValidationError.invalidEmail);
    });
  });

  group('validatePassword', () {
    test('7 chars too short', () {
      expect(validatePassword('1234567'), ValidationError.passwordTooShort);
    });
    test('8 chars valid', () {
      expect(validatePassword('12345678'), isNull);
    });
    test('empty is required', () {
      expect(validatePassword(''), ValidationError.required);
    });
  });

  group('validateName', () {
    test('whitespace only is required', () {
      expect(validateName('  '), ValidationError.required);
    });
    test('name is valid', () {
      expect(validateName('Rani'), isNull);
    });
  });
}
