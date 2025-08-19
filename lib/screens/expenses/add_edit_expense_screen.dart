import 'package:flutter/material.dart';
// XATOLIK TUZATILDI: Import yo'li to'g'rilandi.
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/expense_model.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/widgets/custom_textfield.dart';
import 'package:intl/intl.dart';

class AddEditExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddEditExpenseScreen({super.key, this.expense});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _descriptionController =
        TextEditingController(text: widget.expense?.description);
    _amountController =
        TextEditingController(text: widget.expense?.amount.toString());
    if (widget.expense != null) {
      _selectedDate = widget.expense!.date;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  /// Foydalanuvchiga sana tanlash oynasini ko'rsatish
  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  /// Xarajat ma'lumotlarini saqlash
  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final firestoreService = context.read<FirestoreService>();
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      try {
        final expense = Expense(
          id: widget.expense?.id,
          description: _descriptionController.text.trim(),
          amount: double.tryParse(_amountController.text) ?? 0.0,
          date: _selectedDate,
        );

        if (widget.expense == null) {
          await firestoreService.addExpense(expense);
        } else {
          await firestoreService.updateExpense(expense);
        }

        navigator.pop();
      } catch (e) {
        messenger.showSnackBar(SnackBar(content: Text("Xatolik: $e")));
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.expense == null ? 'Yangi Xarajat' : 'Tahrirlash'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Xarajat tavsifi',
                validator: (value) =>
                    value!.trim().isEmpty ? 'Tavsifni kiriting' : null,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _amountController,
                labelText: 'Summasi',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Summani kiriting';
                  }
                  if (double.tryParse(value) == null) {
                    return 'To\'g\'ri summa kiriting';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Sana tanlash qismi
              ListTile(
                title: const Text('Sana'),
                subtitle:
                    Text(DateFormat('dd MMMM, yyyy').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _pickDate,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(height: 32),

              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveExpense,
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
