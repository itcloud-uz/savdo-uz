// lib/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Sana formatlash uchun kerak

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- SOTUVLAR (SALES) BO'LIMI ---

  /// Bugungi kungi barcha sotuvlar oqimini (stream) qaytaradi.
  Stream<QuerySnapshot> getSalesForToday() {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day); // Bugun 00:00
    DateTime endOfDay =
        DateTime(now.year, now.month, now.day, 23, 59, 59); // Bugun 23:59

    return _db
        .collection('sales')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThanOrEqualTo: endOfDay)
        .snapshots();
  }

  /// Oxirgi N ta sotuvlar oqimini (stream) qaytaradi. Standart qiymat 3 ta.
  Stream<QuerySnapshot> getRecentSales({int limit = 3}) {
    return _db
        .collection('sales')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  // --- MIJOZLAR (CUSTOMERS) BO'LIMI ---

  /// Barcha mijozlar ro'yxatini alifbo tartibida oqim (stream) sifatida qaytaradi.
  Stream<QuerySnapshot> getCustomers() {
    return _db.collection('customers').orderBy('name').snapshots();
  }

  /// Yangi mijozni ma'lumotlar bazasiga qo'shadi.
  Future<void> addCustomer(Map<String, dynamic> customerData) {
    return _db.collection('customers').add(customerData);
  }

  /// Mavjud mijoz ma'lumotlarini yangilaydi.
  Future<void> updateCustomer(
      String customerId, Map<String, dynamic> customerData) {
    return _db.collection('customers').doc(customerId).update(customerData);
  }

  /// Belgilangan mijozni ma'lumotlar bazasidan o'chiradi.
  Future<void> deleteCustomer(String customerId) {
    return _db.collection('customers').doc(customerId).delete();
  }
}

// --- YORDAMCHI FUNKSIYALAR ---

/// Pul miqdorini o'zbek so'mi formatida chiroyli ko'rinishga keltiradi.
/// Masalan: 1250000 -> 1 250 000 so'm
String formatCurrency(num amount) {
  final format =
      NumberFormat.currency(locale: 'uz_UZ', symbol: "so'm", decimalDigits: 0);
  return format.format(amount);
}
