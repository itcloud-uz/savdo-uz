import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppTheme {
  static ThemeData get lightTheme {
    final ThemeData base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      // 1. Asosiy ranglar va fon
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,

      // 2. ColorScheme (Komponentlarning standart ranglari)
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        error: AppColors.error,
        surface: AppColors.card, // Card, Dialog kabi elementlar foni
        surfaceContainer: AppColors.background, // background o‘rniga
      ),

      // 3. Matn stillari (Tipografiya)
      textTheme: base.textTheme
          .copyWith(
            displayLarge: AppTextStyles.headline1,
            displayMedium: AppTextStyles.headline2,
            displaySmall: AppTextStyles.headline3,
            bodyLarge: AppTextStyles.bodyText1,
            bodyMedium: AppTextStyles.bodyText2,
            labelLarge: AppTextStyles.button, // Tugmalar uchun
          )
          .apply(
            fontFamily: 'Inter', // Barcha matnlarga yagona shrift
            displayColor: AppColors.textPrimary,
            bodyColor: AppColors.textPrimary,
          ),

      // 4. AppBar uchun tema
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.textPrimary, // Ikonka va sarlavha rangi
        elevation: 1,
        centerTitle: true, // Sarlavhani markazga joylash
      ),

      // 5. Card (Kartochka) uchun tema
      cardTheme: CardThemeData(
        elevation: 1, // Soyani biroz kamaytiramiz
        color: AppColors.card,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          side: const BorderSide(
            color: Color(0xFFE0E0E0),
            width: 0.5,
          ), // Yengil chegara
        ),
      ),

      // 6. ElevatedButton (Tugma) uchun tema
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      // 7. TextField (Matn kiritish maydoni) uchun tema
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: AppTextStyles.bodyText2,
      ),

      // 8. FloatingActionButton (Qalqib turuvchi tugma) uchun tema
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
      ),

      // 9. Dialog (Muloqot oynasi) uchun tema
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),

      // 10. Divider (Ajratuvchi chiziq) uchun tema
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
      ),
    );
  }
}
