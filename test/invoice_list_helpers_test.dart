import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/invoice_list_helpers.dart';
import 'package:tfg_vday/backend/schema/invoices_record.dart';
import 'package:tfg_vday/backend/schema/orders_record.dart';

import 'firebase_test_setup.dart';

InvoicesRecord _invoice({
  required String number,
  required String customer,
  required String creditTerm,
  required DateTime created,
  String status = InvoiceStatus.pending,
}) {
  return InvoicesRecord.getDocumentFromData(
    {
      'invoice_number': number,
      'customer_name': customer,
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
  });
}
