import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/order_whatsapp_helpers.dart';
import 'package:tfg_vday/backend/schema/orders_record.dart';

import 'firebase_test_setup.dart';

OrdersRecord _order(Map<String, dynamic> data) {
  return OrdersRecord.getDocumentFromData(
    data,
    OrdersRecord.collection.doc('test-order'),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  group('buildOrderConfirmationWhatsAppMessage', () {
    test('includes order id for delivery orders', () {
      final message = buildOrderConfirmationWhatsAppMessage(
        _order({
          'Order_Id': 'TFG-JUN26-00018',
          'pickup_delivery': 'Delivery',
        }),
      );
      expect(message, contains('Order ID: TFG-JUN26-00018'));
      expect(message, contains('Thank you for your purchase'));
      expect(message.toLowerCase(), isNot(contains('pickup order')));
    });

    test('includes pickup instructions for pickup orders', () {
      final message = buildOrderConfirmationWhatsAppMessage(
        _order({
          'Order_Id': 'TFG-JUN26-00019',
          'pickup_delivery': 'PickUp',
        }),
      );
      expect(message, contains('Order ID: TFG-JUN26-00019'));
      expect(
        message,
        contains(
          'This is a pickup order. Please show your Order ID to our staff when you collect your order.',
        ),
      );
    });
  });

  group('buildWhatsAppBusinessSendUri', () {
    test('uses WhatsApp Business send URL with encoded message', () {
      final uri = buildWhatsAppBusinessSendUri(
        phone: '6591234567',
        message: 'Hello & thanks',
      );
      expect(uri.scheme, 'https');
      expect(uri.host, 'api.whatsapp.com');
      expect(uri.path, '/send');
      expect(uri.queryParameters['phone'], '6591234567');
      expect(uri.queryParameters['text'], 'Hello & thanks');
    });
  });

  group('normalizeWhatsAppPhoneNumber', () {
    test('normalizes Singapore mobile without country code', () {
      expect(normalizeWhatsAppPhoneNumber('9123 4567'), '6591234567');
    });

    test('keeps international number with plus', () {
      expect(normalizeWhatsAppPhoneNumber('+6591234567'), '6591234567');
    });

    test('returns null for empty input', () {
      expect(normalizeWhatsAppPhoneNumber(''), isNull);
      expect(normalizeWhatsAppPhoneNumber('NA'), isNull);
    });
  });
}
