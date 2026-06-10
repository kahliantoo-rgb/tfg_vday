import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/cash_payment_helpers.dart';
import 'package:tfg_vday/backend/order_balance_helpers.dart';

void main() {
  group('applyPaymentAmount', () {
    test('records partial payment and remaining balance', () {
      final applied = applyPaymentAmount(
        saleTotal: 500,
        previousPaid: 0,
        receivedThisTime: 100,
      );
      expect(applied.amountPaid, 100);
      expect(applied.balanceDue, 400);
      expect(applied.change, 0);
      expect(applied.isFullyPaid, isFalse);
    });

    test('calculates change for overpayment', () {
      final applied = applyPaymentAmount(
        saleTotal: 120,
        previousPaid: 0,
        receivedThisTime: 150,
      );
      expect(applied.amountPaid, 120);
      expect(applied.balanceDue, 0);
      expect(applied.change, 30);
      expect(applied.isFullyPaid, isTrue);
    });

    test('accumulates multiple partial payments', () {
      final first = applyPaymentAmount(
        saleTotal: 500,
        previousPaid: 0,
        receivedThisTime: 100,
      );
      final second = applyPaymentAmount(
        saleTotal: 500,
        previousPaid: first.amountPaid,
        receivedThisTime: 400,
      );
      expect(second.amountPaid, 500);
      expect(second.balanceDue, 0);
      expect(second.isFullyPaid, isTrue);
    });
  });

  group('handleExactPaymentMethodSelection', () {
    test('exact payment applies full remaining balance', () {
      final balanceDue = calculateBalanceDue(
        saleTotal: 500,
        amountPaid: 100,
      );
      final applied = applyPaymentAmount(
        saleTotal: 500,
        previousPaid: 100,
        receivedThisTime: balanceDue,
      );
      expect(applied.amountPaid, 500);
      expect(applied.balanceDue, 0);
      expect(applied.isFullyPaid, isTrue);
    });
  });
}
