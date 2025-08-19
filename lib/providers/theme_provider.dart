import 'package:flutter/material.dart';

// Ilova mavzusini (yorug'/qorong'u) boshqarish uchun provayder
class ThemeProvider with ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners(); // O'zgarish haqida vidjetlarga xabar berish
  }
}
