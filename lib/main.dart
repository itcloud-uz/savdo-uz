import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/core/theme/app_theme.dart';
import 'package:savdo_uz/providers/auth_provider.dart';
import 'package:savdo_uz/providers/cart_provider.dart';
import 'package:savdo_uz/providers/theme_provider.dart';
import 'package:savdo_uz/screens/auth/login_screen.dart';
import 'package:savdo_uz/screens/home/main_screen.dart';
import 'package:savdo_uz/services/auth_service.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/services/face_recognition_service.dart';
import 'firebase_options.dart';

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
    return MultiProvider(
      providers: [
        // Servislar
        Provider<FirestoreService>(create: (_) => FirestoreService()),
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<FaceRecognitionService>(
            create: (context) => FaceRecognitionService(context)),

        // Holat boshqaruvchilari (ChangeNotifiers)
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(context.read<AuthService>()),
        ),
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
      ],
      // Consumer yordamida ilova mavzusini kuzatib boramiz
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Savdo-UZ',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode, // Mavzuni provayderdan olamiz
            debugShowCheckedModeBanner: false,
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

// Foydalanuvchi tizimga kirgan yoki kirmaganligini tekshiruvchi alohida vidjet
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authStatus = context.watch<AuthProvider>().status;

    // Foydalanuvchi holatiga qarab kerakli ekranni ko'rsatish
    switch (authStatus) {
      case AuthStatus.authenticated:
        return const MainScreen();
      case AuthStatus.unauthenticated:
      case AuthStatus.authenticating:
      default:
        return const LoginScreen();
    }
  }
}
