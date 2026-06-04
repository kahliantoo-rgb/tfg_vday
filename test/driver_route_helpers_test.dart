import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/driver_route_helpers.dart';
import 'package:tfg_vday/backend/schema/orders_record.dart';

import 'firebase_test_setup.dart';

OrdersRecord _order({
  required String id,
  String address = '',
  DateTime? deliveryDate,
  String deliveryTimeSlot = '',
  DocumentReference? assignedDriver,
}) {
  return OrdersRecord.getDocumentFromData(
    {
      'address': address,
      'delivery_date': deliveryDate,
      'delivery_time_slot': deliveryTimeSlot,
      'assigned_driver': assignedDriver,
    },
    FirebaseFirestore.instance.collection('orders').doc(id),
  );
}

void main() {
  setUpAll(setupFirebaseForTests);

  group('sortOrdersForDriverRoute', () {
    test('sorts by delivery date then time slot', () {
      final orders = [
        _order(
          id: 'b',
          address: 'B',
          deliveryDate: DateTime(2026, 6, 5),
          deliveryTimeSlot: '14:00-16:00',
        ),
        _order(
          id: 'a',
          address: 'A',
          deliveryDate: DateTime(2026, 6, 4),
          deliveryTimeSlot: '10:00-12:00',
        ),
        _order(
          id: 'c',
          address: 'C',
          deliveryDate: DateTime(2026, 6, 5),
          deliveryTimeSlot: '09:00-11:00',
        ),
      ];

      final sorted = sortOrdersForDriverRoute(orders);
      expect(sorted.map((o) => o.reference.id).toList(), ['a', 'c', 'b']);
    });
  });

  group('driverRouteAddresses', () {
    test('returns non-empty addresses in visit order', () {
      final orders = [
        _order(
          id: '1',
          address: '  ',
          deliveryDate: DateTime(2026, 6, 4),
        ),
        _order(
          id: '2',
          address: 'Second Stop',
          deliveryDate: DateTime(2026, 6, 5),
        ),
        _order(
          id: '3',
          address: 'First Stop',
          deliveryDate: DateTime(2026, 6, 4),
          deliveryTimeSlot: '08:00',
        ),
      ];

      expect(driverRouteAddresses(orders), ['First Stop', 'Second Stop']);
    });
  });

  group('filterOrdersForDriver', () {
    test('keeps only orders assigned to driver', () {
      final driverA = FirebaseFirestore.instance.collection('users').doc('a');
      final driverB = FirebaseFirestore.instance.collection('users').doc('b');
      final orders = [
        _order(id: '1', assignedDriver: driverA),
        _order(id: '2', assignedDriver: driverB),
        _order(id: '3'),
      ];

      final filtered = filterOrdersForDriver(orders, driverRef: driverA);
      expect(filtered.map((o) => o.reference.id).toList(), ['1']);
    });

    test('returns all orders when driver ref is null', () {
      final orders = [
        _order(id: '1'),
        _order(id: '2'),
      ];
      expect(filterOrdersForDriver(orders).length, 2);
    });
  });

  group('limitRouteStops', () {
    test('caps at max stops', () {
      final addresses = List.generate(12, (i) => 'Stop $i');
      expect(limitRouteStops(addresses).length, kDriverRouteMaxStops);
    });
  });
}
