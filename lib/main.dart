import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'models/voucher_model.dart';

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

  @override
  void initState() {
    super.initState();

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
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
