// Mahsulot ma'lumotlari uchun model.
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String? id;
  final String name;
  final String barcode;
  final double price;
  final int quantity;

  Product({
    this.id,
    required this.name,
    required this.barcode,
    required this.price,
    required this.quantity,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      barcode: data['barcode'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      quantity: data['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'barcode': barcode,
      'price': price,
      'quantity': quantity,
    };
  }
}
