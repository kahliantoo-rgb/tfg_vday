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

Future<FFUploadedFile> exportOrderItemsFinalCsvCopy(
  List<OrderItemRecord> items,
) async {
  if (items.isEmpty) {
    throw Exception('No data to export');
  }

  final rows = <List<String>>[kOrderItemsOnlyCsvHeaders];

  for (final item in items) {
    final row = buildOrderItemOnlyRow(item);
    assertCsvRowMatchesHeader(kOrderItemsOnlyCsvHeaders, row);
    rows.add(row);
  }

  final csv = ordersToCsvString(rows);

  return FFUploadedFile(
    name: 'orders_items_${DateTime.now().millisecondsSinceEpoch}.csv',
    bytes: encodeCsvUtf8Bytes(csv),
  );
}
