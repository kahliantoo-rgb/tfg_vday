import '/backend/backend.dart';
import '/backend/order_status_helpers.dart';
import '/backend/schema/order_item_record.dart';
import 'package:intl/intl.dart';

/// CSV column titles for order + line-item export (Order List → Export CSV).
const kOrdersItemsPickupCsvHeaders = [
  'Order ID',
  'Client Name',
  'Phone',
  'Order Type',
  'Address',
  'Region',
  'Delivery Date',
  'Delivery Time Slot',
  'Status',
  'Card Message',
  'Product Name',
  'Remark',
  'Item Qty',
];

/// CSV column titles for order-only export.
const kOrdersOnlyCsvHeaders = [
  'Order ID',
  'Client Name',
  'Phone',
  'Order Type',
  'Delivery Address',
  'Region',
  'Postal Code',
  'Delivery Date',
  'Delivery Time Slot',
  'Status',
  'Total Amount',
  'Created Time',
];

/// CSV column titles for line-item export.
const kOrderItemsOnlyCsvHeaders = [
  'Order ID',
  'Client Name',
  'Phone',
  'Address',
  'Region',
  'Product Name',
  'Qty',
  'Unit Price',
  'Item Remark',
  'Delivery Date',
  'Card Message',
  'Status',
];

String ordersToCsvString(List<List<String>> rows) {
  return rows
      .map(
        (row) => row.map((cell) => '"${cell.replaceAll('"', '""')}"').join(','),
      )
      .join('\n');
}

/// Ensures every data row has the same column count as [header].
void assertCsvRowMatchesHeader(List<String> header, List<String> row) {
  if (row.length != header.length) {
    throw StateError(
      'CSV column mismatch: header has ${header.length} columns '
      'but row has ${row.length}. Headers: $header',
    );
  }
}

String formatDeliveryDate(DateTime? date) {
  if (date == null) {
    return '';
  }
  return DateFormat('yyyy-MM-dd').format(date);
}

String formatCreatedTime(DateTime? dateTime) {
  if (dateTime == null) {
    return '';
  }
  return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
}

/// Status label aligned with order list filters (orderstatus / legacy labels).
String formatOrderStatusForCsv(OrdersRecord order) {
  if (order.orderstatus.isNotEmpty) {
    return order.orderstatus;
  }
  if (order.status != null) {
    return legacyOrderStatusLabel(order.status!);
  }
  return '';
}

String formatOrderTypeForCsv(OrdersRecord order) {
  if (order.orderType.isNotEmpty) {
    return order.orderType;
  }
  return order.pickupDelivery;
}

String formatItemStatusForCsv(String status) => status;

/// One CSV data row: order fields + product line (Product Name = item.name).
List<String> buildOrdersItemsPickupRow(
  OrdersRecord order,
  OrderItemRecord item,
) {
  return [
    order.orderId.isNotEmpty ? order.orderId : order.reference.id,
    order.clientName,
    order.customerPhoneNumber,
    formatOrderTypeForCsv(order),
    order.address,
    order.region,
    formatDeliveryDate(order.deliveryDate),
    order.deliveryTimeSlot,
    formatOrderStatusForCsv(order),
    order.cardMessage,
    item.name,
    item.remark,
    item.qty > 0 ? item.qty.toString() : '0',
  ];
}

List<String> buildOrdersOnlyRow(OrdersRecord order) {
  return [
    order.orderId.isNotEmpty ? order.orderId : order.reference.id,
    order.clientName,
    order.customerPhoneNumber,
    formatOrderTypeForCsv(order),
    order.address,
    order.region,
    order.postalCode,
    formatDeliveryDate(order.deliveryDate),
    order.deliveryTimeSlot,
    formatOrderStatusForCsv(order),
    order.totalAmount > 0 ? order.totalAmount.toStringAsFixed(2) : '0.00',
    formatCreatedTime(order.createdTime),
  ];
}

List<String> buildOrderItemOnlyRow(OrderItemRecord item) {
  return [
    item.orderId,
    item.clientName,
    item.customerphonenumber,
    item.address,
    item.region,
    item.name,
    item.qty > 0 ? item.qty.toString() : '',
    item.price > 0 ? item.price.toStringAsFixed(2) : '',
    item.remark,
    formatDeliveryDate(item.deliverydate),
    item.cardmessage,
    formatItemStatusForCsv(item.status),
  ];
}
