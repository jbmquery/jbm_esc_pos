// firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; // Android ID
    }

    return "unknown_device";
  }

  Future<Map<String, dynamic>> getDeviceData() async {
    final deviceInfo = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();

    String deviceName = "Unknown";

    if (Platform.isAndroid) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      deviceName = "${androidInfo.brand} ${androidInfo.model}";
    }

    return {"device_name": deviceName, "version_app": packageInfo.version};
  }

  Future<void> registerDevice({
    required String printerName,
    required String printerMac,
    required String printerType,
    required String paperSize,
    required int copies,
  }) async {
    String deviceId = await getDeviceId();
    Map<String, dynamic> deviceData = await getDeviceData();

    final docRef = _firestore.collection("devices").doc(deviceId);
    final doc = await docRef.get();

    if (!doc.exists) {
      DateTime now = DateTime.now();
      DateTime expiration = now.add(const Duration(days: 15));

      await docRef.set({
        "device_id": deviceId,
        "device_name": deviceData["device_name"],
        "estado": "free",
        "fecha_registro": now,
        "fecha_expiracion": expiration,
        "dias_gratis": 15,
        "premium_desde": null,
        "premium_hasta": null,
        "is_blocked": false,
        "ultimo_acceso": now,
        "version_app": deviceData["version_app"],

        // Datos impresora
        "printer_name": printerName,
        "printer_mac": printerMac,
        "printer_type": printerType,
        "paper_size": paperSize,
        "copies": copies,
      });
    } else {
      await docRef.update({
        "ultimo_acceso": DateTime.now(),
        "printer_name": printerName,
        "printer_mac": printerMac,
        "printer_type": printerType,
        "paper_size": paperSize,
        "copies": copies,
      });
    }
  }

  Future<Map<String, dynamic>?> checkAndInitializeDevice() async {
    String deviceId = await getDeviceId();
    Map<String, dynamic> deviceData = await getDeviceData();

    final docRef = _firestore.collection("devices").doc(deviceId);
    final doc = await docRef.get();

    DateTime now = DateTime.now();

    // 🆕 PRIMER USO
    if (!doc.exists) {
      DateTime expiration = now.add(const Duration(days: 15));

      await docRef.set({
        "device_id": deviceId,
        "device_name": deviceData["device_name"],
        "estado": "free",
        "fecha_registro": now,
        "fecha_expiracion": expiration,
        "dias_gratis": 15,
        "premium_desde": null,
        "premium_hasta": null,
        "is_blocked": false,
        "ultimo_acceso": now,
        "version_app": deviceData["version_app"],

        // 🔧 IMPORTANTE: agregar también estos
        "printer_name": null,
        "printer_mac": null,
        "printer_type": null,
        "paper_size": null,
        "copies": null,
      });

      return {
        "estado": "free",
        "is_blocked": false,
        "printer_name": null,
        "printer_mac": null,
        "printer_type": null,
        "paper_size": null,
        "copies": null,
        "fecha_expiracion": expiration,
      };
    }

    // 🔁 YA EXISTE
    final data = doc.data() as Map<String, dynamic>;

    await docRef.update({"ultimo_acceso": now});

    bool isBlocked = data["is_blocked"] ?? false;
    String estado = data["estado"] ?? "free";

    // ⏳ Validar expiración si es free
    if (estado == "free") {
      Timestamp? expTimestamp = data["fecha_expiracion"];
      if (expTimestamp != null) {
        DateTime expiration = expTimestamp.toDate();
        if (now.isAfter(expiration)) {
          estado = "expired";
        }
      }
    }

    return {
      "estado": estado,
      "is_blocked": isBlocked,
      "printer_name": data["printer_name"],
      "printer_mac": data["printer_mac"],
      "printer_type": data["printer_type"],
      "paper_size": data["paper_size"],
      "copies": data["copies"],
      "fecha_expiracion": data["fecha_expiracion"],
    };
  }
}
