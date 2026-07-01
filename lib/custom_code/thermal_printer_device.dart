/// Saved printer identity (MAC on mobile, Web Bluetooth device id on web).
class ThermalPrinterDevice {
  const ThermalPrinterDevice({
    required this.address,
    this.name,
  });

  final String address;
  final String? name;
}
