import 'package:flutter/material.dart';

import '/backend/schema/enums/enums.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/orders_record.dart';
import '/backend/order_list_filter_helpers.dart';
import '/backend/order_status_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Column labels for the order list table.
const kOrderListColumnLabels = [
  'Order ID',
  'Customer',
  'Recipient',
  'Address',
  'Delivery date',
  'P/D',
  'Product',
  'Status',
];

String orderListOrderId(OrdersRecord order) =>
    order.orderId.isNotEmpty ? order.orderId : order.reference.id;

String orderListCustomer(OrdersRecord order) =>
    order.clientName.isNotEmpty ? order.clientName : '-';

/// Recipient name when stored separately; falls back to customer for legacy orders.
String orderListRecipient(OrdersRecord order) {
  final recipient = order.recipientName;
  if (recipient.trim().isNotEmpty) {
    return recipient.trim();
  }
  return order.clientName.isNotEmpty ? order.clientName : '-';
}

String orderListAddress(OrdersRecord order) =>
    order.address.isNotEmpty ? order.address : '-';

String orderListDeliveryDate(OrdersRecord order, {String? locale}) {
  final effective = orderListEffectiveDate(order);
  if (effective == null) {
    return '-';
  }
  final date = dateTimeFormat(
    'd/M/y',
    effective,
    locale: locale,
  );
  if (!isRetailOrderRecord(order) && order.deliveryTimeSlot.isNotEmpty) {
    return '$date ${order.deliveryTimeSlot}';
  }
  return date;
}

String orderListDeliveryDateOnly(OrdersRecord order, {String? locale}) {
  final date = order.deliveryDate ?? orderListEffectiveDate(order);
  if (date == null) {
    return '-';
  }
  return dateTimeFormat('d/M/y', date, locale: locale);
}

String orderListDeliveryTimeSlot(OrdersRecord order) =>
    order.deliveryTimeSlot.isNotEmpty ? order.deliveryTimeSlot : '-';

String orderListPickupDelivery(OrdersRecord order) {
  final raw = order.pickupDelivery.isNotEmpty
      ? order.pickupDelivery
      : order.orderType;
  if (raw.isEmpty) {
    return '-';
  }
  final lower = raw.toLowerCase();
  if (lower.contains('pick')) {
    return 'Pickup';
  }
  if (lower.contains('deliver')) {
    return 'Delivery';
  }
  if (lower.contains('retail')) {
    return 'Retail';
  }
  return raw;
}

String orderListStatusLabel(OrdersRecord order) {
  if (order.status != null) {
    return legacyOrderStatusLabel(order.status!);
  }
  return order.orderstatus.isNotEmpty ? order.orderstatus : '-';
}

/// One line per product: name, optional remark, qty.
String orderListProductSummary(List<OrderItemRecord> items) {
  if (items.isEmpty) {
    return '-';
  }
  return items.map(formatOrderListProductLine).join('\n');
}

String formatOrderListProductLine(OrderItemRecord item) {
  final name = item.name.isNotEmpty ? item.name : 'Item';
  final remark = item.remark.trim();
  final qty = item.qty > 0 ? item.qty : 1;
  if (remark.isEmpty) {
    return '$name · Qty $qty';
  }
  return '$name · $remark · Qty $qty';
}

List<OrderItemRecord> orderListItemsForOrder(
  List<OrderItemRecord> allItems,
  OrdersRecord order,
) =>
    allItems
        .where((item) => item.orderRef?.id == order.reference.id)
        .toList();

Color orderListStatusColor(OrderStatus? status) {
  switch (status) {
    case OrderStatus.pending:
      return const Color(0xFFFFC107);
    case OrderStatus.processing:
      return const Color(0xFF64B5F6);
    case OrderStatus.ready_to_delivery:
      return const Color(0xFF6758EF);
    case OrderStatus.out_of_delivery:
      return const Color(0xFF26A69A);
    case OrderStatus.completed:
      return const Color(0xFF4CAF50);
    case OrderStatus.cancelled:
      return const Color(0xFFE53935);
    case null:
      return const Color(0xFF9E9E9E);
  }
}
