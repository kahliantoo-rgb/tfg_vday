import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/customer_helpers.dart';
import 'package:tfg_vday/backend/schema/customers_record.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';
import 'package:tfg_vday/backend/schema/orders_record.dart';

import 'firebase_test_setup.dart';

CustomersRecord _customer(
  String name, {
  String phone = '91234567',
  String customerId = '',
}) {
  return CustomersRecord.getDocumentFromData(
    {
      'name': name,
      'phone': phone,
      'customer_id': customerId,
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

  group('findCustomerByNameOrId', () {
    test('matches customer id or exact name', () {
      final customers = [
        _customer('Alice Tan', customerId: 'TFG01'),
        _customer('Bob Lee', customerId: 'TFG02'),
      ];
      expect(findCustomerByNameOrId(customers, 'tfg01')?.name, 'Alice Tan');
      expect(findCustomerByNameOrId(customers, 'Alice Tan')?.customerId, 'TFG01');
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

  group('filterCustomersForInvoiceSearch', () {
    test('matches customer id and name', () {
      final customers = [
        _customer('Acme Florist', customerId: 'TFG01'),
        _customer('Beta Shop', customerId: 'TFG02'),
      ];
      final byId = filterCustomersForInvoiceSearch(customers, 'tfg01');
      expect(byId, hasLength(1));
      expect(byId.first.name, 'Acme Florist');
      expect(byId.first.customerId, 'TFG01');

      final byName = filterCustomersForInvoiceSearch(customers, 'beta');
      expect(byName, hasLength(1));
      expect(byName.first.customerId, 'TFG02');

      final byPartialName = filterCustomersForInvoiceSearch(customers, 'acme');
      expect(byPartialName, hasLength(1));
      expect(byPartialName.first.name, 'Acme Florist');
    });
  });

  group('findCustomerProfileDuplicateError', () {
    test('rejects duplicate name case-insensitively', () {
      final existing = [
        _customer('Alice Tan'),
        _customer('Bob Lee'),
      ];
      expect(
        findCustomerProfileDuplicateError(
          existing: existing,
          name: 'alice tan',
          phone: '88888888',
        ),
        kCustomerDuplicateNameError,
      );
    });

    test('allows same name when editing same customer', () {
      final alice = _customer('Alice Tan', phone: '91111111');
      expect(
        findCustomerProfileDuplicateError(
          existing: [alice, _customer('Bob Lee', phone: '92222222')],
          name: 'Alice Tan',
          phone: '91111111',
          excludeRef: alice.reference,
        ),
        isNull,
      );
    });

    test('rejects duplicate phone', () {
      final existing = [_customer('Alice Tan', phone: '91234567')];
      expect(
        findCustomerProfileDuplicateError(
          existing: existing,
          name: 'New Person',
          phone: '9123 4567',
        ),
        kCustomerDuplicatePhoneError,
      );
    });
  });

  group('summarizeCustomerPurchaseHistory', () {
    CustomerPurchaseEntry _entry({
      required String id,
      required double total,
      DateTime? created,
      DateTime? delivery,
      OrderStatus? status,
      String invoicePaymentStatus = '',
      double amountPaid = 0,
    }) {
      return CustomerPurchaseEntry(
        order: OrdersRecord.getDocumentFromData(
          {
            'totalAmount': total,
            'created_time': created,
            'delivery_date': delivery,
            'status': status,
            'invoice_payment_status': invoicePaymentStatus,
            'amount_paid': amountPaid,
          },
          OrdersRecord.collection.doc(id),
        ),
        items: const [],
      );
    }

    test('sums paid orders and finds latest purchase date', () {
      final summary = summarizeCustomerPurchaseHistory([
        _entry(
          id: 'o1',
          total: 80,
          created: DateTime(2026, 3, 1),
          amountPaid: 80,
        ),
        _entry(
          id: 'o2',
          total: 120,
          created: DateTime(2026, 5, 10),
          delivery: DateTime(2026, 5, 12),
          invoicePaymentStatus: 'paid',
        ),
        _entry(
          id: 'o3',
          total: 50,
          created: DateTime(2026, 4, 1),
          invoicePaymentStatus: 'pending',
        ),
        _entry(
          id: 'o4',
          total: 999,
          created: DateTime(2026, 6, 1),
          status: OrderStatus.cancelled,
        ),
      ]);

      expect(summary.totalSpending, 200);
      expect(summary.lastPurchaseAt, DateTime(2026, 5, 12));
      expect(summary.orderCount, 3);
    });
  });
}
