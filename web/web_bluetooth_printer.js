(function () {
  'use strict';

  var KNOWN_SERVICES = [
    '0000ff00-0000-1000-8000-00805f9b34fb',
    '49535343-fe7d-4ae5-8fa9-9fefd205e455',
    '6e400001-b5a3-f393-e0a9-e50e24dccb9e',
    '000018f0-0000-1000-8000-00805f9b34fb',
    'e7810a71-73ae-499d-8c15-faa9aef0c3f2',
  ];

  var WRITE_CHARS = [
    '0000ff02-0000-1000-8000-00805f9b34fb',
    '49535343-8841-43e4-a96d-4c46717370',
    '6e400002-b5a3-f393-e0a9-e50e24dccb9e',
    '000018f1-0000-1000-8000-00805f9b34fb',
    '000018f2-0000-1000-8000-00805f9b34fb',
    '0000ff01-0000-1000-8000-00805f9b34fb',
  ];

  var cachedDevice = null;

  function sleep(ms) {
    return new Promise(function (resolve) {
      setTimeout(resolve, ms);
    });
  }

  async function findWriteCharacteristic(server) {
    for (var s = 0; s < KNOWN_SERVICES.length; s++) {
      var serviceUuid = KNOWN_SERVICES[s];
      try {
        var service = await server.getPrimaryService(serviceUuid);
        for (var c = 0; c < WRITE_CHARS.length; c++) {
          var charUuid = WRITE_CHARS[c];
          try {
            var characteristic = await service.getCharacteristic(charUuid);
            if (
              characteristic.properties.write ||
              characteristic.properties.writeWithoutResponse
            ) {
              return characteristic;
            }
          } catch (ignored) {}
        }
        var characteristics = await service.getCharacteristics();
        for (var i = 0; i < characteristics.length; i++) {
          var ch = characteristics[i];
          if (ch.properties.write || ch.properties.writeWithoutResponse) {
            return ch;
          }
        }
      } catch (ignored) {}
    }
    throw new Error(
      'No writable Bluetooth characteristic found. Use a BLE ESC/POS printer.',
    );
  }

  async function writeBytes(characteristic, bytes, chunkSize, delayMs) {
    var useWithoutResponse =
      characteristic.properties.writeWithoutResponse &&
      !characteristic.properties.write;
    for (var offset = 0; offset < bytes.length; offset += chunkSize) {
      var end = Math.min(offset + chunkSize, bytes.length);
      var chunk = bytes.subarray(offset, end);
      if (useWithoutResponse) {
        await characteristic.writeValueWithoutResponse(chunk);
      } else {
        await characteristic.writeValue(chunk);
      }
      if (delayMs > 0) {
        await sleep(delayMs);
      }
    }
  }

  async function resolveDevice(deviceId) {
    if (cachedDevice && cachedDevice.id === deviceId) {
      return cachedDevice;
    }
    if (navigator.bluetooth && navigator.bluetooth.getDevices) {
      var devices = await navigator.bluetooth.getDevices();
      for (var i = 0; i < devices.length; i++) {
        if (devices[i].id === deviceId) {
          cachedDevice = devices[i];
          return cachedDevice;
        }
      }
    }
    return null;
  }

  window.tfgWebBluetooth = {
    isSupported: function () {
      return !!(navigator.bluetooth && navigator.bluetooth.requestDevice);
    },

    requestPrinter: async function () {
      if (!window.tfgWebBluetooth.isSupported()) {
        throw new Error(
          'Web Bluetooth is not supported. Use Chrome or Edge on HTTPS.',
        );
      }
      var device = await navigator.bluetooth.requestDevice({
        acceptAllDevices: true,
        optionalServices: KNOWN_SERVICES,
      });
      cachedDevice = device;
      return {
        id: device.id,
        name: device.name || device.id,
      };
    },

    disconnect: async function (deviceId) {
      var device = await resolveDevice(deviceId);
      if (device && device.gatt && device.gatt.connected) {
        device.gatt.disconnect();
      }
      if (cachedDevice && cachedDevice.id === deviceId) {
        cachedDevice = null;
      }
    },

    printBytes: async function (deviceId, byteList, chunkSize, delayMs) {
      var device = await resolveDevice(deviceId);
      if (!device) {
        throw new Error(
          'Printer not paired in this browser. Select the printer again.',
        );
      }
      if (!device.gatt.connected) {
        await device.gatt.connect();
      }
      var characteristic = await findWriteCharacteristic(device.gatt);
      var bytes = byteList instanceof Uint8Array ? byteList : new Uint8Array(byteList);
      await writeBytes(
        characteristic,
        bytes,
        chunkSize || 512,
        typeof delayMs === 'number' ? delayMs : 30,
      );
      return true;
    },
  };
})();
