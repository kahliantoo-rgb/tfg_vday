import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/daily_sales_report_service.dart';
import '/backend/driver_delivery_action_helpers.dart';
import '/backend/driver_delivery_tab_labels.dart';
import '/backend/order_list_filter_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/orders_record.dart';

/// Maps driver list chip label to status filter. `null` = all statuses.
OrderStatus? driverTabStatusFromChip(String? chip) {
  switch (driverDeliveryTabKeyFromLabel(chip)) {
    case DriverDeliveryTabKey.outForDelivery:
      return OrderStatus.out_of_delivery;
    case DriverDeliveryTabKey.completed:
      return OrderStatus.completed;
    case DriverDeliveryTabKey.assigned:
      return OrderStatus.ready_to_delivery;
    case DriverDeliveryTabKey.all:
    case null:
      return null;
  }
}

/// Firestore `status` values for the Assigned tab (includes pre-ready assignments).
List<String> driverAssignedTabStatusValues() => [
      OrderStatus.processing.serialize(),
      OrderStatus.ready_to_delivery.serialize(),
    ];

bool orderMatchesDriverTabStatus(OrdersRecord order, OrderStatus? tabStatus) {
  if (tabStatus == null) {
    return driverOrderVisibleOnAllTab(order.status);
  }
  switch (tabStatus) {
    case OrderStatus.ready_to_delivery:
      return order.status == OrderStatus.processing ||
          order.status == OrderStatus.ready_to_delivery;
    case OrderStatus.out_of_delivery:
      return order.status == OrderStatus.out_of_delivery;
    case OrderStatus.completed:
      return order.status == OrderStatus.completed;
    default:
      return false;
  }
}

DateTime? driverDeliveryCalendarDate(OrdersRecord order) =>
    order.deliveryDate ?? order.createdTime;

bool orderMatchesDriverDeliveryDateRange(
  OrdersRecord order, {
  DateTime? filterStart,
  DateTime? filterEnd,
}) {
  if (filterStart == null && filterEnd == null) {
    return true;
  }
  final effective = driverDeliveryCalendarDate(order);
  if (effective == null) {
    return false;
  }
  final local = effective.toLocal();
  if (filterStart != null && local.isBefore(startOfDay(filterStart))) {
    return false;
  }
  if (filterEnd != null && local.isAfter(endOfDay(filterEnd))) {
    return false;
  }
  return true;
}

/// Driver list: assigned to [driverRef], optional status tab, optional date range.
List<OrdersRecord> filterDriverDeliveryOrders(
  List<OrdersRecord> orders, {
  required DocumentReference? driverRef,
  OrderStatus? tabStatus,
  DateTime? filterStart,
  DateTime? filterEnd,
}) {
  if (driverRef == null) {
    return const [];
  }

  final filtered = orders.where((order) {
    if (order.assignedDriver?.path != driverRef.path) {
      return false;
    }
    if (!orderMatchesDriverDeliveryDateRange(
      order,
      filterStart: filterStart,
      filterEnd: filterEnd,
    )) {
      return false;
    }
    return orderMatchesDriverTabStatus(order, tabStatus);
  }).toList();

  filtered.sort((a, b) {
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

  return filtered;
}

/// Active (non-completed) assigned orders in the date window — for route preview.
List<OrdersRecord> driverActiveRouteOrders(
  List<OrdersRecord> orders, {
  required DocumentReference? driverRef,
  DateTime? filterStart,
  DateTime? filterEnd,
}) {
  return filterDriverDeliveryOrders(
    orders,
    driverRef: driverRef,
    tabStatus: null,
    filterStart: filterStart,
    filterEnd: filterEnd,
  ).where((order) {
    final status = order.status;
    return status != OrderStatus.completed && status != OrderStatus.cancelled;
  }).toList();
}
