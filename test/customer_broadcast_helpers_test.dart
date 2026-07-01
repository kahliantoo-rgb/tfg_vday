import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/customer_broadcast_helpers.dart';
import 'package:tfg_vday/backend/customer_broadcast_image_helpers.dart';
import 'package:tfg_vday/backend/schema/customers_record.dart';

import 'firebase_test_setup.dart';

CustomersRecord _customer({
  required String name,
  String phone = '',
  String email = '',
}) {
  return CustomersRecord.getDocumentFromData(
    {
      'name': name,
      'phone': phone,
      'email': email,
      'billing_address': '123 Test Street',
    },
    FirebaseFirestore.instance.collection('customers').doc(name),
  );
}

void main() {
  setUpAll(() async {
    await setupFirebaseForTests();
  });

  group('customerBroadcastImageStoragePath', () {
    test('scopes uploads under company id', () {
      expect(
        customerBroadcastImageStoragePath('company_a', 'photo.jpg'),
        'customer_broadcast_images/company_a/photo.jpg',
      );
    });
  });

  group('resolveBroadcastCustomerTargets', () {
    test('uses filtered list when nothing selected', () {
      final all = [
        _customer(name: 'Alice'),
        _customer(name: 'Bob'),
      ];

      final targets = resolveBroadcastCustomerTargets(
        allCustomers: all,
        filteredCustomers: [all.first],
        selectedCustomerPaths: const {},
      );

      expect(targets.map((c) => c.name), ['Alice']);
    });

    test('uses selected customers when selection is not empty', () {
      final alice = _customer(name: 'Alice');
      final bob = _customer(name: 'Bob');
      final carol = _customer(name: 'Carol');

      final targets = resolveBroadcastCustomerTargets(
        allCustomers: [alice, bob, carol],
        filteredCustomers: [alice, bob],
        selectedCustomerPaths: {bob.reference.path, carol.reference.path},
      );

      expect(targets.map((c) => c.name), ['Bob', 'Carol']);
    });
  });

  group('filterCustomersForBroadcast', () {
    test('includes customers with valid Singapore mobile numbers', () {
      final recipients = filterCustomersForBroadcast([
        _customer(name: 'Alice', phone: '91234567'),
        _customer(name: 'Bob', phone: 'invalid'),
        _customer(name: 'Carol', phone: '87654321'),
      ]);

      expect(recipients, hasLength(2));
      expect(recipients.map((r) => r.customer.name), ['Alice', 'Carol']);
      expect(recipients.first.phoneDigits, '6591234567');
    });
  });

  group('filterCustomersForEmailBroadcast', () {
    test('includes customers with valid unique emails', () {
      final recipients = filterCustomersForEmailBroadcast([
        _customer(name: 'Alice', email: 'alice@example.com'),
        _customer(name: 'Bob', email: 'not-an-email'),
        _customer(name: 'Carol', email: 'carol@example.com'),
        _customer(name: 'Dup', email: 'alice@example.com'),
      ]);

      expect(recipients, hasLength(2));
      expect(recipients.map((r) => r.email), ['alice@example.com', 'carol@example.com']);
    });
  });

  group('buildCustomerBroadcastWhatsAppMessage', () {
    test('appends image URL after message', () {
      expect(
        buildCustomerBroadcastWhatsAppMessage(
          message: '优惠 10%',
          imageUrl: 'https://example.com/promo.jpg',
        ),
        '优惠 10%\n\nhttps://example.com/promo.jpg',
      );
    });

    test('returns image URL when message is empty', () {
      expect(
        buildCustomerBroadcastWhatsAppMessage(
          message: '',
          imageUrl: 'https://example.com/promo.jpg',
        ),
        'https://example.com/promo.jpg',
      );
    });
  });

  group('buildCustomerBroadcastWhatsAppUri', () {
    test('builds WhatsApp Business send link with encoded message', () {
      final uri = buildCustomerBroadcastWhatsAppUri(
        phoneDigits: '6591234567',
        message: '优惠 10%',
      );

      expect(uri.scheme, 'https');
      expect(uri.host, 'api.whatsapp.com');
      expect(uri.path, '/send');
      expect(uri.queryParameters['phone'], '6591234567');
      expect(uri.queryParameters['text'], '优惠 10%');
    });

    test('includes image URL in encoded message', () {
      final uri = buildCustomerBroadcastWhatsAppUri(
        phoneDigits: '6591234567',
        message: 'Hello',
        imageUrl: 'https://example.com/promo.jpg',
      );

      expect(
        uri.queryParameters['text'],
        'Hello\n\nhttps://example.com/promo.jpg',
      );
    });
  });

  group('buildCustomerBroadcastEmailHtml', () {
    test('embeds image inline with escaped HTML', () {
      final html = buildCustomerBroadcastEmailHtml(
        message: 'Dear customer',
        imageUrl: 'https://example.com/promo.jpg?x=1&y=2',
      );

      expect(html, contains('<p>Dear customer</p>'));
      expect(
        html,
        contains(
          '<img src="https://example.com/promo.jpg?x=1&amp;y=2" alt="Promotion"',
        ),
      );
      expect(html, isNot(contains('&y=2"')));
    });
  });

  group('buildCustomerBroadcastEmailUri', () {
    test('builds mailto link with bcc, subject, and body', () {
      final uri = buildCustomerBroadcastEmailUri(
        bccEmails: ['alice@example.com', 'carol@example.com'],
        subject: 'Promotion',
        message: 'Dear customer',
      );

      expect(uri.scheme, 'mailto');
      expect(uri.queryParameters['bcc'], 'alice@example.com,carol@example.com');
      expect(uri.queryParameters['subject'], 'Promotion');
      expect(uri.queryParameters['body'], 'Dear customer');
    });
  });
}
