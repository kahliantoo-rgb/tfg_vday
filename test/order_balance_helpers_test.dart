import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/order_balance_helpers.dart';

void main() {
  group('calculateBalanceDue', () {
    test('returns remaining balance after partial payment', () {
      expect(
        calculateBalanceDue(saleTotal: 500, amountPaid: 100),
        400,
      );
    });

    test('returns zero when fully paid', () {
      expect(
        calculateBalanceDue(saleTotal: 500, amountPaid: 500),
        0,
      );
    });
  });

  group('applyPaymentAmount', () {
    test('caps paid amount at sale total', () {
      final applied = applyPaymentAmount(
        saleTotal: 500,
        previousPaid: 450,
        receivedThisTime: 100,
      );
      expect(applied.amountPaid, 500);
      expect(applied.balanceDue, 0);
      expect(applied.change, 50);
    });
  });
}
