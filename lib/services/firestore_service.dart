import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:savdo_uz/models/attendance_log_model.dart';
import 'package:savdo_uz/models/customer_model.dart';
import 'package:savdo_uz/models/debt_model.dart';
import 'package:savdo_uz/models/employee_model.dart';
import 'package:savdo_uz/models/expense_model.dart';
import 'package:savdo_uz/models/product_model.dart';
import 'package:savdo_uz/models/sale_model.dart';

/// Firestore va Firebase Storage bilan ishlash uchun mas'ul bo'lgan markaziy servis.
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- MAHSULOTLAR (PRODUCTS) ---
  Stream<List<Product>> getProducts() {
    return _db.collection('products').orderBy('name').snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => Product.fromFirestore(doc)).toList());
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final snapshot = await _db
        .collection('products')
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return Product.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  Future<void> addProduct(Product product) {
    return _db.collection('products').add(product.toFirestore());
  }

  Future<void> updateProduct(Product product) {
    return _db
        .collection('products')
        .doc(product.id)
        .update(product.toFirestore());
  }

  Future<void> deleteProduct(String productId) {
    return _db.collection('products').doc(productId).delete();
  }

  // --- SOTUVLAR (SALES) ---
  Future<void> addSale(Sale sale) async {
    return _db.runTransaction((transaction) async {
      final saleRef = _db.collection('sales').doc();
      transaction.set(saleRef, sale.toFirestore());

      if (sale.paymentType == 'debt' && sale.customerId != null) {
        final customerRef = _db.collection('customers').doc(sale.customerId!);
        transaction.update(
            customerRef, {'debt': FieldValue.increment(sale.totalAmount)});
      }

      for (var item in sale.items) {
        final productRef = _db.collection('products').doc(item.product.id!);
        transaction.update(
            productRef, {'quantity': FieldValue.increment(-item.quantity)});
      }
    });
  }

  Stream<List<Sale>> getSalesForToday() {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    return _db
        .collection('sales')
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Sale.fromFirestore(doc)).toList());
  }

  Stream<List<Sale>> getRecentSales({int limit = 5}) {
    return _db
        .collection('sales')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Sale.fromFirestore(doc)).toList());
  }

  Future<List<Sale>> getSalesBetweenDates(
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

    return snapshot.docs.map((doc) => Sale.fromFirestore(doc)).toList();
  }

  // --- MIJOZLAR (CUSTOMERS) ---
  Stream<List<Customer>> getCustomers() {
    return _db.collection('customers').orderBy('name').snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList());
  }

  Future<void> addCustomer(Customer customer) {
    return _db.collection('customers').add(customer.toFirestore());
  }

  Future<void> updateCustomer(Customer customer) {
    return _db
        .collection('customers')
        .doc(customer.id)
        .update(customer.toFirestore());
  }

  Future<void> deleteCustomer(String customerId) {
    return _db.collection('customers').doc(customerId).delete();
  }

  // --- XODIMLAR (EMPLOYEES) ---
  Stream<List<Employee>> getEmployees() {
    return _db.collection('employees').orderBy('name').snapshots().map(
        (snapshot) =>
            snapshot.docs.map((doc) => Employee.fromFirestore(doc)).toList());
  }

  Future<String> uploadEmployeeImage(File imageFile) async {
    String fileName =
        'employee_photos/${DateTime.now().millisecondsSinceEpoch}.jpg';
    Reference ref = _storage.ref().child(fileName);
    UploadTask uploadTask = ref.putFile(imageFile);
    TaskSnapshot snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> addEmployee(Employee employee) {
    return _db.collection('employees').add(employee.toFirestore());
  }

  Future<void> updateEmployee(Employee employee) {
    return _db
        .collection('employees')
        .doc(employee.id)
        .update(employee.toFirestore());
  }

  // XATOLIK TUZATILDI: `deleteEmployee` endi `String employeeId` qabul qiladi.
  // Bu `add_edit_employee_screen`dagi xatolikni ham tuzatadi.
  Future<void> deleteEmployee(String employeeId) async {
    // Avval xodim hujjatini o'qib, rasm URL'ini olamiz.
    DocumentSnapshot doc =
        await _db.collection('employees').doc(employeeId).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>?;
      final imageUrl = data?['imageUrl'] as String?;
      if (imageUrl != null && imageUrl.isNotEmpty) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          debugPrint("Rasmni o'chirishda xatolik: $e");
        }
      }
    }
    // Hujjatni o'chiramiz.
    await _db.collection('employees').doc(employeeId).delete();
  }

  // XATOLIK TUZATILDI: `faceEmbedding` o'rniga `faceData` ishlatildi.
  Future<List<Employee>> getAllEmployeesWithFaceData() async {
    try {
      final snapshot = await _db
          .collection('employees')
          .where('faceData', isNotEqualTo: []).get();
      return snapshot.docs.map((doc) => Employee.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint("Yuz ma'lumotli xodimlarni olishda xatolik: $e");
      return [];
    }
  }

  // --- DAVOMAT (ATTENDANCE) ---
  Future<void> logAttendance(AttendanceLog log) async {
    await _db.collection('attendance_logs').add(log.toFirestore());
  }

  Stream<List<AttendanceLog>> getAttendanceRecords() {
    return _db
        .collection('attendance_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceLog.fromFirestore(doc))
            .toList());
  }

  Future<AttendanceLog?> getLastAttendanceLogForToday(String employeeId) async {
    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    final snapshot = await _db
        .collection('attendance_logs')
        .where('employeeId', isEqualTo: employeeId)
        .where('timestamp', isGreaterThanOrEqualTo: startOfDay)
        .where('timestamp', isLessThan: endOfDay)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return AttendanceLog.fromFirestore(snapshot.docs.first);
    }
    return null;
  }

  // --- QARZ DAFTARI (DEBT LEDGER) ---
  Stream<List<Debt>> getDebts() {
    return _db
        .collection('debts')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Debt.fromFirestore(doc)).toList());
  }

  Future<void> addDebt(Debt debt) {
    return _db.collection('debts').add(debt.toFirestore());
  }

  Future<void> addPaymentToDebt(
      {required String debtId, required double paymentAmount}) async {
    final debtRef = _db.collection('debts').doc(debtId);
    return _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(debtRef);
      if (!snapshot.exists) throw Exception("Qarz topilmadi!");

      Debt debt = Debt.fromFirestore(snapshot);
      double newRemainingAmount = debt.remainingAmount - paymentAmount;
      final newPayment = Payment(amount: paymentAmount, paidAt: DateTime.now());

      List<Map<String, dynamic>> paymentsMap =
          debt.payments.map((p) => p.toMap()).toList();
      paymentsMap.add(newPayment.toMap());

      transaction.update(debtRef, {
        'remainingAmount': newRemainingAmount,
        'isPaid': newRemainingAmount <= 0,
        'lastUpdatedAt': Timestamp.now(),
        'payments': paymentsMap,
      });
    });
  }

  // --- XARAJATLAR (EXPENSES) ---
  Stream<List<Expense>> getExpenses() {
    // XATOLIK TUZATILDI: `expenseDate` o'rniga `date` ishlatildi.
    return _db
        .collection('expenses')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Expense.fromFirestore(doc)).toList());
  }

  Future<void> addExpense(Expense expense) {
    return _db.collection('expenses').add(expense.toFirestore());
  }

  Future<void> updateExpense(Expense expense) {
    return _db
        .collection('expenses')
        .doc(expense.id)
        .update(expense.toFirestore());
  }

  Future<void> deleteExpense(String expenseId) {
    return _db.collection('expenses').doc(expenseId).delete();
  }
}
