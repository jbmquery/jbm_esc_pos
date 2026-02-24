import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

// 🔥 FIREBASE DESACTIVADO TEMPORALMENTE
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

void main() {
  // 🔥 Si en algún momento activas Firebase:
  // WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp();

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
