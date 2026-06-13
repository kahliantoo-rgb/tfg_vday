import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/leftover_orders_helpers.dart';
import '/backend/order_id_service.dart';
import '/backend/tenant_query_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/orders_record.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/order_status_helpers.dart';
import '/backend/order_whatsapp_helpers.dart';

/// Firestore query for order list: tenant scope only.
/// Date/type/status/search filters run in memory so retail (created_time)
/// and delivery (delivery_date) orders both appear correctly.
Query Function(Query) buildOrderListFirestoreQuery({
  DateTime? startDate,
  DateTime? endDate,
}) {
  return applyTenantCompanyFilter;
}

/// True when [order] is a walk-in / retail sale.
bool isRetailOrderRecord(OrdersRecord order) {
  if (order.orderType.toLowerCase().contains('retail')) {
    return true;
  }
  if (order.pickupDelivery.toLowerCase().contains('retail')) {
    return true;
  }
  return OrderIdService.isRetailOrderId(order.orderId);
}

/// Retail uses [OrdersRecord.createdTime]; delivery uses [OrdersRecord.deliveryDate].
DateTime? orderListEffectiveDate(OrdersRecord order) {
  if (isRetailOrderRecord(order)) {
    return order.createdTime ?? order.deliveryDate;
  }
  return order.deliveryDate ?? order.createdTime;
}

bool orderMatchesOrderListDateRange(
  OrdersRecord order, {
  DateTime? startDate,
  DateTime? endDate,
}) {
  if (startDate == null && endDate == null) {
    return true;
  }
  final effective = orderListEffectiveDate(order);
  if (effective == null) {
    return startDate == null && endDate == null;
  }
  if (startDate != null && effective.isBefore(startOfDay(startDate))) {
    return false;
  }
  if (endDate != null && effective.isAfter(endOfDay(endDate))) {
    return false;
  }
  return true;
}

bool orderMatchesOrderListType(OrdersRecord order, String orderType) {
  if (order.orderType == orderType || order.pickupDelivery == orderType) {
    return true;
  }
  if (orderType == 'Retail' && isRetailOrderRecord(order)) {
    return true;
  }
  if (orderType == 'Delivery') {
    final raw = order.pickupDelivery.isNotEmpty
        ? order.pickupDelivery
        : order.orderType;
    return raw.toLowerCase().contains('deliver');
  }
  if (orderType == 'PickUp') {
    final raw = order.pickupDelivery.isNotEmpty
        ? order.pickupDelivery
        : order.orderType;
    return raw.toLowerCase().contains('pick');
  }
  return false;
}

/// Firestore `orderstatus` values used by the order list status dropdown.
const kOrderListLegacyStatusOptions = [
  'pending',
  'processing',
  'readyToShip',
  'outOfDelivery',
  'completed',
  'cancelled',
];

DateTime startOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

DateTime endOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

/// Default All Orders: 3 days before today through 3 days after (7 days total).
({DateTime start, DateTime end}) defaultOrderListDateRange({
  DateTime? asOf,
}) {
  final today = startOfDay(asOf ?? DateTime.now());
  return (
    start: startOfDay(today.subtract(const Duration(days: 3))),
    end: endOfDay(today.add(const Duration(days: 3))),
  );
}

/// Client-side status, order type, date range, and text search.
List<OrdersRecord> applyOrderListClientFilters({
  required List<OrdersRecord> orders,
  required List<OrderItemRecord> orderItems,
  String? legacyStatus,
  String? orderType,
  DateTime? startDate,
  DateTime? endDate,
  required String searchText,
  bool leftoverOnly = false,
}) {
  var result = orders;

  if (leftoverOnly) {
    result = result.where((o) => isLeftoverDeliveryOrder(o)).toList();
  } else {
    result = result
        .where(
          (o) => orderMatchesOrderListDateRange(
            o,
            startDate: startDate,
            endDate: endDate,
          ),
        )
        .toList();
  }

  if (legacyStatus != null &&
      legacyStatus.isNotEmpty &&
      legacyStatus != 'all') {
    result = result
        .where(
          (o) =>
              o.orderstatus == legacyStatus ||
              (o.status != null &&
                  legacyOrderStatusLabel(o.status!) == legacyStatus),
        )
        .toList();
  }

  if (isOrderListTypeFilterActive(orderType)) {
    result = result
        .where((o) => orderMatchesOrderListType(o, orderType!))
        .toList();
  }

  return applyOrderListTextFilter(
    orders: result,
    orderItems: orderItems,
    searchText: searchText,
  );
}

/// True when retail / delivery / pickup chip filter should apply.
bool isOrderListTypeFilterActive(String? orderType) {
  final normalized = orderType?.trim();
  if (normalized == null || normalized.isEmpty) {
    return false;
  }
  return normalized.toLowerCase() != 'all';
}

/// Maps legacy dropdown value to [OrderStatus] for display checks.
OrderStatus? legacyStatusToEnum(String? legacy) {
  if (legacy == null || legacy.isEmpty || legacy == 'all') {
    return null;
  }
  switch (legacy) {
    case 'pending':
      return OrderStatus.pending;
    case 'processing':
      return OrderStatus.processing;
    case 'readyToShip':
      return OrderStatus.ready_to_delivery;
    case 'outOfDelivery':
      return OrderStatus.out_of_delivery;
    case 'completed':
      return OrderStatus.completed;
    case 'cancelled':
      return OrderStatus.cancelled;
    default:
      return null;
  }
}

/// Client-side text filter: name, address, order id, region, phone, product names.
List<OrdersRecord> applyOrderListTextFilter({
  required List<OrdersRecord> orders,
  required List<OrderItemRecord> orderItems,
  required String searchText,
}) {
  final query = searchText.trim().toLowerCase();
  if (query.isEmpty) {
    return orders;
  }

  final productsByOrderId = <String, List<String>>{};
  for (final item in orderItems) {
    final ref = item.orderRef;
    if (ref == null) {
      continue;
    }
    productsByOrderId.putIfAbsent(ref.id, () => []).add(item.name.toLowerCase());
  }

  return orders.where((order) {
    if (order.orderId.toLowerCase().contains(query)) {
      return true;
    }
    if (order.clientName.toLowerCase().contains(query)) {
      return true;
    }
    if (order.recipientName.toLowerCase().contains(query)) {
      return true;
    }
    if (order.address.toLowerCase().contains(query)) {
      return true;
    }
    if (order.region.toLowerCase().contains(query)) {
      return true;
    }
    if (orderRecipientPhone(order).toLowerCase().contains(query)) {
      return true;
    }
    if (order.customerPhoneNumber.toLowerCase().contains(query)) {
      return true;
    }
    final statusLabel = order.status != null
        ? legacyOrderStatusLabel(order.status!)
        : order.orderstatus;
    if (statusLabel.toLowerCase().contains(query)) {
      return true;
    }
    if (order.status?.name.toLowerCase().contains(query) ?? false) {
      return true;
    }
    final products = productsByOrderId[order.reference.id] ?? [];
    return products.any((name) => name.contains(query));
  }).toList();
}

/// Keeps only line items that belong to [orders].
List<OrderItemRecord> orderItemsForOrders(
  List<OrderItemRecord> allItems,
  List<OrdersRecord> orders,
) {
  final orderIds = orders.map((o) => o.reference.id).toSet();
  return allItems
      .where((item) => item.orderRef != null && orderIds.contains(item.orderRef!.id))
      .toList();
}
