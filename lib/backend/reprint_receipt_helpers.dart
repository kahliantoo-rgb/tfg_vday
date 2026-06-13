import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/backend/schema/orders_record.dart';
import '/custom_code/bluetooth_receipt_printer.dart';
import '/custom_code/delivery_order_pdf_printer.dart';
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
  final queryParams = <String, String>{
    if (orderRefParam != null) 'orderRef': orderRefParam,
  };
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

enum OrderPrintFormat { invoice, receipt }

Future<OrderPrintFormat?> showOrderPrintFormatPicker(
  BuildContext context,
  OrdersRecord order,
) async {
  final isRetail = isRetailReceiptOrder(order);
  final receiptSubtitle = isRetail
      ? (kIsWeb
          ? 'Open sales receipt preview'
          : 'Bluetooth sales receipt with prices')
      : (kIsWeb
          ? 'Open delivery receipt preview'
          : 'Bluetooth delivery receipt with prices');

  return showModalBottomSheet<OrderPrintFormat>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Print invoice or receipt',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf),
            title: const Text('Cash Invoice'),
            subtitle: const Text('PDF A4 with prices'),
            onTap: () => Navigator.pop(sheetContext, OrderPrintFormat.invoice),
          ),
          ListTile(
            leading: const Icon(Icons.print),
            title: const Text('Receipt'),
            subtitle: Text(receiptSubtitle),
            onTap: () => Navigator.pop(sheetContext, OrderPrintFormat.receipt),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<void> _printOrderInvoice(
  BuildContext context,
  DocumentReference orderRef,
) async {
  await DeliveryOrderPdfPrinter.printDeliveryOrderPdfA4(context, orderRef);
}

Future<void> _printOrderReceipt(
  BuildContext context,
  DocumentReference orderRef,
  OrdersRecord order,
) async {
  if (kIsWeb) {
    openReprintReceiptPreview(context, orderRef, order);
    return;
  }
  await BluetoothReceiptPrinter.printOrderByRef(context, orderRef);
}

/// Ask invoice (PDF) vs receipt (thermal or preview on web), then print.
Future<void> promptAndReprintOrderReceipt(
  BuildContext context,
  DocumentReference orderRef,
  OrdersRecord order,
) async {
  final format = await showOrderPrintFormatPicker(context, order);
  if (format == null || !context.mounted) {
    return;
  }
  switch (format) {
    case OrderPrintFormat.invoice:
      await _printOrderInvoice(context, orderRef);
      break;
    case OrderPrintFormat.receipt:
      await _printOrderReceipt(context, orderRef, order);
      break;
  }
}

/// Reprint: thermal on app; receipt preview on web (or if print fails).
Future<void> reprintOrderReceipt(
  BuildContext context,
  DocumentReference orderRef,
  OrdersRecord order,
) async {
  await promptAndReprintOrderReceipt(context, orderRef, order);
}
