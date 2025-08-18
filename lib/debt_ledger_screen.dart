import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:savdo_uz/debt_detail_screen.dart'; // Yangi sahifani import qilamiz
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/customers_screen.dart';

// Qarz modeli
class Debt {
  final String id;
  final String customerId;
  final String customerName;
  final double initialAmount;
  final double remainingAmount;
  final Timestamp createdAt;
  final bool isPaid;
  final List payments;
  final String? comment;

  Debt.fromFirestore(DocumentSnapshot doc)
      : id = doc.id,
        customerId = (doc.data() as Map<String, dynamic>)['customerId'] ?? '',
        customerName =
            (doc.data() as Map<String, dynamic>)['customerName'] ?? 'Noma\'lum',
        initialAmount =
            ((doc.data() as Map<String, dynamic>)['initialAmount'] ?? 0.0)
                .toDouble(),
        remainingAmount =
            ((doc.data() as Map<String, dynamic>)['remainingAmount'] ?? 0.0)
                .toDouble(),
        createdAt = (doc.data() as Map<String, dynamic>)['createdAt'] ??
            Timestamp.now(),
        isPaid = (doc.data() as Map<String, dynamic>)['isPaid'] ?? false,
        payments = (doc.data() as Map<String, dynamic>)['payments'] ?? [],
        comment = (doc.data() as Map<String, dynamic>)['comment'];
}

class DebtLedgerScreen extends StatefulWidget {
  const DebtLedgerScreen({super.key});

  @override
  State<DebtLedgerScreen> createState() => _DebtLedgerScreenState();
}

class _DebtLedgerScreenState extends State<DebtLedgerScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _showAddDebtDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return _AddDebtDialog(firestoreService: _firestoreService);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qarz Daftari'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Yangi qarz qo\'shish',
            onPressed: _showAddDebtDialog,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestoreService.getDebts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Xatolik: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Hozircha qarzlar mavjud emas.",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          // XATOLIKNI TUZATISH: Ma'lumotlarni to'g'ridan-to'g'ri Debt modeliga o'girib olamiz
          final debts = snapshot.data!.docs
              .map((doc) => Debt.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: debts.length,
            itemBuilder: (context, index) {
              final debt = debts[index];
              // Endi _buildDebtCard funksiyasiga Debt obyektini uzatamiz
              return _buildDebtCard(debt);
            },
          );
        },
      ),
    );
  }

  Widget _buildDebtCard(Debt debt) {
    final bool isOverdue = !debt.isPaid &&
        DateTime.now().difference(debt.createdAt.toDate()).inDays > 30;
    final currencyFormat = NumberFormat("#,##0", "uz_UZ");

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: debt.isPaid
              ? Colors.green.shade200
              : (isOverdue ? Colors.red.shade200 : Colors.grey.shade300),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        leading: CircleAvatar(
          backgroundColor: debt.isPaid
              ? Colors.green
              : (isOverdue ? Colors.red : Theme.of(context).primaryColor),
          child: Icon(
              debt.isPaid
                  ? Icons.check_circle_outline
                  : Icons.receipt_long_outlined,
              color: Colors.white),
        ),
        title: Text(
          debt.customerName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Qoldiq: ${currencyFormat.format(debt.remainingAmount)} so\'m',
          style: TextStyle(
            color: debt.isPaid ? Colors.green.shade700 : Colors.red.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing:
            Text(DateFormat('dd.MM.yyyy').format(debt.createdAt.toDate())),
        onTap: () {
          // YANGI SAHIFAGA O'TISH
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DebtDetailScreen(debt: debt),
            ),
          );
        },
      ),
    );
  }
}

// _AddDebtDialog vidjeti o'zgarishsiz qoladi...
class _AddDebtDialog extends StatefulWidget {
  final FirestoreService firestoreService;
  const _AddDebtDialog({required this.firestoreService});
  @override
  State<_AddDebtDialog> createState() => _AddDebtDialogState();
}

class _AddDebtDialogState extends State<_AddDebtDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();
  Customer? _selectedCustomer;
  List<Customer> _customers = [];
  bool _isLoading = false;
  bool _customersLoading = true;
  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _customersLoading = true);
    final snapshot = await widget.firestoreService.getCustomers().first;
    _customers =
        snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList();
    setState(() => _customersLoading = false);
  }

  Future<void> _saveDebt() async {
    if (_formKey.currentState!.validate() && _selectedCustomer != null) {
      setState(() => _isLoading = true);
      try {
        await widget.firestoreService.addDebt(
          customerId: _selectedCustomer!.id,
          customerName: _selectedCustomer!.name,
          amount: double.tryParse(_amountController.text) ?? 0.0,
          comment: _commentController.text,
        );
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text("Xatolik: $e")));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    } else if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Iltimos, mijozni tanlang!"),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yangi Qarz Qo\'shish'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _customersLoading
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<Customer>(
                      value: _selectedCustomer,
                      hint: const Text('Mijozni tanlang'),
                      isExpanded: true,
                      items: _customers.map((customer) {
                        return DropdownMenuItem<Customer>(
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
                    ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration:
                    const InputDecoration(labelText: 'Qarz miqdori (so\'mda)'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Miqdorni kiriting';
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'To\'g\'ri miqdor kiriting';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _commentController,
                decoration:
                    const InputDecoration(labelText: 'Izoh (ixtiyoriy)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Bekor Qilish'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveDebt,
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
