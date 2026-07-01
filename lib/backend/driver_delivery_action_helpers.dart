import '/backend/schema/enums/enums.dart';

/// Driver may start delivery only when shop has marked the order ready to ship.
bool driverCanStartOutForDelivery(OrderStatus? status) {
  return status == OrderStatus.ready_to_delivery;
}

/// Driver may open record-delivery flow only while out for delivery.
bool driverCanRecordDelivery(OrderStatus? status) {
  return status == OrderStatus.out_of_delivery;
}

/// Statuses shown on the driver "All" tab (assigned, not cancelled).
bool driverOrderVisibleOnAllTab(OrderStatus? status) {
  return status != null && status != OrderStatus.cancelled;
}

/// Show a read-only hint while the shop has not marked the order ready to ship.
bool driverShowsWaitingForReadyHint(OrderStatus? status) {
  return status == OrderStatus.processing || status == OrderStatus.pending;
}
