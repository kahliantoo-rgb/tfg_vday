import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/order_status_helpers.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';

void main() {
  test('legacyOrderStatusLabel: maps all statuses', () {
    expect(legacyOrderStatusLabel(OrderStatus.pending), 'pending');
    expect(legacyOrderStatusLabel(OrderStatus.processing), 'processing');
    expect(legacyOrderStatusLabel(OrderStatus.ready_to_delivery), 'readyToShip');
    expect(legacyOrderStatusLabel(OrderStatus.out_of_delivery), 'outOfDelivery');
    expect(legacyOrderStatusLabel(OrderStatus.completed), 'completed');
    expect(legacyOrderStatusLabel(OrderStatus.cancelled), 'cancelled');
  });

  test('createOrderStatusUpdateData: syncs enum + legacy label', () {
    final data = createOrderStatusUpdateData(OrderStatus.ready_to_delivery);

    // `status` is serialized via enum.serialize() => enum name.
    expect(data['status'], 'ready_to_delivery');
    // `orderstatus` is the legacy label used by list filters.
    expect(data['orderstatus'], 'readyToShip');
  });

  test('delivery status chain D3: enum + legacy labels stay aligned', () {
    const chain = [
      (OrderStatus.pending, 'pending', 'pending'),
      (OrderStatus.processing, 'processing', 'processing'),
      (OrderStatus.ready_to_delivery, 'ready_to_delivery', 'readyToShip'),
      (OrderStatus.out_of_delivery, 'out_of_delivery', 'outOfDelivery'),
      (OrderStatus.completed, 'completed', 'completed'),
    ];

    for (final (status, enumValue, legacy) in chain) {
      final data = createOrderStatusUpdateData(status);
      expect(data['status'], enumValue, reason: '$status status field');
      expect(data['orderstatus'], legacy, reason: '$status orderstatus field');
      expect(legacyOrderStatusLabel(status), legacy);
    }
  });
}

