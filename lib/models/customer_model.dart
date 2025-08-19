import 'package:cloud_firestore/cloud_firestore.dart';

// Mijoz ma'lumotlarini o'zida saqlovchi klass (model).
class Customer {
  final String? id; // Firestore'dagi hujjatning noyob ID'si
  final String name; // Mijozning to'liq ismi
  final String phone; // Telefon raqami
  final String? address; // Manzili (majburiy emas)
  final double debt; // Qancha qarzi borligi

  Customer({
    this.id,
    required this.name,
    required this.phone,
    this.address,
    this.debt = 0.0, // Standart holatda qarzi 0 bo'ladi
  });

  /// Firestore'dan kelgan ma'lumotni (DocumentSnapshot)
  /// `Customer` obyektiga aylantirib beruvchi factory konstruktor.
  factory Customer.fromFirestore(DocumentSnapshot doc) {
    // Ma'lumotni Map ko'rinishiga o'tkazish
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Customer(
      id: doc.id,
      name: data['name'] ?? '', // Agar 'name' bo'lmasa, bo'sh satr qaytaradi
      phone: data['phone'] ?? '', // Agar 'phone' bo'lmasa, bo'sh satr qaytaradi
      address: data['address'], // Manzil bo'lmasligi ham mumkin
      debt: (data['debt'] ?? 0.0)
          .toDouble(), // Agar 'debt' bo'lmasa, 0.0 qaytaradi
    );
  }

  /// `Customer` obyektini Firestore'ga yozish uchun
  /// qulay bo'lgan `Map<String, dynamic>` formatiga o'girib beruvchi metod.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'debt': debt,
    };
  }
}
