import 'package:flutter/material.dart';

import '/backend/driver_assignment_helpers.dart';
import '/backend/partial_delivery_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/orders_record.dart';
import '/backend/schema/users_record.dart';
import '/backend/order_list_filter_helpers.dart';
import '/backend/order_status_display.dart';
import '/backend/order_whatsapp_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart' show dateTimeFormat;
import '/l10n/tr.dart';

/// Column labels for the order list table.
List<String> orderListColumnLabels(BuildContext context) => [
      tr(context, 'order.col.orderId'),
      tr(context, 'order.col.customer'),
      tr(context, 'order.col.recipient'),
      tr(context, 'order.col.address'),
      tr(context, 'order.col.deliveryDate'),
      tr(context, 'order.col.pd'),
      tr(context, 'order.col.driver'),
      tr(context, 'order.col.product'),
      tr(context, 'order.col.status'),
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

Map<String, String> orderListDriverNameLookup(Iterable<UsersRecord> users) {
  return {
    for (final user in users) user.reference.path: driverDisplayName(user),
  };
}

String orderListAssignedDriverLabel(
  BuildContext context,
  OrdersRecord order,
  Map<String, String> driverNamesByPath,
) {
  final ref = order.assignedDriver;
  if (ref == null) {
    return tr(context, 'order.driver.unassigned');
  }
  return driverNamesByPath[ref.path] ?? ref.id;
}

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

String orderListPickupDelivery(BuildContext context, OrdersRecord order) {
  final raw = order.pickupDelivery.isNotEmpty
      ? order.pickupDelivery
      : order.orderType;
  if (raw.isEmpty) {
    return '-';
  }
  final lower = raw.toLowerCase();
  if (lower.contains('pick')) {
    return tr(context, 'order.type.pickupLabel');
  }
  if (lower.contains('deliver')) {
    return tr(context, 'order.type.delivery');
  }
  if (lower.contains('retail')) {
    return tr(context, 'order.type.retail');
  }
  return raw;
}

String orderListStatusLabel(BuildContext context, OrdersRecord order) {
  if (order.status != null) {
    return orderStatusDisplayLabel(
      context,
      order.status!,
      isPickup: isPickupOrderRecord(order),
    );
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
  final delivered = readDeliveredQty(item);
  final remaining = remainingDeliveryQty(item);
  final qtyLabel = delivered > 0 && remaining > 0
      ? 'Qty $qty ($delivered delivered)'
      : delivered > 0 && remaining <= 0
          ? 'Qty $qty (delivered)'
          : 'Qty $qty';
  if (remark.isEmpty) {
    return '$name · $qtyLabel';
  }
  return '$name · $remark · $qtyLabel';
}

String formatOrderListProductLineLocalized(
  BuildContext context,
  OrderItemRecord item,
) {
  final name =
      item.name.isNotEmpty ? item.name : tr(context, 'common.item');
  final remark = item.remark.trim();
  final qty = item.qty > 0 ? item.qty : 1;
  final delivered = readDeliveredQty(item);
  final remaining = remainingDeliveryQty(item);
  final String qtyLabel;
  if (delivered > 0 && remaining > 0) {
    qtyLabel = tr(
      context,
      'order.product.qtyDeliveredPartial',
      params: {'qty': '$qty', 'delivered': '$delivered'},
    );
  } else if (delivered > 0 && remaining <= 0) {
    qtyLabel = tr(
      context,
      'order.product.qtyAllDelivered',
      params: {'qty': '$qty'},
    );
  } else {
    qtyLabel = tr(context, 'order.product.qtyOnly', params: {'qty': '$qty'});
  }
  if (remark.isEmpty) {
    return '$name · $qtyLabel';
  }
  return '$name · $remark · $qtyLabel';
}

String orderListProductSummaryLocalized(
  BuildContext context,
  List<OrderItemRecord> items,
) {
  if (items.isEmpty) {
    return '-';
  }
  return items
      .map((item) => formatOrderListProductLineLocalized(context, item))
      .join('\n');
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
