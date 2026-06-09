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
  });
}
