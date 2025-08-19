import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/customer_model.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/widgets/custom_textfield.dart';

class AddEditCustomerScreen extends StatefulWidget {
  final Customer? customer; // Tahrirlash uchun mijoz ma'lumotlari

  const AddEditCustomerScreen({super.key, this.customer});

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name);
    _phoneController = TextEditingController(text: widget.customer?.phone);
    _addressController = TextEditingController(text: widget.customer?.address);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final firestoreService = context.read<FirestoreService>();

      try {
        final customer = Customer(
          id: widget.customer?.id,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          debt: widget.customer?.debt ?? 0.0, // Mavjud qarzni saqlab qolamiz
        );

        if (widget.customer == null) {
          // Yangi mijoz qo'shish
          await firestoreService.addCustomer(customer);
        } else {
          // Mavjud mijozni yangilash
          await firestoreService.updateCustomer(customer);
        }

        if (mounted) {
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
  }

  Future<void> _deleteCustomer() async {
    if (widget.customer == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('O\'chirishni tasdiqlang'),
        content: Text(
            '${widget.customer!.name} ismli mijozni o\'chirishga ishonchingiz komilmi? Bu amalni orqaga qaytarib bo\'lmaydi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('O\'chirish'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        final firestoreService = context.read<FirestoreService>();
        await firestoreService.deleteCustomer(widget.customer!.id!);
        if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.customer == null ? 'Yangi Mijoz' : 'Mijozni Tahrirlash'),
        actions: [
          if (widget.customer != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isLoading ? null : _deleteCustomer,
              tooltip: 'Mijozni o\'chirish',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _nameController,
                labelText: 'Ism-sharifi',
                validator: (value) =>
                    value!.trim().isEmpty ? 'Ismni kiriting' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                labelText: 'Telefon raqami',
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.trim().isEmpty ? 'Telefon raqamini kiriting' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _addressController,
                labelText: 'Manzil (ixtiyoriy)',
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveCustomer,
                        child: const Text('Saqlash'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
