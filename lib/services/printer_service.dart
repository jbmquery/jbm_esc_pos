//printer_service.dart
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
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
    await Permission.bluetooth.request();
    await Permission.bluetoothConnect.request();
    await Permission.location.request();

    List<PrinterDevice> devices = [];

    final bluetooth = FlutterBluetoothSerial.instance;

    bool? enabled = await bluetooth.isEnabled;

    if (enabled == false) {
      await bluetooth.requestEnable();
    }

    // 🔥 OBTENER DISPOSITIVOS EMPAREJADOS
    List<BluetoothDevice> bondedDevices = await bluetooth.getBondedDevices();

    for (var device in bondedDevices) {
      devices.add(
        PrinterDevice(
          name: device.name ?? "Bluetooth Printer",
          address: device.address,
          type: "Bluetooth",
        ),
      );
    }

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
    try {
      BluetoothConnection connection = await BluetoothConnection.toAddress(
        address,
      ).timeout(const Duration(seconds: 8));

      connection.output.add(Uint8List.fromList(bytes));
      await connection.output.allSent;

      await connection.close();
    } catch (e) {
      print("ERROR BLUETOOTH: $e");
    }
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
