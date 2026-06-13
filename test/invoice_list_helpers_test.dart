import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/invoice_list_helpers.dart';
import 'package:tfg_vday/backend/schema/customers_record.dart';
import 'package:tfg_vday/backend/schema/invoices_record.dart';
import 'package:tfg_vday/backend/schema/orders_record.dart';

import 'firebase_test_setup.dart';

CustomersRecord _linkedCustomer({
  required String docId,
  required String name,
  required String customerId,
}) {
  return CustomersRecord.getDocumentFromData(
    {
      'name': name,
      'customer_id': customerId,
      'phone': '91234567',
    },
    CustomersRecord.collection.doc(docId),
  );
}

InvoicesRecord _invoice({
  required String number,
  required String customer,
  required String creditTerm,
  required DateTime created,
  DocumentReference? customerRef,
  String status = InvoiceStatus.pending,
}) {
  return InvoicesRecord.getDocumentFromData(
    {
      'invoice_number': number,
      'customer_name': customer,
      'customer_ref': customerRef,
      'credit_term': creditTerm,
      'created_time': created,
      'status': status,
      'total': 100,
    },
    InvoicesRecord.collection.doc('test_$number'),
  );
}
void main() {
  setUpAll(setupFirebaseForTests);

  group('filterInvoiceList', () {
    test('filters by invoice number and customer', () {
      final invoices = [
        _invoice(
          number: 'IN-TFG-JUN26-0001',
          customer: 'Acme Florist',
          creditTerm: 'Credit 30 days',
          created: DateTime(2026, 6, 5),
        ),
        _invoice(
          number: 'IN-TFG-MAY26-0002',
          customer: 'Beta Shop',
          creditTerm: 'Credit 15 days',
          created: DateTime(2026, 5, 10),
          status: InvoiceStatus.paid,
        ),
      ];
      final filtered = filterInvoiceList(
        invoices,
        const InvoiceListFilters(
          invoiceNumberQuery: 'JUN26',
          customerQuery: 'acme',
        ),
      );
      expect(filtered, hasLength(1));
      expect(filtered.first.invoiceNumber, 'IN-TFG-JUN26-0001');
    });

    test('filters by linked customer id', () {
      final customer = _linkedCustomer(
        docId: 'cust1',
        name: 'Acme Florist',
        customerId: 'TFG01',
      );
      final invoices = [
        _invoice(
          number: 'IN-TFG-JUN26-0001',
          customer: 'Acme Florist',
          creditTerm: 'Credit 30 days',
          created: DateTime(2026, 6, 5),
          customerRef: customer.reference,
        ),
        _invoice(
          number: 'IN-TFG-MAY26-0002',
          customer: 'Beta Shop',
          creditTerm: 'Credit 15 days',
          created: DateTime(2026, 5, 10),
        ),
      ];
      final filtered = filterInvoiceList(
        invoices,
        const InvoiceListFilters(customerQuery: 'tfg01'),
        customersByRefPath: buildCustomersByRefPath([customer]),
      );
      expect(filtered, hasLength(1));
      expect(filtered.first.invoiceNumber, 'IN-TFG-JUN26-0001');
    });

    test('filters by month and credit term', () {
      final invoices = [
        _invoice(
          number: 'IN-TFG-JUN26-0001',
          customer: 'Acme Florist',
          creditTerm: 'Credit 30 days',
          created: DateTime(2026, 6, 5),
        ),
        _invoice(
          number: 'IN-TFG-MAY26-0002',
          customer: 'Beta Shop',
          creditTerm: 'Credit 15 days',
          created: DateTime(2026, 5, 10),
          status: InvoiceStatus.paid,
        ),
      ];
      final filtered = filterInvoiceList(
        invoices,
        InvoiceListFilters(
          month: DateTime(2026, 5, 1),
          creditTerm: 'Credit 15 days',
        ),
      );
      expect(filtered, hasLength(1));
      expect(filtered.first.invoiceNumber, 'IN-TFG-MAY26-0002');
    });
  });

  group('isOrderAvailableForInvoicing', () {
    test('allows orders without invoice link', () {
      final order = OrdersRecord.getDocumentFromData(
        <String, dynamic>{},
        OrdersRecord.collection.doc('order1'),
      );
      expect(isOrderAvailableForInvoicing(order), isTrue);
    });

    test('allows orders with voided invoice payment status', () {
      final order = OrdersRecord.getDocumentFromData(
        <String, dynamic>{
          'invoice_payment_status': InvoiceStatus.voided,
          'invoice_ref': InvoicesRecord.collection.doc('voided_inv'),
        },
        OrdersRecord.collection.doc('order2'),
      );
      expect(isOrderAvailableForInvoicing(order), isTrue);
    });

    test('blocks orders on active pending invoice', () {
      final order = OrdersRecord.getDocumentFromData(
        <String, dynamic>{
          'invoice_payment_status': InvoiceStatus.pending,
          'invoice_ref': InvoicesRecord.collection.doc('active_inv'),
        },
        OrdersRecord.collection.doc('order3'),
      );
      expect(isOrderAvailableForInvoicing(order), isFalse);
    });
  });

  group('isCustomerOrderPaid', () {
    test('treats voided invoice orders as unpaid', () {
      final order = OrdersRecord.getDocumentFromData(
        <String, dynamic>{
          'invoice_payment_status': InvoiceStatus.voided,
          'amount_paid': 120,
          'totalAmount': 120,
          'paymentType': 'credit',
        },
        OrdersRecord.collection.doc('order4'),
      );
      expect(isCustomerOrderPaid(order), isFalse);
    });
  });
}
