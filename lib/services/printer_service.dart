//printer_service.dart

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:usb_serial/usb_serial.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';

class PrinterDevice {
  final String name;
  final String address;
  final String type;

  PrinterDevice({
    required this.name,
    required this.address,
    required this.type,
  });
}

class PrinterService {
  /// 🔵 BLUETOOTH
  Future<List<PrinterDevice>> scanBluetoothPrinters() async {
    await Permission.bluetoothScan.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();

    List<PrinterDevice> devices = [];

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        if (r.device.name.isNotEmpty) {
          devices.add(
            PrinterDevice(
              name: r.device.name,
              address: r.device.remoteId.toString(),
              type: "Bluetooth",
            ),
          );
        }
      }
    });

    await Future.delayed(const Duration(seconds: 5));
    await FlutterBluePlus.stopScan();

    return devices;
  }

  /// 🟢 USB
  Future<List<PrinterDevice>> scanUsbPrinters() async {
    List<PrinterDevice> devices = [];

    List<UsbDevice> usbDevices = await UsbSerial.listDevices();

    for (var device in usbDevices) {
      devices.add(
        PrinterDevice(
          name: device.productName ?? "USB Printer",
          address: device.deviceId.toString(),
          type: "USB",
        ),
      );
    }

    return devices;
  }

  /// 🟡 WIFI (solo red local actual)
  Future<List<PrinterDevice>> scanWifiPrinter() async {
    final info = NetworkInfo();
    String? ip = await info.getWifiIP();

    if (ip == null) return [];

    return [PrinterDevice(name: "Printer WiFi", address: ip, type: "WiFi")];
  }
}
