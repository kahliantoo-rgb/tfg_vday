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
}

