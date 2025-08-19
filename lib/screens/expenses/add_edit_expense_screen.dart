import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/expense_model.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/widgets/custom_textfield.dart';

class AddEditExpenseScreen extends StatefulWidget {
  final Expense? expense;

  const AddEditExpenseScreen({super.key, this.expense});

  @override
  State<AddEditExpenseScreen> createState() => _AddEditExpenseScreenState();
}

class _AddEditExpenseScreenState extends State<AddEditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _categoryController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;

  bool _isLoading = false;

  // Xarajat kategoriyalari ro'yxati
  final List<String> _expenseCategories = [
    'Ijara',
    'Oylik maosh',
    'Kommunal to\'lovlar',
    'Soliqlar',
    'Mahsulot xaridi',
    'Marketing',
    'Boshqa',
  ];

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController(text: widget.expense?.category);
    _amountController =
        TextEditingController(text: widget.expense?.amount.toString());
    _descriptionController =
        TextEditingController(text: widget.expense?.description);
    _selectedDate = widget.expense?.expenseDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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

  Future<void> _saveExpense() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final firestoreService = context.read<FirestoreService>();

      try {
        final expense = Expense(
          id: widget.expense?.id,
          category: _categoryController.text.trim(),
          amount: double.tryParse(_amountController.text) ?? 0.0,
          expenseDate: _selectedDate,
          description: _descriptionController.text.trim(),
          createdAt: widget.expense?.createdAt ?? DateTime.now(),
        );

        if (widget.expense == null) {
          await firestoreService.addExpense(expense);
        } else {
          await firestoreService.updateExpense(expense);
        }

        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Xatolik: $e")));
      } finally {
        if (mounted)
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
        title: Text(widget.expense == null ? 'Yangi Xarajat' : 'Tahrirlash'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Kategoriya tanlash
              DropdownButtonFormField<String>(
                value: _categoryController.text.isNotEmpty
                    ? _categoryController.text
                    : null,
                hint: const Text('Kategoriyani tanlang'),
                items: _expenseCategories.map((category) {
                  return DropdownMenuItem(
                      value: category, child: Text(category));
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    _categoryController.text = value;
                  }
                },
                validator: (value) => value == null || value.isEmpty
                    ? 'Kategoriyani tanlang'
                    : null,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _amountController,
                labelText: 'Miqdori (summa)',
                keyboardType: TextInputType.number,
                validator: (value) => (double.tryParse(value!) == null ||
                        double.parse(value) <= 0)
                    ? 'To\'g\'ri summa kiriting'
                    : null,
              ),
              const SizedBox(height: 16),
              // Sana tanlash
              TextFormField(
                readOnly: true,
                controller: TextEditingController(
                    text: DateFormat('dd.MM.yyyy').format(_selectedDate)),
                decoration: InputDecoration(
                  labelText: 'Sanasi',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickDate,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _descriptionController,
                labelText: 'Izoh (ixtiyoriy)',
                maxLines: 3,
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
