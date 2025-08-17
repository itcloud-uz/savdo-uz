// lib/add_edit_customer_screen.dart

import 'package:flutter/material.dart';
import 'package:savdo_uz/services/firestore_service.dart';

class AddEditCustomerScreen extends StatefulWidget {
  const AddEditCustomerScreen({super.key});

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _firestoreService = FirestoreService();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    // 1. Formadagi ma'lumotlar to'g'riligini tekshirish (validatsiya)
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 2. Yangi mijoz ma'lumotlarini Map (lug'at) ko'rinishida tayyorlash
      final customerData = {
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'addedDate': DateTime.now(),
      };

      // 3. FirestoreService orqali ma'lumotlarni bazaga qo'shish
      await _firestoreService.addCustomer(customerData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Mijoz muvaffaqiyatli qo'shildi!"),
            backgroundColor: Colors.green,
          ),
        );
        // 4. Orqaga, mijozlar ro'yxati sahifasiga qaytish
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xatolik yuz berdi: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Yangi Mijoz Qo'shish"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Mijoz ismi uchun kiritish maydoni
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Mijozning to'liq ismi",
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Iltimos, mijoz ismini kiriting";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Telefon raqami uchun kiritish maydoni
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: "Telefon raqami",
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: "+9989...",
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Iltimos, telefon raqamini kiriting";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Saqlash tugmasi
              ElevatedButton(
                onPressed: _isLoading ? null : _saveCustomer,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text("Saqlash"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
