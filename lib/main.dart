// main.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'models/voucher_model.dart';
import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'utils/debug_overlay.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  /// 🧠 CASO 1: app cerrada
  List<SharedMediaFile> sharedFiles = await ReceiveSharingIntent.instance
      .getInitialMedia();

  if (sharedFiles.isNotEmpty) {
    final file = File(sharedFiles.first.path);

    await VoucherProcessor.processFile(file);
    await Future.delayed(const Duration(seconds: 2));
    exit(0);
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _intentSub;

  static const platform = MethodChannel('jbm.intent.channel');

  @override
  void initState() {
    super.initState();

    /// 🔥 RECIBIR ARCHIVO DESDE ANDROID (content://)
    platform.setMethodCallHandler((call) async {
      final context = navigatorKey.currentContext;

      if (call.method == "file_received") {
        DebugOverlay().show(context!, "📥 Intent recibido");

        final uri = call.arguments;

        DebugOverlay().show(context!, "📄 URI: $uri");

        final bytes = await platform.invokeMethod('read_file', uri);

        DebugOverlay().show(context!, "✅ Archivo leído");

        final tempFile = File('${Directory.systemTemp.path}/ticket.jbm');

        await tempFile.writeAsBytes(Uint8List.fromList(bytes));

        DebugOverlay().show(context!, "💾 Archivo temporal creado");

        await VoucherProcessor.processFile(tempFile);

        DebugOverlay().show(context!, "🧾 Enviado a impresión");

        exit(0);
      }
    });

    // 🔥 avisar a Android que Flutter ya está listo
    platform.invokeMethod("flutter_ready");

    /// 🧠 CASO 2: app ya abierta
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen((
      files,
    ) async {
      if (files.isNotEmpty) {
        final file = File(files.first.path);

        await VoucherProcessor.processFile(file);

        exit(0);
      }
    });
  }

  @override
  void dispose() {
    _intentSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
