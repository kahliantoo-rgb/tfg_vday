import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/customer_invoice_helpers.dart';
import 'package:tfg_vday/backend/order_discount_helpers.dart';

void main() {
  group('calculateOrderPayableTotals', () {
    test('no discount keeps payable equal to subtotal', () {
      final totals = calculateOrderPayableTotals(itemSubtotal: 120);
      expect(totals.subtotal, 120);
      expect(totals.discount, 0);
      expect(totals.total, 120);
      expect(totals.discountLabel, '-');
    });

    test('percent discount', () {
      final totals = calculateOrderPayableTotals(
        itemSubtotal: 200,
        discount: const CustomerInvoiceDiscountInput(
          type: CustomerInvoiceDiscountType.percent,
          value: 10,
        ),
      );
      expect(totals.discount, 20);
      expect(totals.total, 180);
      expect(totals.discountLabel, '10.00%');
    });

    test('amount discount capped at subtotal', () {
      final totals = calculateOrderPayableTotals(
        itemSubtotal: 50,
        discount: const CustomerInvoiceDiscountInput(
          type: CustomerInvoiceDiscountType.amount,
          value: 80,
        ),
      );
      expect(totals.discount, 50);
      expect(totals.total, 0);
    });
  });
}
