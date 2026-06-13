import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/order_id_service.dart';

void main() {
  group('OrderIdService.counterDocId', () {
    test('scopes delivery counter by month period', () {
      expect(
        OrderIdService.counterDocId('delivery', period: 'JUN26'),
        'default_delivery_JUN26',
      );
      expect(
        OrderIdService.counterDocId('retail', period: 'JUL26'),
        'default_retail_JUL26',
      );
    });

    test('different months use different counter docs', () {
      final june = OrderIdService.counterDocId('delivery', period: 'JUN26');
      final july = OrderIdService.counterDocId('delivery', period: 'JUL26');
      expect(june, isNot(equals(july)));
    });
  });

  group('OrderIdService order id patterns', () {
    test('detects delivery and retail ids', () {
      expect(OrderIdService.isDeliveryOrderId('TFG-JUN26-0001'), isTrue);
      expect(OrderIdService.isRetailOrderId('TFG-JUN26-WI0001'), isTrue);
      expect(OrderIdService.isDeliveryOrderId('TFG-JUN26-WI0001'), isFalse);
    });

    test('detects invoice numbers', () {
      expect(OrderIdService.isInvoiceNumber('IN-TFG-JUN26-0001'), isTrue);
      expect(OrderIdService.isInvoiceNumber('TFG-JUN26-0001'), isFalse);
    });

    test('invoice counter doc id uses monthly period', () {
      expect(
        OrderIdService.counterDocId('invoice', period: 'JUN26'),
        'default_invoice_JUN26',
      );
    });
  });

  group('OrderIdService customer ids', () {
    test('formats TFG01 through TFG1000', () {
      expect(OrderIdService.formatCustomerId(1), 'TFG01');
      expect(OrderIdService.formatCustomerId(9), 'TFG09');
      expect(OrderIdService.formatCustomerId(99), 'TFG99');
      expect(OrderIdService.formatCustomerId(100), 'TFG100');
      expect(OrderIdService.formatCustomerId(1000), 'TFG1000');
    });

    test('detects valid customer public ids', () {
      expect(OrderIdService.isCustomerPublicId('TFG01'), isTrue);
      expect(OrderIdService.isCustomerPublicId('TFG1000'), isTrue);
      expect(OrderIdService.isCustomerPublicId('TFG1001'), isFalse);
      expect(OrderIdService.isCustomerPublicId('TFG-JUN26-0001'), isFalse);
    });

    test('uses fixed customer counter doc', () {
      expect(OrderIdService.customerCounterId, 'default_customer');
    });

    test('reuses lowest released customer sequence', () {
      expect(
        OrderIdService.pickNextCustomerSequence(
          current: 10,
          available: const [3, 7],
        ),
        3,
      );
      expect(
        OrderIdService.pickNextCustomerSequence(
          current: 10,
          available: const [],
        ),
        11,
      );
      expect(
        OrderIdService.pickNextCustomerSequence(
          current: 1000,
          available: const [],
        ),
        isNull,
      );
    });

    test('addReleasedCustomerSequence keeps sorted unique values', () {
      expect(
        OrderIdService.addReleasedCustomerSequence(const [5, 9], 3),
        [3, 5, 9],
      );
      expect(
        OrderIdService.addReleasedCustomerSequence(const [5], 5),
        [5],
      );
    });
  });
}
