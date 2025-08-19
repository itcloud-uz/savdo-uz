import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/customer_model.dart';
import 'package:savdo_uz/models/debt_model.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/widgets/custom_textfield.dart';

class AddDebtScreen extends StatefulWidget {
  const AddDebtScreen({super.key});

  @override
  State<AddDebtScreen> createState() => _AddDebtScreenState();
}

class _AddDebtScreenState extends State<AddDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();
  Customer? _selectedCustomer;
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _saveDebt() async {
    if (_formKey.currentState!.validate() && _selectedCustomer != null) {
      setState(() {
        _isLoading = true;
      });

      final firestoreService = context.read<FirestoreService>();
      final amount = double.tryParse(_amountController.text) ?? 0.0;

      try {
        final newDebt = Debt(
          customerId: _selectedCustomer!.id!,
          customerName: _selectedCustomer!.name,
          initialAmount: amount,
          remainingAmount: amount,
          createdAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
          comment: _commentController.text.trim(),
        );

        await firestoreService.addDebt(newDebt);

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Xatolik: $e")));
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else if (_selectedCustomer == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Iltimos, mijozni tanlang")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Yangi Qarz Qo'shish"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mijoz tanlash uchun Dropdown
              StreamBuilder<List<Customer>>(
                stream: firestoreService.getCustomers(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final customers = snapshot.data!;
                  return DropdownButtonFormField<Customer>(
                    initialValue: _selectedCustomer,
                    hint: const Text('Mijozni tanlang'),
                    isExpanded: true,
                    items: customers.map((customer) {
                      return DropdownMenuItem(
                        value: customer,
                        child: Text(customer.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCustomer = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Mijoz tanlanishi shart' : null,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _amountController,
                labelText: 'Qarz miqdori',
                keyboardType: TextInputType.number,
                validator: (value) => (double.tryParse(value!) == null ||
                        double.parse(value) <= 0)
                    ? "To'g'ri summa kiriting"
                    : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _commentController,
                labelText: 'Izoh (ixtiyoriy)',
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveDebt,
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
