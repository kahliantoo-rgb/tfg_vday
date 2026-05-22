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
import 'dart:convert';
import 'package:intl/intl.dart';

// ===== CSV helper =====
String _toCsv(List<List<String>> rows) {
  return rows
      .map((row) =>
          row.map((cell) => '"${cell.replaceAll('"', '""')}"').join(','))
      .join('\n');
}

Future<FFUploadedFile> exportOrderItemsFinalCsvCopy(
  List<OrderItemRecord> items,
) async {
  if (items.isEmpty) {
    throw Exception('No data to export');
  }

  final rows = <List<String>>[];

  // ===== Header =====
  rows.add([
    'Order ID',
    'Client Name',
    'Customer Phone Number',
    'Address',
    'Region',
    'Order Item',
    'Delivery Date',
    'Card Message',
    'Status',
  ]);

  // ===== Data =====
  for (final i in items) {
    rows.add([
      i.orderId ?? '',
      i.clientName ?? '',
      i.customerphonenumber ?? '',
      i.address ?? '',
      i.region ?? '',
      i.name ?? '',
      i.deliverydate != null
          ? DateFormat('yyyy-MM-dd').format(i.deliverydate!)
          : '',
      i.cardmessage ?? '',
      i.status?.toString() ?? '',
    ]);
  }

  final csv = _toCsv(rows);

  return FFUploadedFile(
    name: 'orders_items_${DateTime.now().millisecondsSinceEpoch}.csv',
    bytes: utf8.encode(csv),
  );
}
// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
