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

  group('formatPaymentMethodLabel', () {
    test('formats cash and credit labels', () {
      expect(formatPaymentMethodLabel('Cash'), 'Cash');
      expect(formatPaymentMethodLabel('Credit 30 days'), '30 days');
      expect(formatPaymentMethodLabel(''), 'Not set');
    });
  });

  group('creditTermShortLabel', () {
    test('shortens stored credit payment labels', () {
      expect(creditTermShortLabel('Credit 15 days'), '15 days');
      expect(creditTermShortLabel('Credit Cash on delivery'), 'COD');
    });
  });

  group('payment amount entry helpers', () {
    test('requires amount dialog for Cash PayNow and Card', () {
      expect(requiresPaymentAmountEntry('Cash'), isTrue);
      expect(requiresPaymentAmountEntry('Paynow'), isTrue);
      expect(requiresPaymentAmountEntry('Card'), isTrue);
      expect(requiresPaymentAmountEntry('Shopify'), isFalse);
      expect(requiresPaymentAmountEntry('Credit 15 days'), isFalse);
    });

    test('uses exact amount for marketplace methods', () {
      expect(usesExactPaymentAmount('Shopify'), isTrue);
      expect(usesExactPaymentAmount('Shopee'), isTrue);
      expect(usesExactPaymentAmount('Paynow'), isFalse);
    });

    test('formats Paynow label for dialogs', () {
      expect(paymentMethodLabel('Paynow'), 'PayNow');
      expect(paymentMethodLabel('Cash'), 'Cash');
    });
  });
}
