import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/driver_delivery_filter_helpers.dart';
import 'package:tfg_vday/backend/schema/enums/enums.dart';
import 'package:tfg_vday/backend/schema/orders_record.dart';

import 'firebase_test_setup.dart';

OrdersRecord _order({
  required String id,
  OrderStatus? status,
  DateTime? deliveryDate,
  DocumentReference? assignedDriver,
}) {
  return OrdersRecord.getDocumentFromData(
    {
      if (status != null) 'status': status.serialize(),
      if (deliveryDate != null) 'delivery_date': deliveryDate,
      if (assignedDriver != null) 'assigned_driver': assignedDriver,
    },
    FirebaseFirestore.instance.collection('orders').doc(id),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  test('driverTabStatusFromChip maps labels', () {
    expect(driverTabStatusFromChip('All'), isNull);
    expect(driverTabStatusFromChip('Assigned'), OrderStatus.ready_to_delivery);
    expect(
      driverTabStatusFromChip('Out for Delivery'),
      OrderStatus.out_of_delivery,
    );
    expect(driverTabStatusFromChip('Completed'), OrderStatus.completed);
  });

  test('filterDriverDeliveryOrders returns all assigned when tab is null', () {
    final driver = FirebaseFirestore.instance.collection('users').doc('driver1');
    final orders = [
      _order(
        id: '1',
        status: OrderStatus.ready_to_delivery,
        deliveryDate: DateTime(2026, 6, 4),
        assignedDriver: driver,
      ),
      _order(
        id: '2',
        status: OrderStatus.out_of_delivery,
        deliveryDate: DateTime(2026, 6, 10),
        assignedDriver: driver,
      ),
      _order(
        id: '3',
        status: OrderStatus.completed,
        deliveryDate: DateTime(2026, 5, 1),
        assignedDriver: driver,
      ),
    ];

    final filtered = filterDriverDeliveryOrders(
      orders,
      driverRef: driver,
      tabStatus: null,
    );

    expect(filtered.map((o) => o.reference.id).toList(), ['3', '1', '2']);
  });

  test('filterDriverDeliveryOrders filters by date range', () {
    final driver = FirebaseFirestore.instance.collection('users').doc('driver1');
    final orders = [
      _order(
        id: '1',
        status: OrderStatus.ready_to_delivery,
        deliveryDate: DateTime(2026, 6, 4),
        assignedDriver: driver,
      ),
      _order(
        id: '2',
        status: OrderStatus.ready_to_delivery,
        deliveryDate: DateTime(2026, 6, 8),
        assignedDriver: driver,
      ),
    ];

    final filtered = filterDriverDeliveryOrders(
      orders,
      driverRef: driver,
      tabStatus: null,
      filterStart: DateTime(2026, 6, 5),
      filterEnd: DateTime(2026, 6, 9),
    );

    expect(filtered.map((o) => o.reference.id).toList(), ['2']);
  });

  test('filterDriverDeliveryOrders returns empty without driver ref', () {
    final orders = [
      _order(
        id: '1',
        status: OrderStatus.ready_to_delivery,
        deliveryDate: DateTime(2026, 6, 4),
      ),
    ];
    expect(
      filterDriverDeliveryOrders(
        orders,
        driverRef: null,
        tabStatus: null,
      ),
      isEmpty,
    );
  });
}
