import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'thermal_printer_device.dart';

abstract class ThermalPrinterTransport {
  bool get isAvailable;

  Future<ThermalPrinterDevice?> pickPrinter(BuildContext context);

  Future<void> disconnect(String address);

  Future<bool> sendBytes({
    required String address,
    required Uint8List data,
    int maxBufferSize = 512,
    int delayMs = 120,
  });
}
