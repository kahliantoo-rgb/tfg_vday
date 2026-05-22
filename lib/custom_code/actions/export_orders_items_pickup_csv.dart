// Automatic FlutterFlow imports
import '/backend/backend.dart';
import '/backend/schema/structs/index.dart';
import '/backend/schema/enums/enums.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom actions
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom action code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import '/flutter_flow/uploaded_file.dart';
// DO NOT REMOVE THE CODE ABOVE!

import 'dart:convert';
import 'package:intl/intl.dart';

/// Convert rows to CSV
String _toCsv(List<List<String>> rows) {
  return rows
      .map(
        (row) => row.map((cell) => '"${cell.replaceAll('"', '""')}"').join(','),
      )
      .join('\n');
}

/// Safe enum export (e.g. OrderStatus.COMPLETED -> COMPLETED)
String exportEnum(dynamic value) {
  if (value == null) return '';
  return value.toString().split('.').last;
}

Future<FFUploadedFile> exportOrdersItemsPickupCsv(
  List<OrdersRecord> orders,
  List<OrderItemRecord> orderItems,
) async {
  if (orders.isEmpty) {
    throw Exception('No orders to export');
  }

  final rows = <List<String>>[];

  // ===== CSV Header =====
  rows.add([
    'Order ID',
    'Client Name',
    'Phone',
    'Order Type',
    'Address',
    'Region',
    'Delivery Date',
    'Delivery Time Slot'
        'Status',
    'Card Message',
    'Product Name',
    'Remark',
    'Item Qty',
  ]);

  // ===== Build order map by DocumentReference =====
  final orderMap = <String, OrdersRecord>{};
  for (final o in orders) {
    orderMap[o.reference.id] = o;
  }

  // ===== Join order_items using orderRef =====
  for (final item in orderItems) {
    final ref = item.orderRef;
    if (ref == null) continue;

    final order = orderMap[ref.id];
    if (order == null) continue;

    rows.add([
      order.orderId ?? order.reference.id,
      order.clientName ?? '',
      order.customerPhoneNumber ?? '',
      order.orderType ?? '', // ✅ pickup_delivery
      order.address ?? '',
      order.region ?? '',
      order.deliveryDate != null
          ? DateFormat('yyyy-MM-dd').format(order.deliveryDate!)
          : '',
      order.deliveryTimeSlot ?? '',
      exportEnum(order.status), // ✅ enum safe export
      order.cardMessage ?? '',
      item.name ?? '',
      item.remark ?? '', // ✅ product name (Firestore: name)
      item.qty?.toString() ?? '0', // ✅ qty
    ]);
  }

  final csv = _toCsv(rows);

  return FFUploadedFile(
    name: 'orders_with_items_${DateTime.now().millisecondsSinceEpoch}.csv',
    bytes: utf8.encode(csv),
  );
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
