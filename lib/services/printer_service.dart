//printer_service.dart
import 'dart:io';
import 'dart:typed_data';
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

  // =========================
  // ENVÍO REAL A IMPRESORA
  // =========================
  Future<void> sendBytes({
    required List<int> bytes,
    required String type,
    required String address,
  }) async {
    if (type == "Bluetooth") {
      await _sendBluetooth(bytes, address);
    }

    if (type == "USB") {
      await _sendUsb(bytes, address);
    }

    if (type == "WiFi") {
      await _sendWifi(bytes, address);
    }
  }

  Future<void> _sendBluetooth(List<int> bytes, String address) async {
    final device = BluetoothDevice.fromId(address);

    try {
      await device.connect(autoConnect: false);
    } catch (_) {
      await device.disconnect();
      await Future.delayed(const Duration(seconds: 1));
      await device.connect(autoConnect: false);
    }

    final services = await device.discoverServices();

    for (var service in services) {
      for (var characteristic in service.characteristics) {
        if (characteristic.properties.write) {
          await characteristic.write(bytes, withoutResponse: true);
        }
      }
    }

    await device.disconnect();
  }

  Future<void> _sendUsb(List<int> bytes, String address) async {
    List<UsbDevice> devices = await UsbSerial.listDevices();

    for (var device in devices) {
      if (device.deviceId.toString() == address) {
        UsbPort? port = await device.create();
        await port?.open();
        await port?.write(Uint8List.fromList(bytes));
        await port?.close();
      }
    }
  }

  Future<void> _sendWifi(List<int> bytes, String ip) async {
    final socket = await Socket.connect(ip, 9100);
    socket.add(bytes);
    await socket.flush();
    await socket.close();
  }
}
