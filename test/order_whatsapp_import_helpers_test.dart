import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/order_whatsapp_import_helpers.dart';

void main() {
  group('extractOrderIdFromWhatsAppText', () {
    test('reads Order ID from confirmation message', () {
      const text = '''
Thank you for your purchase. Your order is confirmed.

Order ID: TFG-JUN26-00018

This is a pickup order. Please show your Order ID to our staff when you collect your order.
''';
      expect(
        extractOrderIdFromWhatsAppText(text),
        'TFG-JUN26-00018',
      );
    });

    test('finds bare TFG id in text', () {
      expect(
        extractOrderIdFromWhatsAppText('Please check TFG-MAR26-WI0003 thanks'),
        'TFG-MAR26-WI0003',
      );
    });
  });

  group('parseWhatsAppOrderText', () {
    test('parses labeled customer details', () {
      final parsed = parseWhatsAppOrderText('''
Customer: Alice Tan
Phone: 91234567
Address: 10 Orchard Road
Delivery date: 15/6/2026
Time: 14:00-16:00
''');
      expect(parsed.clientName, 'Alice Tan');
      expect(parsed.phone, '91234567');
      expect(parsed.address, '10 Orchard Road');
      expect(parsed.deliveryTimeSlot, '14:00-16:00');
      expect(parsed.deliveryDate, DateTime(2026, 6, 15));
    });

    test('detects pickup from confirmation text', () {
      final parsed = parseWhatsAppOrderText(
        'Order ID: TFG-JUN26-00019\nThis is a pickup order.',
      );
      expect(parsed.orderId, 'TFG-JUN26-00019');
      expect(parsed.orderType, 'PickUp');
    });

    test('parses free-form wedding car deco WhatsApp message', () {
      const text = '''
17Jun 星期三 on site wedding car deco 9am-10am @
Block 309 Jurong East street 32

BMW 7 series
Red and champagne theme
Ws-Molly''';
      final parsed = parseWhatsAppOrderText(text);
      expect(parsed.deliveryDate, DateTime(2026, 6, 17));
      expect(parsed.deliveryTimeSlot, '9am-10am');
      expect(parsed.address, 'Block 309 Jurong East street 32');
      expect(parsed.clientName, 'Molly');
      expect(parsed.orderType, 'Delivery');
      expect(parsed.cardMessage, contains('BMW 7 series'));
      expect(parsed.cardMessage, contains('Red and champagne theme'));
      expect(parsed.cardMessage, isNot(contains('wedding car deco')));
    });

    test('parses delivery order with May date and TFG carousel name', () {
      const text = '''
6支的 28May 星期四 两点前送
blk 821 woodlands st 82 #03-369 S730821
aqil1421 TFG（customer carousel name）''';
      final parsed = parseWhatsAppOrderText(
        text,
        referenceDate: DateTime(2026, 6, 7),
      );
      expect(parsed.deliveryDate, DateTime(2026, 5, 28));
      expect(parsed.deliveryTimeSlot, 'Before 2pm');
      expect(parsed.address, 'blk 821 woodlands st 82 #03-369 S730821');
      expect(parsed.postalCode, '730821');
      expect(parsed.clientName, 'aqil1421');
      expect(parsed.orderType, 'Delivery');
      expect(parsed.productHint, contains('6支'));
      expect(parsed.cardMessage, isNull);
    });

    test('parses pickup corsage order with 拜四', () {
      const text = '''
3支粉玫瑰手花 拜四拿
farahaqilahramli TFG''';
      final parsed = parseWhatsAppOrderText(
        text,
        referenceDate: DateTime(2026, 6, 7),
      );
      expect(parsed.deliveryDate, DateTime(2026, 6, 11));
      expect(parsed.clientName, 'farahaqilahramli');
      expect(parsed.orderType, 'PickUp');
      expect(parsed.productHint, '3支粉玫瑰手花');
    });

    test('parses priced corsage with photo hint and tomorrow pickup', () {
      const text = r'''
$160手花 如图 明天5pm拿
tycaaron TFG（要可以upload 照片的）''';
      final parsed = parseWhatsAppOrderText(
        text,
        referenceDate: DateTime(2026, 6, 7),
      );
      expect(parsed.deliveryDate, DateTime(2026, 6, 8));
      expect(parsed.deliveryTimeSlot, '5pm');
      expect(parsed.clientName, 'tycaaron');
      expect(parsed.orderType, 'PickUp');
      expect(parsed.productHint, r'$160手花');
      expect(parsed.productPrice, 160);
      expect(parsed.needsReferencePhoto, isTrue);
    });

    test('parses labeled hospital delivery with Shopify reference', () {
      const text = '''
Young hearts手花 明天送
Address: St Luke Hospital
Recipient name: Rachel
Hp contact: 81837830
Shopify #1102''';
      final parsed = parseWhatsAppOrderText(
        text,
        referenceDate: DateTime(2026, 6, 7),
      );
      expect(parsed.recipientName, 'Rachel');
      expect(parsed.phone, '81837830');
      expect(parsed.address, 'St Luke Hospital');
      expect(parsed.deliveryDate, DateTime(2026, 6, 8));
      expect(parsed.orderType, 'Delivery');
      expect(parsed.productHint, 'Young hearts手花');
      expect(parsed.clientName, 'Shopify #1102');
      expect(parsed.cardMessage, isNull);
    });
  });

  group('resolveWhatsAppDeliveryTimeSlot', () {
    test('uses default when missing', () {
      expect(resolveWhatsAppDeliveryTimeSlot(null), '09:00-20:00');
      expect(resolveWhatsAppDeliveryTimeSlot(''), '09:00-20:00');
      expect(resolveWhatsAppDeliveryTimeSlot('   '), '09:00-20:00');
    });

    test('keeps detected time slot', () {
      expect(resolveWhatsAppDeliveryTimeSlot('5pm'), '5pm');
      expect(resolveWhatsAppDeliveryTimeSlot('14:00-16:00'), '14:00-16:00');
    });
  });
}
