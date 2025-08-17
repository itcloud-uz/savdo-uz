import 'package:flutter/material.dart';

// Dasturda ishlatiladigan barcha ranglar uchun markazlashtirilgan klass
class AppColors {
  // Asosiy ranglar
  static const Color primary = Color(0xFF007BFF); // Asosiy ko'k rang
  static const Color primaryDark = Color(0xFF0056b3); // To'qroq ko'k
  static const Color accent = Color(
      0xFF28A745); // Qo'shimcha yashil rang (masalan, muvaffaqiyatli amallar uchun)

  // Fon ranglari
  static const Color background =
      Color(0xFFF4F6F8); // Orqa fon uchun och kulrang
  static const Color scaffoldBackground = Color(0xFFFFFFFF); // Asosiy oq fon

  // Matn ranglari
  static const Color textPrimary = Color(0xFF212529); // Asosiy qora matn
  static const Color textSecondary =
      Color(0xFF6c757d); // Ikkilamchi kulrang matn
  static const Color textLight = Color(0xFFFFFFFF); // Oq matn

  // Boshqa ranglar
  static const Color cardColor = Color(0xFFFFFFFF); // Kartochkalar rangi
  static const Color borderColor =
      Color(0xFFDEE2E6); // Chegaralar (border) uchun
  static const Color error = Color(0xFFDC3545); // Xatolik rangi
  static const Color success = Color(0xFF28A745); // Muvaffaqiyat rangi
  static const Color warning = Color(0xFFFFC107); // Ogohlantirish rangi
}
