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

import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer_library.dart';
import '/custom_code/bluetooth_receipt_printer.dart';
import '/backend/company_query_helpers.dart';

/// Prints ESC/POS receipt bytes to a Bluetooth thermal printer.
/// Uses [macAddress] when provided, otherwise the saved App State address.
Future<void> printOrderReceiptEscPos(
  String macAddress,
  List<OrderItemRecord> items,
  String totalAmount,
) async {
  if (kIsWeb || items.isEmpty) return;

  final address = macAddress.isNotEmpty
      ? macAddress
      : FFAppState().bluetoothPrinterAddress;
  if (address.isEmpty) return;

  final orderRef = items.first.orderRef;
  if (orderRef == null) return;

  final order = await OrdersRecord.getDocumentOnce(orderRef);
  final company = await getDefaultCompanyOnce();

  final data = Uint8List.fromList(
    BluetoothReceiptPrinter.buildReceiptBytes(
      order: order,
      items: items,
      company: company,
    ),
  );

  try {
    await FlutterBluetoothPrinter.printBytes(
      address: address,
      data: data,
      keepConnected: false,
    );
  } catch (e) {
    debugPrint('Bluetooth print error: $e');
  }
}
