import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/debt_model.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/widgets/custom_textfield.dart';

class DebtDetailScreen extends StatelessWidget {
  final Debt debt;
  const DebtDetailScreen({super.key, required this.debt});

  void _showAddPaymentDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final firestoreService = context.read<FirestoreService>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('To\'lov qo\'shish'),
        content: Form(
          key: formKey,
          child: CustomTextField(
            controller: amountController,
            labelText: 'To\'lov miqdori',
            keyboardType: TextInputType.number,
            validator: (value) {
              final amount = double.tryParse(value!);
              if (amount == null || amount <= 0) {
                return 'To\'g\'ri summa kiriting';
              }
              if (amount > debt.remainingAmount) {
                return 'Summa qoldiqdan katta bo\'lmasligi kerak';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final paymentAmount = double.parse(amountController.text);
                try {
                  await firestoreService.addPaymentToDebt(
                    debtId: debt.id!,
                    paymentAmount: paymentAmount,
                  );
                  if (context.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('To\'lov muvaffaqiyatli qo\'shildi!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Xatolik: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Qo\'shish'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
        locale: 'uz_UZ', symbol: 'so\'m', decimalDigits: 0);
    final dateFormatter = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(debt.customerName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(context, currencyFormatter),
            const SizedBox(height: 24),
            Text(
              'To\'lovlar tarixi',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            _buildPaymentsList(currencyFormatter, dateFormatter),
          ],
        ),
      ),
      floatingActionButton: debt.isPaid
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddPaymentDialog(context),
              tooltip: 'To\'lov qo\'shish',
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildInfoCard(BuildContext context, NumberFormat formatter) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow('Umumiy qarz:', formatter.format(debt.initialAmount)),
            _buildInfoRow(
              'To\'langan:',
              formatter.format(debt.initialAmount - debt.remainingAmount),
            ),
            const Divider(height: 24),
            _buildInfoRow(
              'Qoldiq:',
              formatter.format(debt.remainingAmount),
              isTotal: true,
              color: debt.isPaid ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isTotal = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsList(
    NumberFormat currencyFormatter,
    DateFormat dateFormatter,
  ) {
    if (debt.payments.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: Center(
            child: Text('Hali to\'lovlar qilinmagan.'),
          ),
        ),
      );
    }
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: debt.payments.length,
        itemBuilder: (context, index) {
          final payment = debt.payments[index];
          return ListTile(
            leading: const CircleAvatar(
              child: Icon(Icons.payment),
            ),
            title: Text(currencyFormatter.format(payment.amount)),
            subtitle: Text(dateFormatter.format(payment.paidAt)),
          );
        },
        separatorBuilder: (ctx, i) => const Divider(height: 1, indent: 16),
      ),
    );
  }
}
