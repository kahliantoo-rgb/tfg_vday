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

import '/custom_code/actions/index.dart';

import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer_library.dart';
import '/backend/schema/order_item_record.dart';

Future<void> printOrderReceiptEscPos(
  String macAddress,
  List<OrderItemRecord> items,
  String totalAmount,
) async {
  final List<int> buffer = [];

  // ===== 初始化 =====
  buffer.addAll([0x1B, 0x40]);

  // ===== 标题 =====
  buffer.addAll(utf8.encode('DELIVERY ORDER\n'));
  buffer.addAll([0x0A]);

  // ===== 订单项目 =====
  for (final item in items) {
    final name = item.name ?? '';
    final qty = item.qty?.toString() ?? '1';
    buffer.addAll(utf8.encode('$name x$qty\n'));
  }

  buffer.addAll([0x0A]);

  // ===== 合计 =====
  buffer.addAll(utf8.encode('TOTAL: $totalAmount\n'));

  // ===== 切纸 =====
  buffer.addAll([0x1D, 0x56, 0x00]);

  // ===== 蓝牙打印（2.17.0 正确写法）=====
  try {
    await FlutterBluetoothPrinter.printBytes(
      address: macAddress,
      data: Uint8List.fromList(buffer),
      keepConnected: false,
    );
  } catch (e) {
    print('Error printing: $e');
    // Handle the error appropriately, e.g., show a dialog to the user
  }
}
