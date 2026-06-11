import 'package:flutter/material.dart';

import '/app_state.dart';

/// Thermal roll width — drives logo dots and receipt line width.
enum ThermalPaperSize {
  mm58,
  mm80;

  int get dotsPerLine => switch (this) {
        ThermalPaperSize.mm58 => 384,
        ThermalPaperSize.mm80 => 576,
      };

  int get lineWidthChars => switch (this) {
        ThermalPaperSize.mm58 => 32,
        ThermalPaperSize.mm80 => 48,
      };

  String get label => switch (this) {
        ThermalPaperSize.mm58 => '58mm',
        ThermalPaperSize.mm80 => '80mm',
      };

  String get storageValue => this == ThermalPaperSize.mm80 ? '80' : '58';

  static ThermalPaperSize fromStorage(String? value) {
    if (value == '80' || value == 'mm80') {
      return ThermalPaperSize.mm80;
    }
    return ThermalPaperSize.mm58;
  }
}

/// Guess paper width from printer model name (first-time pairing hint).
ThermalPaperSize guessPaperSizeFromPrinterName(String? name) {
  final normalized = (name ?? '').toLowerCase();
  if (normalized.contains('80') ||
      normalized.contains('3inch') ||
      normalized.contains('3-inch') ||
      normalized.contains('3 inch')) {
    return ThermalPaperSize.mm80;
  }
  return ThermalPaperSize.mm58;
}

ThermalPaperSize savedThermalPaperSizeForAddress(String address) {
  final appState = FFAppState();
  if (address.isNotEmpty) {
    final mapped = appState.printerPaperWidthForAddress(address);
    if (mapped != null) {
      return ThermalPaperSize.fromStorage(mapped);
    }
  }
  return ThermalPaperSize.fromStorage(appState.bluetoothPrinterPaperWidth);
}

ThermalPaperSize activeThermalPaperSize() =>
    savedThermalPaperSizeForAddress(FFAppState().bluetoothPrinterAddress);

int thermalPaperDotsPerLine() => activeThermalPaperSize().dotsPerLine;

int thermalPaperLineWidth() => activeThermalPaperSize().lineWidthChars;

Future<void> persistPrinterPaperSize(
  String address,
  ThermalPaperSize size,
) async {
  final appState = FFAppState();
  appState.setPrinterPaperWidthForAddress(address, size.storageValue);
  appState.bluetoothPrinterPaperWidth = size.storageValue;
}

Future<ThermalPaperSize?> showThermalPaperSizePicker(
  BuildContext context, {
  ThermalPaperSize? initial,
  String? printerLabel,
}) {
  final selected = initial ?? ThermalPaperSize.mm58;
  return showModalBottomSheet<ThermalPaperSize>(
    context: context,
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              printerLabel == null || printerLabel.isEmpty
                  ? 'Receipt paper width'
                  : 'Paper width for $printerLabel',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final size in ThermalPaperSize.values)
            ListTile(
              leading: Icon(
                size == selected ? Icons.radio_button_checked : Icons.circle,
              ),
              title: Text(size.label),
              subtitle: Text(
                '${size.dotsPerLine} dots · ${size.lineWidthChars} chars/line',
              ),
              onTap: () => Navigator.pop(sheetContext, size),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
