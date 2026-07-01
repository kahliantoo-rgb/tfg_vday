import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_printer/flutter_bluetooth_printer_library.dart';
import 'package:flutter_bluetooth_printer_platform_interface/flutter_bluetooth_printer_platform_interface.dart';

import 'thermal_printer_device.dart';
import 'thermal_printer_transport_base.dart';

class _MobileThermalPrinterTransport extends ThermalPrinterTransport {
  String? _connectedAddress;

  @override
  bool get isAvailable => true;

  @override
  Future<ThermalPrinterDevice?> pickPrinter(BuildContext context) async {
    final device = await showModalBottomSheet<BluetoothDevice>(
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
    if (device == null) {
      return null;
    }
    return ThermalPrinterDevice(
      address: device.address,
      name: device.name ?? device.address,
    );
  }

  @override
  Future<void> disconnect(String address) async {
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

  @override
  Future<bool> sendBytes({
    required String address,
    required Uint8List data,
    int maxBufferSize = 512,
    int delayMs = 120,
  }) async {
    if (address.isEmpty) {
      return false;
    }

    if (_connectedAddress != null && _connectedAddress != address) {
      await disconnect(_connectedAddress!);
    }

    Future<bool> attempt({required bool keepConnected}) {
      return FlutterBluetoothPrinter.printBytes(
        address: address,
        data: data,
        keepConnected: keepConnected,
        maxBufferSize: maxBufferSize,
        delayTime: delayMs,
      );
    }

    var ok = await attempt(keepConnected: true);
    if (ok) {
      _connectedAddress = address;
      return true;
    }

    await disconnect(address);

    ok = await attempt(keepConnected: true);
    if (ok) {
      _connectedAddress = address;
    }
    return ok;
  }
}

ThermalPrinterTransport createThermalPrinterTransport() =>
    _MobileThermalPrinterTransport();
