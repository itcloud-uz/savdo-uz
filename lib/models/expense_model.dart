import 'package:cloud_firestore/cloud_firestore.dart';

// Xarajat ma'lumotlari uchun model
class Expense {
  final String? id;
  final String category;
  final double amount;
  final DateTime expenseDate;
  final String? description;
  final DateTime createdAt;

  Expense({
    this.id,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.description,
    required this.createdAt,
  });

  factory Expense.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Expense(
      id: doc.id,
      category: data['category'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      expenseDate: (data['expenseDate'] as Timestamp).toDate(),
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'category': category,
      'amount': amount,
      'expenseDate': Timestamp.fromDate(expenseDate),
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
