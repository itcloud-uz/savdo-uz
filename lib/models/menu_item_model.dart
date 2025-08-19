// XATOLIK TUZATILDI: Flutter'ning asosiy material kutubxonasi to'g'ri import qilindi.
import 'package:flutter/material.dart';

/// Bosh ekrandagi menyu elementlari uchun model klassi.
/// Bu klass har bir menyu elementi uchun kerakli ma'lumotlarni
/// (nomi, ikonka, bosilganda nima qilish kerakligi) bir joyda saqlaydi.
class MenuItemModel {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  // Konstruktor orqali yangi MenuItemModel obyekti yaratiladi.
  // `required` kalit so'zi bu maydonlarni to'ldirish majburiy ekanligini bildiradi.
  MenuItemModel({
    required this.title,
    required this.icon,
    required this.onTap,
  });
}
