import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/audit_log_helpers.dart';
import '/backend/backend.dart';
import '/backend/order_status_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/staff_notice_helpers.dart';

Future<int> bulkUpdateOrdersStatus({
  required List<OrdersRecord> orders,
  required OrderStatus status,
}) async {
  var updated = 0;
  for (final order in orders) {
    await updateOrderStatus(order.reference, status);
    await auditLogOrderStatusChangeByRef(order.reference, status);
    updated++;
  }
  return updated;
}

Future<int> bulkAssignDriverToOrders({
  required List<OrdersRecord> orders,
  required DocumentReference driverUserRef,
}) async {
  var updated = 0;
  for (final order in orders) {
    final previousDriverId = order.assignedDriver?.id;
    await order.reference.update(
      createOrdersRecordData(assignedDriver: driverUserRef),
    );
    await auditLogAssignDriver(
      order: order,
      oldDriverId: previousDriverId,
      newDriverId: driverUserRef.id,
    );
    if (previousDriverId != driverUserRef.id) {
      await notifyDriverAssigned(
        order: order,
        driverUserRef: driverUserRef,
      );
    }
    updated++;
  }
  return updated;
}
