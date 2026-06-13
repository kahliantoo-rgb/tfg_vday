import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/driver_delivery_proof_helpers.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';

void main() {
  group('deliveryProofStoragePath', () {
    test('stores under order id folder', () {
      expect(
        deliveryProofStoragePath('order123', 'photo.jpg'),
        'delivery_proof_images/order123/photo.jpg',
      );
    });
  });

  group('orderAllowsDeliveryProofUpload', () {
    test('allows out for delivery and completed', () {
      expect(
        orderAllowsDeliveryProofUpload(OrderStatus.out_of_delivery),
        isTrue,
      );
      expect(orderAllowsDeliveryProofUpload(OrderStatus.completed), isTrue);
      expect(
        orderAllowsDeliveryProofUpload(OrderStatus.ready_to_delivery),
        isFalse,
      );
    });
  });
}
