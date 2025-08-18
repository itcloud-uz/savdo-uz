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

  Future<List<QueryDocumentSnapshot>> getSalesBetweenDates(
      DateTime startDate, DateTime endDate) async {
    DateTime start = DateTime(startDate.year, startDate.month, startDate.day);
    DateTime end =
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    final snapshot = await _db
        .collection('sales')
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThanOrEqualTo: end)
        .orderBy('timestamp', descending: true)
        .get();
    return snapshot.docs;
  }

  // --- MAHSULOTLAR (PRODUCTS) BO'LIMI ---
  Future<DocumentSnapshot?> getProductByBarcode(String barcode) async {
    final querySnapshot = await _db
        .collection('products')
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();
    if (querySnapshot.docs.isNotEmpty) {
      return querySnapshot.docs.first;
    }
    return null;
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
        print("Rasmni o'chirishda xatolik: $e");
      }
    }
    await _db.collection('users').doc(employeeId).delete();
  }

  // --- DAVOMAT (ATTENDANCE) BO'LIMI ---
  Future<List<QueryDocumentSnapshot>> getEmployeeFaceData() async {
    final snapshot = await _db
        .collection('users')
        .where('faceEmbedding', isNotEqualTo: null)
        .get();
    return snapshot.docs;
  }

  Future<void> logAttendance(
      String employeeId, String employeeName, String status) async {
    await _db.collection('attendance_logs').add({
      'employeeId': employeeId,
      'employeeName': employeeName,
      'timestamp': Timestamp.now(),
      'status': status
    });
  }

  Stream<QuerySnapshot> getAttendanceRecords() {
    return _db
        .collection('attendance_logs')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Xodimning bugungi oxirgi davomat yozuvini tekshiradi. (YANGI FUNKSIYA)
  Future<DocumentSnapshot?> getLastAttendanceLogForToday(
      String employeeId) async {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final snapshot = await _db
        .collection('attendance_logs')
        .where('employeeId', isEqualTo: employeeId)
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThanOrEqualTo: endOfDay)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first;
    }
    return null;
  }

  // --- QARZ DAFTARI (DEBT LEDGER) BO'LIMI ---
  Stream<QuerySnapshot> getDebts() {
    return _db
        .collection('debts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> addDebt(
      {required String customerId,
      required String customerName,
      required double amount,
      String? comment}) {
    return _db.collection('debts').add({
      'customerId': customerId,
      'customerName': customerName,
      'initialAmount': amount,
      'remainingAmount': amount,
      'createdAt': Timestamp.now(),
      'lastUpdatedAt': Timestamp.now(),
      'isPaid': false,
      'payments': [],
      'comment': comment
    });
  }

  Future<void> addPaymentToDebt(
      {required String debtId, required double paymentAmount}) async {
    final debtRef = _db.collection('debts').doc(debtId);
    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(debtRef);
      if (!snapshot.exists) throw Exception("Qarz topilmadi!");
      final data = snapshot.data() as Map<String, dynamic>;
      final double remainingAmount =
          (data['remainingAmount'] ?? 0.0).toDouble();
      final double newRemainingAmount = remainingAmount - paymentAmount;
      final newPayment = {'amount': paymentAmount, 'paidAt': Timestamp.now()};
      transaction.update(debtRef, {
        'remainingAmount': newRemainingAmount,
        'isPaid': newRemainingAmount <= 0,
        'lastUpdatedAt': Timestamp.now(),
        'payments': FieldValue.arrayUnion([newPayment])
      });
    });
  }

  // --- XARAJATLAR (EXPENSES) BO'LIMI ---
  Stream<QuerySnapshot> getExpenses() {
    return _db
        .collection('expenses')
        .orderBy('expenseDate', descending: true)
        .snapshots();
  }

  Future<void> addExpense(
      {required String category,
      required double amount,
      required DateTime expenseDate,
      String? description}) {
    return _db.collection('expenses').add({
      'category': category,
      'amount': amount,
      'expenseDate': Timestamp.fromDate(expenseDate),
      'description': description,
      'createdAt': Timestamp.now()
    });
  }
}

// --- YORDAMCHI FUNKSIYALAR ---
String formatCurrency(num amount) {
  final format =
      NumberFormat.currency(locale: 'uz_UZ', symbol: "so'm", decimalDigits: 0);
  return format.format(amount);
}
