// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:savdo_uz/core/theme/app_theme.dart'; // Yangi import
import 'firebase_options.dart';
import 'login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Savdo.uz',
      debugShowCheckedModeBanner: false, // Bannerni olib tashlash
      theme: AppTheme.lightTheme, // YARATILGAN YANGI TEMANI ULASH
      home: LoginScreen(),
    );
  }
}
