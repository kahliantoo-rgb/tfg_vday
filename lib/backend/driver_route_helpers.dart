import '/backend/schema/orders_record.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Orders assigned to [driverRef]. When [driverRef] is null, returns all orders.
List<OrdersRecord> filterOrdersForDriver(
  List<OrdersRecord> orders, {
  DocumentReference? driverRef,
}) {
  if (driverRef == null) {
    return orders;
  }
  return orders
      .where((order) => order.assignedDriver?.path == driverRef.path)
      .toList();
}
List<OrdersRecord> sortOrdersForDriverRoute(List<OrdersRecord> orders) {
  final copy = List<OrdersRecord>.from(orders);
  copy.sort((a, b) {
    final dateA = a.deliveryDate;
    final dateB = b.deliveryDate;
    if (dateA != null && dateB != null) {
      final byDate = dateA.compareTo(dateB);
      if (byDate != 0) {
        return byDate;
      }
    } else if (dateA != null) {
      return -1;
    } else if (dateB != null) {
      return 1;
    }
    return a.deliveryTimeSlot.compareTo(b.deliveryTimeSlot);
  });
  return copy;
}

/// Non-empty delivery addresses in suggested visit order.
List<String> driverRouteAddresses(List<OrdersRecord> orders) {
  return sortOrdersForDriverRoute(orders)
      .map((order) => order.address.trim())
      .where((address) => address.isNotEmpty)
      .toList();
}

/// Google Maps URL multi-stop limit (practical cap for map URLs).
const kDriverRouteMaxStops = 10;

List<String> limitRouteStops(List<String> addresses) {
  if (addresses.length <= kDriverRouteMaxStops) {
    return addresses;
  }
  return addresses.sublist(0, kDriverRouteMaxStops);
}
