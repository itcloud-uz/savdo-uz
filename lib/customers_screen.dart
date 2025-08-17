// lib/customers_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/add_edit_customer_screen.dart'; // YANGI SAHIFANI IMPORT QILAMIZ

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mijozlar Bazasi'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getCustomers(),
        builder: (context, snapshot) {
          // ... (bu qism o'zgarishsiz qoladi)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text("Ma'lumotlarni yuklashda xatolik!"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Hozircha mijozlar qo'shilmagan.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final customers = snapshot.data!.docs;

          return ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index].data() as Map<String, dynamic>;
              final customerName = customer['name'] ?? 'Nomsiz';
              final customerPhone =
                  customer['phoneNumber'] ?? 'Raqam kiritilmagan';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(customerName.isNotEmpty
                        ? customerName[0].toUpperCase()
                        : '?'),
                  ),
                  title: Text(customerName),
                  subtitle: Text(customerPhone),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Kelajakda mijoz ma'lumotlarini ko'rish/tahrirlash uchun
                  },
                ),
              );
            },
          );
        },
      ),
      // FLOATING ACTION BUTTON YANGILANDI
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Yangi mijoz qo'shish oynasini ochish
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const AddEditCustomerScreen()),
          );
        },
        tooltip: 'Yangi mijoz qo\'shish',
        child: const Icon(Icons.add),
      ),
    );
  }
}
