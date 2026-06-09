import 'package:flutter/material.dart';

import '/backend/daily_sales_report_service.dart';
import '/backend/order_list_filter_helpers.dart';
import '/backend/order_status_helpers.dart';
import '/backend/schema/orders_record.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Preset filters when opening the order list from dashboard stat cards.
enum DashboardOrderListFilter {
  todayDeliveryOrders,
  todayPendingOrders,
  todayCompletedOrders,
  todayTotalOrders,
  tomorrowDeliveryOrders,
  tomorrowTotalOrders,
}

class DashboardOrderStats {
  const DashboardOrderStats({
    required this.todayDeliveryOrders,
    required this.todayPendingOrders,
    required this.todayCompletedOrders,
    required this.todayTotalOrders,
    required this.tomorrowDeliveryOrders,
    required this.tomorrowTotalOrders,
  });

  final int todayDeliveryOrders;
  final int todayPendingOrders;
  final int todayCompletedOrders;
  final int todayTotalOrders;
  final int tomorrowDeliveryOrders;
  final int tomorrowTotalOrders;
}

bool orderMatchesLegacyStatus(OrdersRecord order, String legacyStatus) {
  if (legacyStatus == 'all') {
    return true;
  }
  if (order.orderstatus == legacyStatus) {
    return true;
  }
  if (order.status != null) {
    return legacyOrderStatusLabel(order.status!) == legacyStatus;
  }
  return false;
}

/// Delivery orders only — excludes pickup and retail walk-ins.
bool isTodayDeliveryOrderRecord(OrdersRecord order, DateTime day) {
  if (!orderMatchesOrderListType(order, 'Delivery')) {
    return false;
  }
  if (orderMatchesOrderListType(order, 'PickUp')) {
    return false;
  }
  return orderMatchesOrderListDateRange(
    order,
    startDate: day,
    endDate: day,
  );
}

bool isTodayOrderRecord(OrdersRecord order, DateTime day) {
  return orderMatchesOrderListDateRange(
    order,
    startDate: day,
    endDate: day,
  );
}

DashboardOrderStats computeDashboardOrderStats(List<OrdersRecord> orders) {
  final today = calendarDay(DateTime.now());
  final tomorrow = calendarDay(today.add(const Duration(days: 1)));

  var delivery = 0;
  var pending = 0;
  var completed = 0;
  var total = 0;
  var tomorrowDelivery = 0;
  var tomorrowTotal = 0;

  for (final order in orders) {
    if (isTodayOrderRecord(order, today)) {
      total++;
      if (orderMatchesLegacyStatus(order, 'pending')) {
        pending++;
      }
      if (orderMatchesLegacyStatus(order, 'completed')) {
        completed++;
      }
      if (isTodayDeliveryOrderRecord(order, today)) {
        delivery++;
      }
    }
    if (isTodayOrderRecord(order, tomorrow)) {
      tomorrowTotal++;
      if (isTodayDeliveryOrderRecord(order, tomorrow)) {
        tomorrowDelivery++;
      }
    }
  }

  return DashboardOrderStats(
    todayDeliveryOrders: delivery,
    todayPendingOrders: pending,
    todayCompletedOrders: completed,
    todayTotalOrders: total,
    tomorrowDeliveryOrders: tomorrowDelivery,
    tomorrowTotalOrders: tomorrowTotal,
  );
}

Future<DashboardOrderStats> loadDashboardOrderStats() async {
  final orders = await queryTenantOrdersRecordOnce();
  return computeDashboardOrderStats(orders);
}

/// Opens [OrderlistWidget] with filters matching [filter].
void openDashboardFilteredOrderList(
  BuildContext context,
  DashboardOrderListFilter filter,
) {
  final today = calendarDay(DateTime.now());
  final tomorrow = calendarDay(today.add(const Duration(days: 1)));
  var startDate = today;
  var endDate = today;
  String status = 'all';
  String? orderType;

  switch (filter) {
    case DashboardOrderListFilter.todayDeliveryOrders:
      orderType = 'Delivery';
      break;
    case DashboardOrderListFilter.todayPendingOrders:
      status = 'pending';
      break;
    case DashboardOrderListFilter.todayCompletedOrders:
      status = 'completed';
      break;
    case DashboardOrderListFilter.todayTotalOrders:
      break;
    case DashboardOrderListFilter.tomorrowDeliveryOrders:
      startDate = tomorrow;
      endDate = tomorrow;
      orderType = 'Delivery';
      break;
    case DashboardOrderListFilter.tomorrowTotalOrders:
      startDate = tomorrow;
      endDate = tomorrow;
      break;
  }

  final queryParameters = <String, String>{
    'startDate': serializeParam(startDate, ParamType.DateTime)!,
    'endDate': serializeParam(endDate, ParamType.DateTime)!,
    if (status != 'all') 'status': status,
    if (orderType != null) 'orderType': orderType,
  };

  context.pushNamed(
    OrderlistWidget.routeName,
    queryParameters: queryParameters,
  );
}
