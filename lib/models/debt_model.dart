import 'package:cloud_firestore/cloud_firestore.dart';

// To'lov ma'lumotlari uchun yordamchi model
class Payment {
  final double amount;
  final DateTime paidAt;

  Payment({required this.amount, required this.paidAt});

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      amount: (map['amount'] ?? 0.0).toDouble(),
      paidAt: (map['paidAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'paidAt': Timestamp.fromDate(paidAt),
    };
  }
}

// Qarz ma'lumotlari uchun model
class Debt {
  final String? id;
  final String customerId;
  final String customerName;
  final double initialAmount;
  final double remainingAmount;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final bool isPaid;
  final List<Payment> payments;
  final String? comment;

  Debt({
    this.id,
    required this.customerId,
    required this.customerName,
    required this.initialAmount,
    required this.remainingAmount,
    required this.createdAt,
    required this.lastUpdatedAt,
    this.isPaid = false,
    this.payments = const [],
    this.comment,
  });

  factory Debt.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Debt(
      id: doc.id,
      customerId: data['customerId'] ?? '',
      customerName: data['customerName'] ?? '',
      initialAmount: (data['initialAmount'] ?? 0.0).toDouble(),
      remainingAmount: (data['remainingAmount'] ?? 0.0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastUpdatedAt: (data['lastUpdatedAt'] as Timestamp).toDate(),
      isPaid: data['isPaid'] ?? false,
      payments: (data['payments'] as List? ?? [])
          .map((p) => Payment.fromMap(p))
          .toList(),
      comment: data['comment'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'initialAmount': initialAmount,
      'remainingAmount': remainingAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
      'isPaid': isPaid,
      'payments': payments.map((p) => p.toMap()).toList(),
      'comment': comment,
    };
  }
}
