import 'package:flutter/material.dart';

import '/backend/schema/enums/enums.dart';
import '/l10n/tr.dart';

/// User-facing order status label (not the Firestore legacy key).
///
/// For pickup orders, [ready_to_delivery] / [completed] are shown as
/// Ready for Pickup / Picked Up (待自取 / 已自取).
String orderStatusDisplayLabel(
  BuildContext context,
  OrderStatus status, {
  bool isPickup = false,
}) {
  switch (status) {
    case OrderStatus.pending:
      return tr(context, 'order.status.pending');
    case OrderStatus.processing:
      return tr(context, 'order.status.processing');
    case OrderStatus.ready_to_delivery:
      return tr(
        context,
        isPickup ? 'order.status.readyForPickup' : 'order.status.readyToShip',
      );
    case OrderStatus.out_of_delivery:
      return tr(context, 'order.status.outOfDelivery');
    case OrderStatus.completed:
      return tr(
        context,
        isPickup ? 'order.status.pickedUp' : 'order.status.completed',
      );
    case OrderStatus.cancelled:
      return tr(context, 'order.status.cancelled');
  }
}

/// Statuses offered when updating an order from the status sheet / bulk sheet.
List<OrderStatus> orderStatusUpdateOptions({required bool isPickup}) {
  if (isPickup) {
    return const [
      OrderStatus.processing,
      OrderStatus.ready_to_delivery,
      OrderStatus.completed,
      OrderStatus.cancelled,
    ];
  }
  return const [
    OrderStatus.processing,
    OrderStatus.ready_to_delivery,
    OrderStatus.out_of_delivery,
    OrderStatus.completed,
    OrderStatus.cancelled,
  ];
}

/// Dropdown / filter label for legacy status keys stored in Firestore.
String orderLegacyStatusDisplayLabel(BuildContext context, String legacyKey) {
  switch (legacyKey) {
    case 'all':
      return tr(context, 'order.status.all');
    case 'pending':
      return tr(context, 'order.status.pending');
    case 'processing':
      return tr(context, 'order.status.processing');
    case 'readyToShip':
      return tr(context, 'order.status.readyToShip');
    case 'outOfDelivery':
      return tr(context, 'order.status.outOfDelivery');
    case 'completed':
      return tr(context, 'order.status.completed');
    case 'cancelled':
      return tr(context, 'order.status.cancelled');
    default:
      return legacyKey;
  }
}

List<String> orderListStatusDropdownLabels(BuildContext context) {
  return [
    orderLegacyStatusDisplayLabel(context, 'all'),
    for (final key in const [
      'pending',
      'processing',
      'readyToShip',
      'outOfDelivery',
      'completed',
      'cancelled',
    ])
      orderLegacyStatusDisplayLabel(context, key),
  ];
}
