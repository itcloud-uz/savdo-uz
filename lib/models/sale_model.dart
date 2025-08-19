import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:savdo_uz/models/cart_item_model.dart';

// To'lov turini belgilash uchun enum
enum PaymentType { cash, card, debt }

// Sotuv ma'lumotlari uchun model
class Sale {
  final String? id;
  final String saleId; // Noyob chek raqami (masalan, 20240819-001)
  final double totalAmount;
  final DateTime timestamp;
  final List<CartItem> items;
  final String paymentType; // 'cash', 'card', yoki 'debt'
  final String? customerId; // Agar qarzga olinsa
  final String? customerName; // Agar qarzga olinsa

  Sale({
    this.id,
    required this.saleId,
    required this.totalAmount,
    required this.timestamp,
    required this.items,
    required this.paymentType,
    this.customerId,
    this.customerName,
  });

  factory Sale.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Sale(
      id: doc.id,
      saleId: data['saleId'] ?? '',
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      // Ma'lumotlar bazasidan o'qishda `items`ni `CartItem`ga aylantiramiz
      items: (data['items'] as List<dynamic>? ?? [])
          .map((item) => CartItem.fromMap(item))
          .toList(),
      paymentType: data['paymentType'] ?? 'cash',
      customerId: data['customerId'],
      customerName: data['customerName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'saleId': saleId,
      'totalAmount': totalAmount,
      'timestamp': Timestamp.fromDate(timestamp),
      // Ma'lumotlar bazasiga yozishda `items`ni `Map`ga aylantiramiz
      'items': items.map((item) => item.toMap()).toList(),
      'paymentType': paymentType,
      'customerId': customerId,
      'customerName': customerName,
    };
  }
}
