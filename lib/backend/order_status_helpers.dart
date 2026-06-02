import '/backend/schema/enums/enums.dart';

/// Legacy string stored in Firestore field `orderstatus` (used by order list filters).
String legacyOrderStatusLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'pending';
    case OrderStatus.processing:
      return 'processing';
    case OrderStatus.ready_to_delivery:
      return 'readyToShip';
    case OrderStatus.out_of_delivery:
      return 'outOfDelivery';
    case OrderStatus.completed:
      return 'completed';
    case OrderStatus.cancelled:
      return 'cancelled';
  }
}

/// Keeps enum `status` and legacy `orderstatus` in sync on writes.
Map<String, dynamic> createOrderStatusUpdateData(OrderStatus status) => {
      'status': status.serialize(),
      'orderstatus': legacyOrderStatusLabel(status),
    };
