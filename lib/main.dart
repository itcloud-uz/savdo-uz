import 'package:flutter/material.dart';
import 'package:savdo_uz/login_screen.dart';

// Firebase bilan ishlash uchun kerakli kutubxonalarni import qilamiz
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  // Loyiha ishga tushishidan oldin barcha bindinglarning to'g'ri ishlashini ta'minlaymiz
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase'ni ishga tushiramiz
  // Bu qism Firebase'ni loyihaga ulash uchun juda muhim
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase'ni ishga tushirishda xatolik yuz berdi: $e");
    // Agar Firebase ishga tushmasa ham, ilova ishga tushishi uchun
    // faqat konsolga xato yozib qo'yamiz.
  }

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
