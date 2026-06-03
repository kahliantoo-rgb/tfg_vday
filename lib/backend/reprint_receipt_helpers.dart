import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/backend/schema/orders_record.dart';
import '/custom_code/bluetooth_receipt_printer.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Retail / walk-in orders use the POS receipt preview page.
bool isRetailReceiptOrder(OrdersRecord order) {
  final type = order.orderType.toLowerCase();
  return type == 'retail' || type == 'cashier';
}

/// Opens the correct receipt preview for reprinting (web + mobile).
void openReprintReceiptPreview(
  BuildContext context,
  DocumentReference orderRef,
  OrdersRecord order,
) {
  final orderRefParam = serializeParam(
    orderRef,
    ParamType.DocumentReference,
  );
  final queryParams = orderRefParam != null
      ? <String, String>{'orderRef': orderRefParam}
      : const <String, String>{};
  final extra = <String, dynamic>{'orderRef': orderRef};

  if (isRetailReceiptOrder(order)) {
    context.pushNamed(
      ReceiptPreviewpage2Widget.routeName,
      queryParameters: queryParams,
      extra: extra,
    );
  } else {
    context.pushNamed(
      DeliveryReceiptPreviewPageWidget.routeName,
      queryParameters: queryParams,
      extra: extra,
    );
  }
}

/// Reprint: thermal on app; receipt preview on web (or if print fails).
Future<void> reprintOrderReceipt(
  BuildContext context,
  DocumentReference orderRef,
  OrdersRecord order,
) async {
  if (!kIsWeb) {
    final printed =
        await BluetoothReceiptPrinter.printOrderByRef(context, orderRef);
    if (printed) {
      return;
    }
  }
  if (!context.mounted) {
    return;
  }
  openReprintReceiptPreview(context, orderRef, order);
}
