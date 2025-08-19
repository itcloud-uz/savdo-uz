// Asosiy MaterialApp vidjeti va marshrutlash.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/core/theme/app_theme.dart';
import 'package:savdo_uz/providers/auth_provider.dart';
import 'package:savdo_uz/screens/auth/login_screen.dart';
import 'package:savdo_uz/screens/home/main_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Savdo-UZ',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // "const" olib tashlandi, chunki Consumer o'zgaruvchan
          switch (auth.status) {
            case AuthStatus.authenticated:
              return const MainScreen(); // Bu yerda const ishlatsa bo'ladi
            case AuthStatus.unauthenticated:
            case AuthStatus.authenticating:
            default:
              return const LoginScreen(); // Bu yerda ham
          }
        },
      ),
    );
  }
}
