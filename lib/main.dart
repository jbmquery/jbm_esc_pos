// main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'models/voucher_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  List<SharedMediaFile> sharedFiles = await ReceiveSharingIntent.instance
      .getInitialMedia();

  if (sharedFiles.isNotEmpty) {
    File file = File(sharedFiles.first.path);

    try {
      await VoucherProcessor.processFile(file);
    } catch (_) {}

    exit(0);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomeScreen(),
    );
  }
}
