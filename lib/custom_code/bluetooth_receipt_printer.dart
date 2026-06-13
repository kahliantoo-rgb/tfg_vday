import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer_library.dart';
import 'package:flutter_bluetooth_printer_platform_interface/flutter_bluetooth_printer_platform_interface.dart';

import '/app_state.dart';
import '/backend/audit_log_helpers.dart';
import '/backend/backend.dart';
import '/backend/company_query_helpers.dart';
import '/backend/order_item_helpers.dart';
import '/backend/schema/companies_record.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/orders_record.dart';
import '/custom_code/esc_pos_receipt_builder.dart';
import '/custom_code/thermal_paper_helpers.dart';

/// Bluetooth thermal receipt printing (ESC/POS). Android / iOS only.
class BluetoothReceiptPrinter {
  static String? _connectedAddress;
  static bool _printing = false;

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

  static Future<void> openPrinterSettings(BuildContext context) async {
    if (kIsWeb) {
      showSnack(
        context,
        'Bluetooth printing works on Android/iOS only, not in the browser.',
      );
      return;
    }

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        final appState = FFAppState();
        final paper = activeThermalPaperSize().label;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Bluetooth printer',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('Select printer'),
                subtitle: appState.bluetoothPrinterName.isNotEmpty
                    ? Text(appState.bluetoothPrinterName)
                    : const Text('Not configured'),
                onTap: () => Navigator.pop(sheetContext, 'printer'),
              ),
              ListTile(
                leading: const Icon(Icons.straighten),
                title: const Text('Paper width'),
                subtitle: Text('$paper (saved per printer)'),
                onTap: () => Navigator.pop(sheetContext, 'paper'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (!context.mounted || action == null) {
      return;
    }
    switch (action) {
      case 'printer':
        await selectAndSavePrinter(context);
        break;
      case 'paper':
        await changePaperSizeForCurrentPrinter(context);
        break;
    }
  }

  static Future<bool> selectAndSavePrinter(BuildContext context) async {
    final device = await pickPrinter(context);
    if (device == null) return false;

    final previousAddress = FFAppState().bluetoothPrinterAddress;
    if (previousAddress.isNotEmpty && previousAddress != device.address) {
      await _disconnectSavedPrinter(previousAddress);
    }

    final appState = FFAppState();
    appState.bluetoothPrinterAddress = device.address;
    appState.bluetoothPrinterName = device.name ?? device.address;

    final ThermalPaperSize paperSize;
    final savedForDevice =
        appState.printerPaperWidthForAddress(device.address);
    if (savedForDevice != null) {
      paperSize = ThermalPaperSize.fromStorage(savedForDevice);
      appState.bluetoothPrinterPaperWidth = paperSize.storageValue;
    } else if (context.mounted) {
      final picked = await showThermalPaperSizePicker(
        context,
        initial: guessPaperSizeFromPrinterName(device.name),
        printerLabel: appState.bluetoothPrinterName,
      );
      paperSize = picked ?? guessPaperSizeFromPrinterName(device.name);
      await persistPrinterPaperSize(device.address, paperSize);
    } else {
      paperSize = guessPaperSizeFromPrinterName(device.name);
      await persistPrinterPaperSize(device.address, paperSize);
    }

    if (context.mounted) {
      showSnack(
        context,
        'Printer set: ${appState.bluetoothPrinterName} (${paperSize.label})',
      );
    }
    return true;
  }

  static Future<void> changePaperSizeForCurrentPrinter(
    BuildContext context,
  ) async {
    final appState = FFAppState();
    final address = appState.bluetoothPrinterAddress;
    if (address.isEmpty) {
      showSnack(context, 'Select a Bluetooth printer first.');
      return;
    }

    final picked = await showThermalPaperSizePicker(
      context,
      initial: savedThermalPaperSizeForAddress(address),
      printerLabel: appState.bluetoothPrinterName,
    );
    if (picked == null || !context.mounted) {
      return;
    }
    await persistPrinterPaperSize(address, picked);
    showSnack(context, 'Paper width set to ${picked.label}');
  }

  static Future<void> _disconnectSavedPrinter(String address) async {
    try {
      await FlutterBluetoothPrinter.disconnect(address);
    } catch (_) {
      // Best-effort cleanup before switching printers.
    }
    if (_connectedAddress == address) {
      _connectedAddress = null;
    }
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  /// Sends ESC/POS bytes with reconnect + retry for flaky Bluetooth stacks.
  static Future<bool> sendBytesToPrinter({
    required String address,
    required Uint8List data,
  }) async {
    if (address.isEmpty) {
      return false;
    }

    if (_connectedAddress != null && _connectedAddress != address) {
      await _disconnectSavedPrinter(_connectedAddress!);
    }

    Future<bool> attempt({required bool keepConnected}) {
      return FlutterBluetoothPrinter.printBytes(
        address: address,
        data: data,
        keepConnected: keepConnected,
        maxBufferSize: 512,
        delayTime: 120,
      );
    }

    var ok = await attempt(keepConnected: true);
    if (ok) {
      _connectedAddress = address;
      return true;
    }

    await _disconnectSavedPrinter(address);

    ok = await attempt(keepConnected: true);
    if (ok) {
      _connectedAddress = address;
    }
    return ok;
  }

  static Future<bool> _ensurePrinter(BuildContext context) async {
    final address = FFAppState().bluetoothPrinterAddress;
    if (address.isNotEmpty) return true;
    return selectAndSavePrinter(context);
  }

  static Future<CompaniesRecord?> resolveReceiptCompany(
    OrdersRecord order,
  ) async {
    final companyRef = order.companyRef;
    if (companyRef != null) {
      try {
        return await CompaniesRecord.getDocumentOnce(companyRef);
      } catch (_) {
        // Fall back to default company below.
      }
    }
    return getDefaultCompanyOnce();
  }

  /// Builds ESC/POS bytes (GBK Chinese + structured layout).
  static Future<List<int>> buildReceiptBytes({
    required OrdersRecord order,
    required List<OrderItemRecord> items,
    CompaniesRecord? company,
    String? cashierName,
  }) =>
      buildEscPosReceiptBytes(
        order: order,
        items: items,
        company: company,
        cashierName: cashierName,
      );

  static Future<List<int>> buildDeliverySlipBytes({
    required OrdersRecord order,
    required List<OrderItemRecord> items,
    CompaniesRecord? company,
    String? cashierName,
    String? deliveryIdOverride,
  }) =>
      buildEscPosDeliverySlipBytes(
        order: order,
        items: items,
        company: company,
        cashierName: cashierName,
        deliveryIdOverride: deliveryIdOverride,
      );

  static Future<bool> printOrderReceipt(
    BuildContext context, {
    required OrdersRecord order,
    required List<OrderItemRecord> items,
    CompaniesRecord? company,
    String? cashierName,
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

    if (_printing) {
      showSnack(context, 'Print in progress…');
      return false;
    }

    final address = FFAppState().bluetoothPrinterAddress;
    _printing = true;
    try {
      final cashierLabel = formatReceiptCashierLabel(
        await resolveOrderCashierName(order.reference),
      );
      final data = Uint8List.fromList(
        await buildReceiptBytes(
          order: order,
          items: items,
          company: company,
          cashierName: cashierLabel,
        ),
      );
      final ok = await sendBytesToPrinter(address: address, data: data);

      if (context.mounted) {
        showSnack(
          context,
          ok
              ? 'Receipt sent to printer.'
              : 'Print failed. Re-select the Bluetooth printer and try again.',
        );
      }
      if (ok) {
        await auditLogPrintReceipt(order: order, format: 'Bluetooth receipt');
      }
      return ok;
    } catch (e) {
      await _disconnectSavedPrinter(address);
      if (context.mounted) {
        showSnack(context, 'Print error: $e');
      }
      return false;
    } finally {
      _printing = false;
    }
  }

  static Future<bool> printDeliverySlipByRef(
    BuildContext context,
    DocumentReference orderRef,
  ) async {
    final order = await OrdersRecord.getDocumentOnce(orderRef);
    final items = activeOrderItems(
      await queryOrderItemRecordOnce(
        queryBuilder: (q) => q.where('orderRef', isEqualTo: orderRef),
      ),
    );
    return printDeliverySlip(
      context,
      order: order,
      items: items,
    );
  }

  static Future<bool> printDeliverySlip(
    BuildContext context, {
    required OrdersRecord order,
    required List<OrderItemRecord> items,
    String? deliveryIdOverride,
  }) async {
    final company = await resolveReceiptCompany(order);

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
      showSnack(context, 'Select at least one item to print.');
      return false;
    }

    if (_printing) {
      showSnack(context, 'Print in progress…');
      return false;
    }

    final address = FFAppState().bluetoothPrinterAddress;
    _printing = true;
    try {
      final cashierLabel = formatReceiptCashierLabel(
        await resolveOrderCashierName(order.reference),
      );
      final data = Uint8List.fromList(
        await buildDeliverySlipBytes(
          order: order,
          items: items,
          company: company,
          cashierName: cashierLabel,
          deliveryIdOverride: deliveryIdOverride,
        ),
      );
      final ok = await sendBytesToPrinter(address: address, data: data);

      if (context.mounted) {
        showSnack(
          context,
          ok
              ? 'Delivery slip sent to printer.'
              : 'Print failed. Re-select the Bluetooth printer and try again.',
        );
      }
      if (ok) {
        await auditLogPrintReceipt(
          order: order,
          format: 'Bluetooth delivery slip',
        );
      }
      return ok;
    } catch (e) {
      await _disconnectSavedPrinter(address);
      if (context.mounted) {
        showSnack(context, 'Print error: $e');
      }
      return false;
    } finally {
      _printing = false;
    }
  }

  static Future<bool> printOrderByRef(
    BuildContext context,
    DocumentReference orderRef, {
    String? cashierName,
  }) async {
    final order = await OrdersRecord.getDocumentOnce(orderRef);
    final items = activeOrderItems(
      await queryOrderItemRecordOnce(
        queryBuilder: (q) => q.where('orderRef', isEqualTo: orderRef),
      ),
    );

    final company = await resolveReceiptCompany(order);

    return printOrderReceipt(
      context,
      order: order,
      items: items,
      company: company,
      cashierName: cashierName,
    );
  }
}
