import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'thermal_printer_device.dart';
import 'thermal_printer_transport_base.dart';

class _StubThermalPrinterTransport extends ThermalPrinterTransport {
  @override
  bool get isAvailable => false;

  @override
  Future<ThermalPrinterDevice?> pickPrinter(BuildContext context) async =>
      null;

  @override
  Future<void> disconnect(String address) async {}

  @override
  Future<bool> sendBytes({
    required String address,
    required Uint8List data,
    int maxBufferSize = 512,
    int delayMs = 120,
  }) async =>
      false;
}

ThermalPrinterTransport createThermalPrinterTransport() =>
    _StubThermalPrinterTransport();
