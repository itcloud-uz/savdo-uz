import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/customer_model.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/widgets/custom_textfield.dart';
import 'package:savdo_uz/providers/theme_provider.dart';

class AddEditCustomerScreen extends StatefulWidget {
  final Customer? customer; // Tahrirlash uchun mijoz ma'lumotlari

  const AddEditCustomerScreen({super.key, this.customer});

  @override
  State<AddEditCustomerScreen> createState() => _AddEditCustomerScreenState();
}

class _AddEditCustomerScreenState extends State<AddEditCustomerScreen> {
  final _phoneRegex =
      RegExp(r'^(\+998|998)?[ -]?(\d{2})[ -]?(\d{3})[ -]?(\d{2})[ -]?(\d{2})');
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
          debt: widget.customer?.debt ?? 0.0,
        );

        if (widget.customer == null) {
          await firestoreService.addCustomer(customer);
        } else {
          await firestoreService.updateCustomer(customer);
        }

        if (!mounted) return;
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xatolik yuz berdi: $e")),
        );
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
        title: const Text("O'chirishni tasdiqlang"),
        content: Text(
          '${widget.customer!.name} ismli mijozni o\'chirishga ishonchingiz komilmi? Bu amalni orqaga qaytarib bo\'lmaydi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("O'chirish"),
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

        if (!mounted) return; // 🔑 async gapdan keyin qo'shildi
        Navigator.pop(context);
      } catch (e) {
        if (!mounted) return; // 🔑 async gapdan keyin qo'shildi
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Xatolik yuz berdi: $e")),
        );
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
    final themeProvider = context.watch<ThemeProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.customer == null ? "Yangi Mijoz" : "Mijozni Tahrirlash"),
        actions: [
          if (widget.customer != null)
            IconButton(
              tooltip: "Mijozni o'chirish",
              icon: const Icon(Icons.delete_outline),
              onPressed: _isLoading ? null : _deleteCustomer,
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
                labelText: "Ism-sharifi",
                validator: (value) =>
                    value!.trim().isEmpty ? "Ismni kiriting" : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _phoneController,
                labelText: "Telefon raqami",
                keyboardType: TextInputType.phone,
                validator: (value) {
                  final v = value?.trim() ?? '';
                  if (v.isEmpty) return "Telefon raqamini kiriting";
                  if (!_phoneRegex.hasMatch(v))
                    return "To‘g‘ri telefon raqamini kiriting (998 XX XXX XX XX)";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _addressController,
                labelText: "Manzil (ixtiyoriy)",
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveCustomer,
                        child: const Text("Saqlash"),
                      ),
                    ),
              const SizedBox(height: 32),
              RadioListTile<ThemeMode>(
                title: const Text('Tizim sozlamasi'),
                value: ThemeMode.system,
                selected: themeProvider.themeMode == ThemeMode.system,
                onChanged: (value) {
                  if (value != null) themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Yorug\' rejim'),
                value: ThemeMode.light,
                selected: themeProvider.themeMode == ThemeMode.light,
                onChanged: (value) {
                  if (value != null) themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text('Qorong\'u rejim'),
                value: ThemeMode.dark,
                selected: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  if (value != null) themeProvider.setThemeMode(value);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
