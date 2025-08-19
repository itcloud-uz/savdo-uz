import 'package:cloud_firestore/cloud_firestore.dart';

class Employee {
  final String? id;
  final String name;
  final String position;
  final String? phone;
  final String? imageUrl;
  // YETISHMAYOTGAN QISM QO'SHILDI: Yuz ma'lumotlarini saqlash uchun maydon.
  final List<dynamic> faceData;

  Employee({
    this.id,
    required this.name,
    required this.position,
    this.phone,
    this.imageUrl,
    this.faceData = const [], // Standart qiymat sifatida bo'sh ro'yxat berildi
  });

  /// Firestore'dan olingan ma'lumotlarni `Employee` obyektiga o'girish.
  factory Employee.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Employee(
      id: doc.id,
      name: data['name'] ?? '',
      position: data['position'] ?? '',
      phone: data['phone'],
      imageUrl: data['imageUrl'],
      // Firestore'dan `faceData`ni o'qish
      faceData: List<dynamic>.from(data['faceData'] ?? []),
    );
  }

  /// `Employee` obyektini Firestore'ga yozish uchun Map'ga o'girish.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'position': position,
      'phone': phone,
      'imageUrl': imageUrl,
      'faceData': faceData,
    };
  }
}
