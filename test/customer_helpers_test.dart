import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/customer_helpers.dart';
import 'package:tfg_vday/backend/schema/customers_record.dart';

import 'firebase_test_setup.dart';

CustomersRecord _customer(String name, {String phone = '91234567'}) {
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
  group('normalizeCustomerName', () {
    test('trims and lowercases whitespace', () {
      expect(normalizeCustomerName('  Alice   Tan '), 'alice tan');
    });
  });

  group('findExactCustomerByName', () {
    test('matches case-insensitive exact name', () {
      final customers = [
        _customer('Alice Tan'),
        _customer('Bob Lee'),
      ];
      expect(findExactCustomerByName(customers, 'alice tan')?.name, 'Alice Tan');
      expect(findExactCustomerByName(customers, 'Bob'), isNull);
    });
  });

  group('filterCustomersByNameQuery', () {
    test('returns partial matches after two characters', () {
      final customers = [
        _customer('Alice Tan'),
        _customer('Alicia Wong'),
        _customer('Bob Lee'),
      ];
      final matches = filterCustomersByNameQuery(customers, 'ali');
      expect(matches.map((c) => c.name), ['Alice Tan', 'Alicia Wong']);
    });

    test('returns empty list for short query', () {
      final customers = [_customer('Alice Tan')];
      expect(filterCustomersByNameQuery(customers, 'a'), isEmpty);
    });
  });
}
