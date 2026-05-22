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

String _toCsv(List<List<String>> rows) {
  return rows
      .map((row) =>
          row.map((cell) => '"${cell.replaceAll('"', '""')}"').join(','))
      .join('\n');
}

Future<FFUploadedFile> exportOrdersToCsv(
  List<OrdersRecord> orders,
) async {
  if (orders.isEmpty) {
    throw Exception('No orders to export');
  }

  final rows = <List<String>>[];

  // ===== Header =====
  rows.add([
    'Order ID',
    'Delivery Address',
    'Region',
    'Client Name',
    'Phone',
    'Delivery Date',
    'Status',
    'Total Amount',
    'Created Time',
  ]);

  // ===== Data =====
  for (final o in orders) {
    rows.add([
      o.orderId ?? '',
      o.address ?? '',
      o.region ?? '',
      o.clientName ?? '',
      o.customerPhoneNumber ?? '',
      o.deliveryDate != null
          ? DateFormat('yyyy-MM-dd').format(o.deliveryDate!)
          : '',
      o.status?.toString() ?? '',
      o.totalAmount != null ? o.totalAmount!.toStringAsFixed(2) : '0.00',
      o.createdTime != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(o.createdTime!)
          : '',
    ]);
  }

  final csv = _toCsv(rows);

  return FFUploadedFile(
    name: 'orders_${DateTime.now().millisecondsSinceEpoch}.csv',
    bytes: utf8.encode(csv),
  );
}

// Set your action name, define your arguments and return parameter,
// and then add the boilerplate code using the green button on the right!
