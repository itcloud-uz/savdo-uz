import 'package:flutter/material.dart';
import 'package:savdo_uz/login_screen.dart';

// Firebase bilan ishlash uchun bu qatorlar kerak bo'ladi
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase sozlamalari yangi loyihada qaytadan qilinishi kerak bo'ladi
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Savdo.uz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFF1F5F9),
      ),
      home: const LoginScreen(),
    );
  }
}
