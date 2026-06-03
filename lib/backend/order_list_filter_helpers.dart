import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/tenant_query_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/orders_record.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/order_status_helpers.dart';

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

/// Firestore query: delivery date range only (avoids brittle composite indexes).
Query Function(Query) buildOrderListFirestoreQuery({
  DateTime? startDate,
  DateTime? endDate,
}) {
  return (Query query) {
    query = applyTenantCompanyFilter(query);
    if (startDate != null) {
      query = query.where(
        'delivery_date',
        isGreaterThanOrEqualTo: startOfDay(startDate),
      );
    }
    if (endDate != null) {
      query = query.where(
        'delivery_date',
        isLessThanOrEqualTo: endOfDay(endDate),
      );
    }
    return query;
  };
}

/// Status, order type, and text search (name, address, product, status label).
List<OrdersRecord> applyOrderListClientFilters({
  required List<OrdersRecord> orders,
  required List<OrderItemRecord> orderItems,
  String? legacyStatus,
  String? orderType,
  required String searchText,
}) {
  var result = orders;

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
        .where(
          (o) => o.orderType == orderType || o.pickupDelivery == orderType,
        )
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
    if (order.address.toLowerCase().contains(query)) {
      return true;
    }
    if (order.region.toLowerCase().contains(query)) {
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
