import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer_library.dart';
import 'package:flutter_bluetooth_printer_platform_interface/flutter_bluetooth_printer_platform_interface.dart';

import '/app_state.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/company_query_helpers.dart';
import '/backend/schema/companies_record.dart';

/// Bluetooth thermal receipt printing (ESC/POS). Android / iOS only.
class BluetoothReceiptPrinter {
  static const int _lineWidth = 32;

  static void showSnack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static Future<BluetoothDevice?> pickPrinter(BuildContext context) async {
    if (kIsWeb) {
      showSnack(
        context,
        'Bluetooth printing works on Android/iOS only, not in the browser.',
      );
      return null;
    }

    return showModalBottomSheet<BluetoothDevice>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.65,
        child: const BluetoothDeviceSelector(
          title: Text(
            'Select Bluetooth Printer',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  static Future<bool> selectAndSavePrinter(BuildContext context) async {
    final device = await pickPrinter(context);
    if (device == null) return false;

    final appState = FFAppState();
    appState.bluetoothPrinterAddress = device.address;
    appState.bluetoothPrinterName = device.name ?? device.address;

    if (context.mounted) {
      showSnack(
        context,
        'Printer set: ${appState.bluetoothPrinterName}',
      );
    }
    return true;
  }

  static Future<bool> _ensurePrinter(BuildContext context) async {
    final address = FFAppState().bluetoothPrinterAddress;
    if (address.isNotEmpty) return true;
    return selectAndSavePrinter(context);
  }

  static void _writeLine(List<int> buffer, String text) {
    buffer.addAll(utf8.encode(text));
    buffer.add(0x0A);
  }

  static void _writeCenter(List<int> buffer, String text) {
    buffer.addAll([0x1B, 0x61, 0x01]); // center align
    _writeLine(buffer, text);
    buffer.addAll([0x1B, 0x61, 0x00]); // left align
  }

  static void _writeBold(List<int> buffer, String text) {
    buffer.addAll([0x1B, 0x45, 0x01]);
    _writeLine(buffer, text);
    buffer.addAll([0x1B, 0x45, 0x00]);
  }

  static String _twoColumn(String left, String right) {
    final r = right.length > 10 ? right.substring(0, 10) : right;
    final space = _lineWidth - left.length - r.length;
    if (space < 1) {
      return '${left.substring(0, _lineWidth - r.length - 1)} $r';
    }
    return '$left${' ' * space}$r';
  }

  static String _money(double value) => '\$${value.toStringAsFixed(2)}';

  static List<int> buildReceiptBytes({
    required OrdersRecord order,
    required List<OrderItemRecord> items,
    CompaniesRecord? company,
  }) {
    final buffer = <int>[];

    // Initialize printer
    buffer.addAll([0x1B, 0x40]);

    final companyName = company?.companyName ?? 'TFG VDAY';
    _writeCenter(buffer, companyName);

    if (company != null && company.companyUen.isNotEmpty) {
      _writeCenter(buffer, 'UEN: ${company.companyUen}');
    }
    if (company != null && company.companyPhone.isNotEmpty) {
      _writeCenter(buffer, company.companyPhone);
    }
    if (company != null && company.companyAddress.isNotEmpty) {
      _writeCenter(buffer, company.companyAddress);
    }

    buffer.add(0x0A);
    _writeLine(buffer, '--------------------------------');

    final isDelivery = order.orderType.toLowerCase().contains('delivery');
    _writeBold(buffer, isDelivery ? 'DELIVERY RECEIPT' : 'SALES RECEIPT');

    if (order.orderId.isNotEmpty) {
      _writeLine(buffer, 'Order: ${order.orderId}');
    }
    if (order.createdTime != null) {
      _writeLine(
        buffer,
        'Date: ${dateTimeFormat('yyyy-MM-dd HH:mm', order.createdTime)}',
      );
    }
    if (order.paymentType.isNotEmpty) {
      _writeLine(buffer, 'Payment: ${order.paymentType}');
    }

    if (isDelivery) {
      if (order.clientName.isNotEmpty) {
        _writeLine(buffer, 'Customer: ${order.clientName}');
      }
      if (order.customerPhoneNumber.isNotEmpty) {
        _writeLine(buffer, 'Phone: ${order.customerPhoneNumber}');
      }
      if (order.address.isNotEmpty) {
        _writeLine(buffer, 'Addr: ${order.address}');
      }
      if (order.deliveryDate != null) {
        _writeLine(
          buffer,
          'Delivery: ${dateTimeFormat('yyyy-MM-dd', order.deliveryDate)}',
        );
      }
      if (order.deliveryTimeSlot.isNotEmpty) {
        _writeLine(buffer, 'Slot: ${order.deliveryTimeSlot}');
      }
      if (order.cardMessage.isNotEmpty) {
        _writeLine(buffer, 'Card: ${order.cardMessage}');
      }
    }

    buffer.add(0x0A);
    _writeLine(buffer, '--------------------------------');
    _writeLine(buffer, 'ITEMS');

    double computedTotal = 0;
    for (final item in items) {
      final name = item.name.isNotEmpty ? item.name : 'Item';
      final qty = item.qty > 0 ? item.qty : 1;
      final lineTotal =
          item.subtotal > 0 ? item.subtotal : item.price * qty;
      computedTotal += lineTotal;

      final shortName =
          name.length > 18 ? '${name.substring(0, 17)}.' : name;
      _writeLine(buffer, _twoColumn('$shortName x$qty', _money(lineTotal)));
      if (item.remark.isNotEmpty) {
        _writeLine(buffer, '  * ${item.remark}');
      }
    }

    buffer.add(0x0A);
    _writeLine(buffer, '--------------------------------');

    final total = order.total > 0
        ? order.total
        : (order.totalAmount > 0 ? order.totalAmount : computedTotal);
    _writeBold(buffer, _twoColumn('TOTAL', _money(total)));

    buffer.add(0x0A);
    _writeCenter(buffer, 'Thank you!');
    buffer.add(0x0A);

    // Partial cut
    buffer.addAll([0x1D, 0x56, 0x00]);

    return buffer;
  }

  static Future<bool> printOrderReceipt(
    BuildContext context, {
    required OrdersRecord order,
    required List<OrderItemRecord> items,
    CompaniesRecord? company,
  }) async {
    if (kIsWeb) {
      showSnack(
        context,
        'Use the Android or iOS app to print via Bluetooth.',
      );
      return false;
    }

    if (!await _ensurePrinter(context)) {
      return false;
    }

    if (items.isEmpty) {
      showSnack(context, 'No items to print.');
      return false;
    }

    final address = FFAppState().bluetoothPrinterAddress;
    try {
      final data = Uint8List.fromList(
        buildReceiptBytes(order: order, items: items, company: company),
      );
      final ok = await FlutterBluetoothPrinter.printBytes(
        address: address,
        data: data,
        keepConnected: false,
      );

      if (context.mounted) {
        showSnack(
          context,
          ok ? 'Receipt sent to printer.' : 'Print failed. Check printer.',
        );
      }
      return ok;
    } catch (e) {
      if (context.mounted) {
        showSnack(context, 'Print error: $e');
      }
      return false;
    }
  }

  static Future<bool> printOrderByRef(
    BuildContext context,
    DocumentReference orderRef,
  ) async {
    final order = await OrdersRecord.getDocumentOnce(orderRef);
    final items = await queryOrderItemRecordOnce(
      queryBuilder: (q) => q.where('orderRef', isEqualTo: orderRef),
    );

    final company = await getDefaultCompanyOnce();

    return printOrderReceipt(
      context,
      order: order,
      items: items,
      company: company,
    );
  }
}
