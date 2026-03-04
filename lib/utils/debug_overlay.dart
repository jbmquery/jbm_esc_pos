//file: lib/utils/debug_overlay.dart
import 'package:flutter/material.dart';

class DebugOverlay {
  static final DebugOverlay _instance = DebugOverlay._internal();
  factory DebugOverlay() => _instance;
  DebugOverlay._internal();

  OverlayEntry? _entry;

  void show(BuildContext context, String message) {
    _entry?.remove();

    _entry = OverlayEntry(
      builder: (_) => Positioned(
        top: 40,
        left: 10,
        right: 10,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.85),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_entry!);

    Future.delayed(const Duration(seconds: 5), () {
      _entry?.remove();
      _entry = null;
    });
  }
}
