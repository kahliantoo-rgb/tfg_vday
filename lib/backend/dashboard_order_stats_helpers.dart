import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/backend/daily_sales_report_service.dart';
import '/backend/leftover_orders_helpers.dart';
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
  leftoverOrders,
}

class DashboardOrderStats {
  const DashboardOrderStats({
    required this.todayDeliveryOrders,
    required this.todayPendingOrders,
    required this.todayCompletedOrders,
    required this.todayTotalOrders,
    required this.tomorrowDeliveryOrders,
    required this.tomorrowTotalOrders,
    required this.leftoverOrders,
  });

  final int todayDeliveryOrders;
  final int todayPendingOrders;
  final int todayCompletedOrders;
  final int todayTotalOrders;
  final int tomorrowDeliveryOrders;
  final int tomorrowTotalOrders;
  final int leftoverOrders;
}

class DashboardOrderStatsLoadResult {
  const DashboardOrderStatsLoadResult({
    required this.stats,
    required this.rolledForwardCount,
  });

  final DashboardOrderStats stats;
  final int rolledForwardCount;
}

/// Notifies [SalesDashBoardWidget] to reload counts after orders change.
class DashboardStatsRefresh extends ChangeNotifier {
  DashboardStatsRefresh._();

  static final DashboardStatsRefresh instance = DashboardStatsRefresh._();

  void notifyStatsChanged() => notifyListeners();
}

void notifyDashboardStatsChanged() {
  DashboardStatsRefresh.instance.notifyStatsChanged();
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
  final leftover = countLeftoverDeliveryOrders(orders, asOf: today);

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
    leftoverOrders: leftover,
  );
}

Future<DashboardOrderStats> loadDashboardOrderStats() async {
  final orders = await queryTenantOrdersRecordOnce();
  return computeDashboardOrderStats(orders);
}

/// Reload stats without rolling delivery dates forward (e.g. after delete).
Future<DashboardOrderStatsLoadResult> loadDashboardOrderStatsFresh() async {
  return DashboardOrderStatsLoadResult(
    stats: await loadDashboardOrderStats(),
    rolledForwardCount: 0,
  );
}

/// Rolls past-due incomplete deliveries to today, then returns fresh stats.
Future<DashboardOrderStatsLoadResult> loadDashboardOrderStatsWithRollForward() async {
  final rolledForwardCount = await rollForwardPastDueDeliveryOrders();
  final orders = await queryTenantOrdersRecordOnce();
  return DashboardOrderStatsLoadResult(
    stats: computeDashboardOrderStats(orders),
    rolledForwardCount: rolledForwardCount,
  );
}

/// Opens [OrderlistWidget] with filters matching [filter].
Future<void> openDashboardFilteredOrderList(
  BuildContext context,
  DashboardOrderListFilter filter,
) async {
  final today = calendarDay(DateTime.now());
  final tomorrow = calendarDay(today.add(const Duration(days: 1)));
  DateTime? startDate = today;
  DateTime? endDate = today;
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
    case DashboardOrderListFilter.leftoverOrders:
      orderType = 'Delivery';
      startDate = null;
      endDate = null;
      status = 'all';
      break;
  }

  final queryParameters = <String, String>{
    if (startDate != null)
      'startDate': serializeParam(startDate, ParamType.DateTime)!,
    if (endDate != null)
      'endDate': serializeParam(endDate, ParamType.DateTime)!,
    if (status != 'all') 'status': status,
    if (orderType != null) 'orderType': orderType,
    if (filter == DashboardOrderListFilter.leftoverOrders) 'leftoverOnly': 'true',
  };

  await context.pushNamed(
    OrderlistWidget.routeName,
    queryParameters: queryParameters,
  );
}
