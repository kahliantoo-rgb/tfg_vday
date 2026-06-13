import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/daily_sales_report_service.dart';
import '/backend/order_list_filter_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/orders_record.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Delivery order scheduled on or before [asOf] that is still not completed.
bool isLeftoverDeliveryOrder(
  OrdersRecord order, {
  DateTime? asOf,
}) {
  if (order.status == OrderStatus.completed ||
      order.status == OrderStatus.cancelled) {
    return false;
  }
  if (!orderMatchesOrderListType(order, 'Delivery')) {
    return false;
  }
  if (orderMatchesOrderListType(order, 'PickUp')) {
    return false;
  }

  final scheduled = order.deliveryDate;
  if (scheduled == null) {
    return false;
  }

  final today = calendarDay(asOf ?? DateTime.now());
  final scheduledDay = calendarDay(scheduled);
  if (scheduledDay.isAfter(today)) {
    return false;
  }

  if (order.status == OrderStatus.out_of_delivery) {
    return true;
  }

  if (scheduledDay.isBefore(today) &&
      (order.status == OrderStatus.ready_to_delivery ||
          order.status == OrderStatus.processing)) {
    return true;
  }

  return false;
}

/// Past-due leftovers should appear on today's delivery schedule.
bool needsRollForwardDeliveryDate(
  OrdersRecord order, {
  DateTime? asOf,
}) {
  if (!isLeftoverDeliveryOrder(order, asOf: asOf)) {
    return false;
  }
  final scheduled = order.deliveryDate;
  if (scheduled == null) {
    return false;
  }
  final today = calendarDay(asOf ?? DateTime.now());
  return calendarDay(scheduled).isBefore(today);
}

int countLeftoverDeliveryOrders(
  List<OrdersRecord> orders, {
  DateTime? asOf,
}) =>
    orders
        .where((order) => isLeftoverDeliveryOrder(order, asOf: asOf))
        .length;

/// Moves missed delivery dates to today so drivers see them on the current run.
Future<int> rollForwardPastDueDeliveryOrders({
  DateTime? asOf,
}) async {
  final today = calendarDay(asOf ?? DateTime.now());
  final orders = await queryTenantOrdersRecordOnce();
  var count = 0;

  for (final order in orders) {
    if (!needsRollForwardDeliveryDate(order, asOf: asOf)) {
      continue;
    }
    await order.reference.update(
      createOrdersRecordData(deliveryDate: today),
    );
    count++;
  }

  return count;
}
