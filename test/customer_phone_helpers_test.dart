import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/customer_helpers.dart';

void main() {
  group('isValidCustomerPhone', () {
    test('accepts Singapore local mobile', () {
      expect(isValidCustomerPhone('91234567'), isTrue);
      expect(isValidCustomerPhone('+65 9123 4567'), isTrue);
    });

    test('accepts international numbers with country code', () {
      expect(isValidCustomerPhone('+1 415 555 0100'), isTrue);
      expect(isValidCustomerPhone('+44 7911 123456'), isTrue);
      expect(isValidCustomerPhone('+61 412 345 678'), isTrue);
    });

    test('rejects too few digits', () {
      expect(isValidCustomerPhone('123456'), isFalse);
    });

    test('rejects too many digits', () {
      expect(isValidCustomerPhone('1' * 16), isFalse);
    });
  });

  group('validateCustomerPhoneInput', () {
    test('requires phone when configured', () {
      expect(validateCustomerPhoneInput(''), isNotNull);
      expect(validateCustomerPhoneInput(null), isNotNull);
    });

    test('allows empty when optional', () {
      expect(validateCustomerPhoneInput('', required: false), isNull);
    });
  });

  group('validateCustomerEmailInput', () {
    test('allows empty email', () {
      expect(validateCustomerEmailInput(''), isNull);
      expect(validateCustomerEmailInput(null), isNull);
    });

    test('accepts valid email', () {
      expect(validateCustomerEmailInput('guest@example.com'), isNull);
    });

    test('rejects invalid email', () {
      expect(validateCustomerEmailInput('not-an-email'), isNotNull);
    });
  });
}
