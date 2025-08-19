import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String? id;
  final String description;
  final double amount;
  // XATOLIK TUZATILDI: Yetishmayotgan `date` maydoni qo'shildi.
  final DateTime date;

  Expense({
    this.id,
    required this.description,
    required this.amount,
    required this.date,
  });

  /// Firestore'dan olingan ma'lumotlarni `Expense` obyektiga o'girish.
  factory Expense.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      description: data['description'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      // Sanani `Timestamp`dan `DateTime`ga o'girib olamiz.
      date: (data['date'] as Timestamp).toDate(),
    );
  }

  /// `Expense` obyektini Firestore'ga yozish uchun Map'ga o'girish.
  Map<String, dynamic> toFirestore() {
    return {
      'description': description,
      'amount': amount,
      'date': Timestamp.fromDate(date),
    };
  }
}
