import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/payment_method_helpers.dart';

void main() {
  group('isCreditPaymentType', () {
    test('detects credit payment types', () {
      expect(isCreditPaymentType('Credit 15 days'), isTrue);
      expect(isCreditPaymentType('Credit Cash on delivery'), isTrue);
      expect(isCreditPaymentType('Cash'), isFalse);
    });
  });

  group('parseCustomCreditTerm', () {
    test('parses day counts and COD', () {
      expect(parseCustomCreditTerm('45'), 'Credit 45 days');
      expect(parseCustomCreditTerm('60 days'), 'Credit 60 days');
      expect(parseCustomCreditTerm('cash on delivery'),
          'Credit Cash on delivery');
      expect(parseCustomCreditTerm('COD'), 'Credit Cash on delivery');
    });

    test('passes through free-form custom labels', () {
      expect(parseCustomCreditTerm('Net 7'), 'Credit Net 7');
    });
  });

  group('creditTermShortLabel', () {
    test('shortens stored credit payment labels', () {
      expect(creditTermShortLabel('Credit 15 days'), '15 days');
      expect(creditTermShortLabel('Credit Cash on delivery'), 'COD');
    });
  });
}
