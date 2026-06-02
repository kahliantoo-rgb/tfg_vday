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
import 'csv_export_helpers.dart';
// DO NOT REMOVE THE CODE ABOVE!

import 'dart:convert';

Future<FFUploadedFile> exportOrdersItemsPickupCsv(
  List<OrdersRecord> orders,
  List<OrderItemRecord> orderItems,
) async {
  if (orders.isEmpty) {
    throw Exception('No orders to export');
  }

  final rows = <List<String>>[kOrdersItemsPickupCsvHeaders];

  final orderMap = <String, OrdersRecord>{};
  for (final o in orders) {
    orderMap[o.reference.id] = o;
  }

  for (final item in orderItems) {
    final ref = item.orderRef;
    if (ref == null) {
      continue;
    }

    final order = orderMap[ref.id];
    if (order == null) {
      continue;
    }

    final row = buildOrdersItemsPickupRow(order, item);
    assertCsvRowMatchesHeader(kOrdersItemsPickupCsvHeaders, row);
    rows.add(row);
  }

  if (rows.length == 1) {
    throw Exception(
      'No order line items to export for the selected orders.',
    );
  }

  final csv = ordersToCsvString(rows);

  return FFUploadedFile(
    name: 'orders_with_items_${DateTime.now().millisecondsSinceEpoch}.csv',
    bytes: utf8.encode(csv),
  );
}
