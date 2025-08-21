import 'package:flutter/material.dart';
import 'package:savdo_uz/screens/auth/login_screen.dart';
import 'dart:async';
import 'package:simple_animations/simple_animations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // 3 soniyadan so'ng login ekranga o'tish
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple, // Orqa fon uchun to'q rang
      body: Center(
        child: PlayAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0), // 0 dan 1 gacha animatsiya
          duration: const Duration(seconds: 2), // 2 soniya davomida
          builder: (context, value, child) {
            return Opacity(
              opacity: value, // Sekin-asta ko'rinish
              child: Transform.scale(
                scale: value, // Kichikdan kattalashish
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logotip rasmingiz. Agar rasm bo'lmasa, ikonka ishlatamiz
              Image.asset(
                'assets/images/logo.png', // O'zingizni logotipingiz
                width: 120,
                errorBuilder: (context, error, stackTrace) {
                  // "S" va "U" harflaridan iborat oddiy logo
                  return Text(
                    "SU",
                    style: TextStyle(
                      fontSize: 80,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Savdo-UZ',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
