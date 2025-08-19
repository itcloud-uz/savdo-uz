// lib/theme/app_theme.dart
import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  /// Yengil (Light) mavzu
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.lightBg,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.lightBg,
      elevation: 0.5,
      iconTheme: IconThemeData(color: AppColors.lightText),
      titleTextStyle: TextStyle(
        color: AppColors.lightText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.lightText,
      ),
      contentTextStyle: TextStyle(
        fontSize: 16,
        color: AppColors.lightText,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.secondary,
      type: BottomNavigationBarType.fixed,
    ),
  );

  /// Qorong‘i (Dark) mavzu
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.darkBg,
    fontFamily: 'Roboto',
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.darkBg,
      elevation: 0.5,
      iconTheme: IconThemeData(color: AppColors.darkText),
      titleTextStyle: TextStyle(
        color: AppColors.darkText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: const CardThemeData(
      color: Color(0xFF2C2C2C),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    dialogTheme: const DialogThemeData(
      backgroundColor: Color(0xFF2C2C2C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.darkText,
      ),
      contentTextStyle: TextStyle(
        fontSize: 16,
        color: AppColors.darkText,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF2C2C2C),
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.secondary,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
