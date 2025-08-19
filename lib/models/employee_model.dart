import 'package:cloud_firestore/cloud_firestore.dart';

class Employee {
  final String? id;
  final String name;
  final String position;
  final String phone;
  final String? imageUrl; // Rasm uchun URL
  final List<double>? faceEmbedding;

  Employee({
    this.id,
    required this.name,
    required this.position,
    required this.phone,
    this.imageUrl,
    this.faceEmbedding,
  });

  factory Employee.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Employee(
      id: doc.id,
      name: data['name'] ?? '',
      position: data['position'] ?? '',
      phone: data['phone'] ?? '',
      imageUrl: data['imageUrl'], // URL'ni o'qish
      faceEmbedding: data['faceEmbedding'] != null
          ? List<double>.from(data['faceEmbedding'])
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'position': position,
      'phone': phone,
      'imageUrl': imageUrl, // URL'ni yozish
      if (faceEmbedding != null) 'faceEmbedding': faceEmbedding,
    };
  }
}
