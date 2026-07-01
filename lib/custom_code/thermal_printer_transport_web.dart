import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'thermal_printer_device.dart';
import 'thermal_printer_transport_base.dart';

Object? _webBluetoothApi() {
  try {
    return js_util.getProperty(html.window, 'tfgWebBluetooth');
  } catch (_) {
    return null;
  }
}

class _WebThermalPrinterTransport extends ThermalPrinterTransport {
  @override
  bool get isAvailable {
    final api = _webBluetoothApi();
    if (api == null) {
      return false;
    }
    try {
      return js_util.callMethod<bool>(api, 'isSupported', []);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<ThermalPrinterDevice?> pickPrinter(BuildContext context) async {
    final api = _webBluetoothApi();
    if (api == null || !isAvailable) {
      return null;
    }
    try {
      final result = await js_util.promiseToFuture<Object>(
        js_util.callMethod(api, 'requestPrinter', []),
      );
      final id = js_util.getProperty<String>(result, 'id');
      final name = js_util.getProperty<String?>(result, 'name');
      return ThermalPrinterDevice(address: id, name: name ?? id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> disconnect(String address) async {
    final api = _webBluetoothApi();
    if (api == null || address.isEmpty) {
      return;
    }
    try {
      await js_util.promiseToFuture<Object>(
        js_util.callMethod(api, 'disconnect', [address]),
      );
    } catch (_) {
      // Best-effort cleanup.
    }
  }

  @override
  Future<bool> sendBytes({
    required String address,
    required Uint8List data,
    int maxBufferSize = 512,
    int delayMs = 120,
  }) async {
    final api = _webBluetoothApi();
    if (api == null || address.isEmpty) {
      return false;
    }
    try {
      await js_util.promiseToFuture<Object>(
        js_util.callMethod(api, 'printBytes', [
          address,
          data.toList(),
          maxBufferSize,
          delayMs,
        ]),
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}

ThermalPrinterTransport createThermalPrinterTransport() =>
    _WebThermalPrinterTransport();
