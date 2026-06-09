import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/customer_broadcast_helpers.dart';
import 'package:tfg_vday/backend/schema/customers_record.dart';

import 'firebase_test_setup.dart';

CustomersRecord _customer(String name, String phone) {
  return CustomersRecord.getDocumentFromData(
    {
      'name': name,
      'phone': phone,
      'billing_address': '123 Test Street',
    },
    FirebaseFirestore.instance.collection('customers').doc(name),
  );
}

void main() {
  setUpAll(() async {
    await setupFirebaseForTests();
  });

  group('filterCustomersForBroadcast', () {
    test('includes customers with valid Singapore mobile numbers', () {
      final recipients = filterCustomersForBroadcast([
        _customer('Alice', '91234567'),
        _customer('Bob', 'invalid'),
        _customer('Carol', '87654321'),
      ]);

      expect(recipients, hasLength(2));
      expect(recipients.map((r) => r.customer.name), ['Alice', 'Carol']);
      expect(recipients.first.phoneDigits, '6591234567');
    });
  });

  group('buildCustomerBroadcastWhatsAppUri', () {
    test('builds wa.me link with encoded message', () {
      final uri = buildCustomerBroadcastWhatsAppUri(
        phoneDigits: '6591234567',
        message: '优惠 10%',
      );

      expect(uri.toString(), contains('https://wa.me/6591234567'));
      expect(uri.queryParameters['text'], '优惠 10%');
    });
  });
}
