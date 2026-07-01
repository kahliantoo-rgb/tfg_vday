import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '/app_state.dart';
import '/backend/audit_log_helpers.dart';
import '/backend/backend.dart';
import '/backend/company_query_helpers.dart';
import '/backend/order_item_helpers.dart';
import '/backend/order_production_menu_helpers.dart';
import '/backend/schema/companies_record.dart';
import '/backend/schema/order_item_record.dart';
import '/backend/schema/orders_record.dart';
import '/custom_code/esc_pos_production_menu_builder.dart';
import '/custom_code/esc_pos_receipt_builder.dart';
import '/custom_code/thermal_paper_helpers.dart';
import '/custom_code/thermal_printer_device.dart';
import '/custom_code/thermal_printer_transport.dart';

/// Bluetooth thermal receipt printing (ESC/POS). Mobile + Web (BLE).
class BluetoothReceiptPrinter {
  static final ThermalPrinterTransport _transport =
      createThermalPrinterTransport();

  static String? _connectedAddress;
  static bool _printing = false;

  static bool get isBluetoothPrintAvailable => _transport.isAvailable;

  static String unsupportedPlatformMessage() {
    if (kIsWeb) {
      return 'Web Bluetooth needs Chrome or Edge on HTTPS, and a BLE thermal printer.';
    }
    return 'Bluetooth printing is not available on this device.';
  }

  static void showSnack(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static Future<ThermalPrinterDevice?> pickPrinter(BuildContext context) async {
    if (!_transport.isAvailable) {
      showSnack(context, unsupportedPlatformMessage());
      return null;
    }

    return _transport.pickPrinter(context);
  }

  static Future<void> openPrinterSettings(BuildContext context) async {
    if (!_transport.isAvailable) {
      showSnack(context, unsupportedPlatformMessage());
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
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  kIsWeb ? 'Web Bluetooth printer' : 'Bluetooth printer',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (kIsWeb)
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    'Use Chrome or Edge. Printer must support Bluetooth Low Energy (BLE).',
                    style: TextStyle(fontSize: 13),
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
    await _transport.disconnect(address);
    if (_connectedAddress == address) {
      _connectedAddress = null;
    }
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

    final ok = await _transport.sendBytes(
      address: address,
      data: data,
      maxBufferSize: 512,
      delayMs: 120,
    );
    if (ok) {
      _connectedAddress = address;
    }
    return ok;
  }

  static Future<void> _reportPrintFailure(
    BuildContext context,
    String address,
  ) async {
    if (address.isNotEmpty) {
      await _disconnectSavedPrinter(address);
    }
    if (!context.mounted) {
      return;
    }

    final appState = FFAppState();
    final savedName = appState.bluetoothPrinterName.trim();
    final savedHint = savedName.isNotEmpty
        ? 'Saved printer: $savedName'
        : 'No printer saved yet.';

    final changePrinter = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Print failed'),
        content: Text(
          kIsWeb
              ? '$savedHint\n\nCould not reach this printer in the browser. '
                  'Tap Change printer to pair the correct BLE thermal printer.'
              : '$savedHint\n\nCould not connect to this Bluetooth printer. '
                  'Tap Change printer to pick the correct device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Change printer'),
          ),
        ],
      ),
    );

    if (changePrinter == true && context.mounted) {
      await selectAndSavePrinter(context);
    }
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
    if (!_transport.isAvailable) {
      showSnack(context, unsupportedPlatformMessage());
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
      final resolvedCashier = await resolveOrderCashierName(
        order.reference,
        fallback: resolvedCurrentCashierLabel(),
      );
      final data = Uint8List.fromList(
        await buildReceiptBytes(
          order: order,
          items: items,
          company: company,
          cashierName: cashierName ?? resolvedCashier,
        ),
      );
      final ok = await sendBytesToPrinter(address: address, data: data);

      if (context.mounted) {
        if (ok) {
          showSnack(context, 'Receipt sent to printer.');
        } else {
          await _reportPrintFailure(context, address);
        }
      }
      if (ok) {
        await auditLogPrintReceipt(order: order, format: 'Bluetooth receipt');
      }
      return ok;
    } catch (e) {
      await _disconnectSavedPrinter(address);
      if (context.mounted) {
        showSnack(context, 'Print error: $e');
        await _reportPrintFailure(context, address);
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
      await queryOrderItemsForOrderOnce(orderRef),
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

    if (!_transport.isAvailable) {
      showSnack(context, unsupportedPlatformMessage());
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
      final cashierName = await resolveOrderCashierName(
        order.reference,
        fallback: resolvedCurrentCashierLabel(),
      );
      final data = Uint8List.fromList(
        await buildDeliverySlipBytes(
          order: order,
          items: items,
          company: company,
          cashierName: cashierName,
          deliveryIdOverride: deliveryIdOverride,
        ),
      );
      final ok = await sendBytesToPrinter(address: address, data: data);

      if (context.mounted) {
        if (ok) {
          showSnack(context, 'Delivery slip sent to printer.');
        } else {
          await _reportPrintFailure(context, address);
        }
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
        await _reportPrintFailure(context, address);
      }
      return false;
    } finally {
      _printing = false;
    }
  }

  static Future<List<int>> buildProductionMenuBytes({
    required OrderProductionMenu menu,
    CompaniesRecord? company,
  }) =>
      buildEscPosProductionMenuBytes(
        menu: menu,
        company: company,
      );

  static Future<bool> printProductionMenu(
    BuildContext context, {
    required OrderProductionMenu menu,
  }) async {
    final company = await resolveReceiptCompany(menu.order);

    if (!_transport.isAvailable) {
      showSnack(context, unsupportedPlatformMessage());
      return false;
    }

    if (!await _ensurePrinter(context)) {
      return false;
    }

    if (_printing) {
      showSnack(context, 'Print in progress…');
      return false;
    }

    final address = FFAppState().bluetoothPrinterAddress;
    _printing = true;
    try {
      final data = Uint8List.fromList(
        await buildProductionMenuBytes(
          menu: menu,
          company: company,
        ),
      );
      final ok = await sendBytesToPrinter(address: address, data: data);

      if (context.mounted) {
        if (ok) {
          showSnack(context, 'Production menu sent to printer.');
        } else {
          await _reportPrintFailure(context, address);
        }
      }
      if (ok) {
        await auditLogPrintReceipt(
          order: menu.order,
          format: 'Bluetooth production menu',
        );
      }
      return ok;
    } catch (e) {
      await _disconnectSavedPrinter(address);
      if (context.mounted) {
        showSnack(context, 'Print error: $e');
        await _reportPrintFailure(context, address);
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
      await queryOrderItemsForOrderOnce(orderRef),
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
