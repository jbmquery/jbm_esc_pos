// voucher_model.dart
import 'dart:convert';
import 'dart:io';
import '../services/printer_service.dart';
import '../services/firebase_service.dart';
import 'package:encrypt/encrypt.dart';
import 'dart:typed_data';

class VoucherProcessor {
  static Future<void> processFile(File file) async {
    final raw = await file.readAsBytes();
    final decrypted = _decryptFile(raw);

    if (file.path.endsWith(".json")) {
      final jsonData = jsonDecode(utf8.decode(decrypted));
      await _processJson(jsonData);
    } else if (file.path.endsWith(".bin")) {
      await _processBinary(decrypted);
    }
  }

  static Future<void> _processJson(Map<String, dynamic> data) async {
    List<int> escposBytes = [];

    for (var element in data["content"]) {
      if (element["type"] == "text") {
        escposBytes.addAll(_textToEscPos(element));
      }

      if (element["type"] == "divider") {
        escposBytes.addAll(utf8.encode("------------------------------\n"));
      }

      if (element["type"] == "table_row") {
        String left = element["left"] ?? "";
        String right = element["right"] ?? "";
        int width = 32; // 58mm default

        escposBytes.addAll(utf8.encode(_formatLine(left, right, width)));
      }

      if (element["type"] == "image") {
        final imageBytes = base64Decode(element["base64"]);
        escposBytes.addAll(imageBytes);
      }

      if (element["type"] == "qr") {
        String dataQr = element["value"];

        escposBytes.addAll([
          0x1D,
          0x28,
          0x6B,
          0x04,
          0x00,
          0x31,
          0x41,
          0x32,
          0x00,
        ]);

        escposBytes.addAll([
          0x1D,
          0x28,
          0x6B,
          (dataQr.length + 3) & 0xFF,
          ((dataQr.length + 3) >> 8) & 0xFF,
          0x31,
          0x50,
          0x30,
        ]);

        escposBytes.addAll(utf8.encode(dataQr));

        escposBytes.addAll([0x1D, 0x28, 0x6B, 0x03, 0x00, 0x31, 0x51, 0x30]);
      }
    }

    escposBytes.addAll([0x1D, 0x56, 0x41, 0x10]); // cortar papel

    await _sendToPrinter(escposBytes);
  }

  static List<int> _textToEscPos(Map<String, dynamic> element) {
    List<int> bytes = [];

    if (element["align"] == "center") {
      bytes.addAll([0x1B, 0x61, 0x01]);
    }

    if (element["bold"] == true) {
      bytes.addAll([0x1B, 0x45, 0x01]);
    }

    if (element["size"] == "double") {
      bytes.addAll([0x1D, 0x21, 0x11]);
    }

    bytes.addAll(utf8.encode("${element["value"]}\n"));

    bytes.addAll([0x1B, 0x45, 0x00]);
    bytes.addAll([0x1D, 0x21, 0x00]);

    return bytes;
  }

  static String _formatLine(String left, String right, int width) {
    int spaces = width - left.length - right.length;
    if (spaces < 0) spaces = 1;
    return left + (" " * spaces) + right + "\n";
  }

  static Future<void> _processBinary(List<int> bytes) async {
    await _sendToPrinter(bytes);
  }

  static List<int> _decryptFile(List<int> encryptedBytes) {
    final key = Key.fromUtf8('12345678901234567890123456789012');
    final iv = IV.fromLength(16);

    final encrypter = Encrypter(AES(key));

    final encrypted = Encrypted(Uint8List.fromList(encryptedBytes));

    final decrypted = encrypter.decryptBytes(encrypted, iv: iv);

    return decrypted;
  }

  static Future<void> _sendToPrinter(List<int> bytes) async {
    final firebase = FirebaseService();
    final config = await firebase.checkAndInitializeDevice();

    if (config == null) return;

    if (config["is_blocked"] == true) return;

    if (config["estado"] != "premium" && config["estado"] != "free") {
      return;
    }

    if (config["printer_mac"] == null || config["printer_type"] == null) {
      return;
    }

    try {
      await PrinterService().sendBytes(
        bytes: bytes,
        type: config["printer_type"],
        address: config["printer_mac"],
      );
    } catch (_) {}
  }
}
