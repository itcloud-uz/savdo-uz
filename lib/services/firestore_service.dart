import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // --- SOTUVLAR (SALES) BO'LIMI ---

  Stream<QuerySnapshot> getSalesForToday() {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    return _db
        .collection('sales')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThanOrEqualTo: endOfDay)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getRecentSales({int limit = 3}) {
    return _db
        .collection('sales')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots();
  }

  // YANGI FUNKSIYA UCHUN JOY
  /// Eng ko'p sotilgan mahsulotlar ro'yxatini qaytaradi.
  /// (Hozircha implementatsiya qilinmagan)
  Stream<QuerySnapshot> getTopSellingProducts({int limit = 3}) {
    // TODO: Bu funksiyani implementatsiya qilish kerak.
    // Bu murakkab agregat so'rov talab qilishi mumkin (masalan, Cloud Functions yordamida).
    // Hozircha bo'sh oqim qaytaramiz.
    return Stream.empty();
  }

  // --- MIJOZLAR (CUSTOMERS) BO'LIMI ---

  Stream<QuerySnapshot> getCustomers() {
    return _db.collection('customers').orderBy('name').snapshots();
  }

  Future<void> addCustomer(Map<String, dynamic> customerData) {
    return _db.collection('customers').add(customerData);
  }

  Future<void> updateCustomer(
      String customerId, Map<String, dynamic> customerData) {
    return _db.collection('customers').doc(customerId).update(customerData);
  }

  Future<void> deleteCustomer(String customerId) {
    return _db.collection('customers').doc(customerId).delete();
  }

  // --- XODIMLAR (EMPLOYEES) BO'LIMI ---

  Stream<QuerySnapshot> getEmployees() {
    return _db.collection('users').orderBy('fullName').snapshots();
  }

  Future<XFile?> pickImage() async {
    return await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
  }

  Future<String> uploadEmployeeImage(File imageFile) async {
    try {
      String fileName =
          'employee_photos/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Rasm yuklashda xatolik: $e");
      rethrow;
    }
  }

  Future<DocumentReference> addEmployee(Map<String, dynamic> employeeData) {
    employeeData['createdAt'] = Timestamp.now();
    return _db.collection('users').add(employeeData);
  }

  Future<void> updateEmployee(
      String employeeId, Map<String, dynamic> employeeData) {
    return _db.collection('users').doc(employeeId).update(employeeData);
  }

  Future<void> deleteEmployee(String employeeId, {String? imageUrl}) async {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        await _storage.refFromURL(imageUrl).delete();
      } catch (e) {
        print("Rasmni o'chirishda xatolik (ehtimol, u mavjud emas): $e");
      }
    }
    await _db.collection('users').doc(employeeId).delete();
  }
}

// --- YORDAMCHI FUNKSIYALAR ---

String formatCurrency(num amount) {
  final format =
      NumberFormat.currency(locale: 'uz_UZ', symbol: "so'm", decimalDigits: 0);
  return format.format(amount);
}
