import 'package:flutter/material.dart';

import '/backend/backend.dart';
import '/backend/order_list_filter_helpers.dart';
import '/custom_code/actions/index.dart' as actions;
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/uploaded_file.dart';

/// Builds CSV from [orders] + [items], downloads with a `.csv` filename.
Future<void> downloadOrdersCsv({
  required BuildContext context,
  required List<OrdersRecord> orders,
  required List<OrderItemRecord> allOrderItems,
  String? filenameBase,
}) async {
  if (orders.isEmpty) {
    throw Exception('No orders to export');
  }

  final items = orderItemsForOrders(allOrderItems, orders);
  final FFUploadedFile file;
  if (items.isNotEmpty) {
    file = await actions.exportOrdersItemsPickupCsv(orders, items);
  } else {
    file = await actions.exportOrdersToCsv(orders);
  }

  final base =
      filenameBase ?? 'orders_${DateTime.now().millisecondsSinceEpoch}';
  final filename = base.endsWith('.csv') ? base : '$base.csv';

  await downloadFile(
    filename: filename,
    uploadedFile: file,
  );
}
