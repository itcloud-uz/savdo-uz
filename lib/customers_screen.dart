import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:savdo_uz/services/firestore_service.dart';

// Mijoz ma'lumotlarini saqlash uchun Model
class Customer {
  final String id;
  final String name;
  final String phoneNumber;
  final String? address;

  Customer({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.address,
  });

  factory Customer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Customer(
      id: doc.id,
      name: data['name'] ?? 'Nomsiz',
      phoneNumber: data['phoneNumber'] ?? 'Raqam kiritilmagan',
      address: data['address'],
    );
  }
}

// Mijozlar ro'yxatini ko'rsatuvchi asosiy ekran
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showCustomerDialog({Customer? customer}) {
    showDialog(
      context: context,
      builder: (context) => _AddEditCustomerDialog(
        firestoreService: _firestoreService,
        customer: customer,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mijozlar Bazasi (CRM)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Yangi mijoz qo\'shish',
            onPressed: () => _showCustomerDialog(),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getCustomers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text("Ma'lumotlarni yuklashda xatolik!"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Mijozlar mavjud emas.'));
          }

          final customers = snapshot.data!.docs
              .map((doc) => Customer.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(customer.name.substring(0, 1)),
                  ),
                  title: Text(customer.name),
                  subtitle: Text(customer.phoneNumber),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () =>
                            _showCustomerDialog(customer: customer),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _deleteCustomer(customer),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _deleteCustomer(Customer customer) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("O'chirishni tasdiqlang"),
        content: Text("${customer.name} ismli mijozni o'chirmoqchimisiz?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Bekor qilish")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("O'chirish"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestoreService.deleteCustomer(customer.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Mijoz muvaffaqiyatli o'chirildi")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Xatolik: $e")),
          );
        }
      }
    }
  }
}

// Mijoz qo'shish va tahrirlash uchun Dialog oynasi
class _AddEditCustomerDialog extends StatefulWidget {
  final FirestoreService firestoreService;
  final Customer? customer;

  const _AddEditCustomerDialog({required this.firestoreService, this.customer});

  @override
  State<_AddEditCustomerDialog> createState() => _AddEditCustomerDialogState();
}

class _AddEditCustomerDialogState extends State<_AddEditCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController =
        TextEditingController(text: widget.customer?.phoneNumber ?? '');
    _addressController =
        TextEditingController(text: widget.customer?.address ?? '');
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final data = {
        'name': _nameController.text,
        'phoneNumber': _phoneController.text,
        'address': _addressController.text,
      };

      try {
        if (widget.customer == null) {
          await widget.firestoreService.addCustomer(data);
        } else {
          await widget.firestoreService
              .updateCustomer(widget.customer!.id, data);
        }
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Saqlashda xatolik: $e")),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.customer == null ? 'Yangi Mijoz' : 'Mijozni Tahrirlash'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Ism, Familiya'),
                validator: (value) => value!.isEmpty ? 'Ismni kiriting' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                    labelText: 'Telefon raqami', prefixText: '+998 '),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.isEmpty ? 'Raqamni kiriting' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration:
                    const InputDecoration(labelText: 'Manzil (ixtiyoriy)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Bekor qilish'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveCustomer,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Saqlash'),
        ),
      ],
    );
  }
}
