// Mahsulot ma'lumotlari uchun model.
import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String? id;
  final String name;
  final String barcode;
  final double price;
  final double quantity;
  final String unit;

  Product({
    this.id,
    required this.name,
    required this.barcode,
    required this.price,
    required this.quantity,
    this.unit = "dona",
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      barcode: data['barcode'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      quantity: (data['quantity'] ?? 0).toDouble(),
      unit: data['unit'] ?? "dona",
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'barcode': barcode,
      'price': price,
      'quantity': quantity,
      'unit': unit,
    };
  }
}
