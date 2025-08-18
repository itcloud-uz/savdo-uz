import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:savdo_uz/debt_ledger_screen.dart'; // Debt modelini olish uchun
import 'package:savdo_uz/services/firestore_service.dart';

class DebtDetailScreen extends StatelessWidget {
  final Debt debt;
  const DebtDetailScreen({super.key, required this.debt});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat("#,##0", "uz_UZ");

    return Scaffold(
      appBar: AppBar(
        title: Text(debt.customerName),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Umumiy ma'lumot kartasi
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildInfoRow('Umumiy qarz:',
                        '${currencyFormat.format(debt.initialAmount)} so\'m'),
                    const SizedBox(height: 8),
                    _buildInfoRow('Qoldiq:',
                        '${currencyFormat.format(debt.remainingAmount)} so\'m',
                        isHighlight: true),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                        'Olingan sana:',
                        DateFormat('dd.MM.yyyy')
                            .format(debt.createdAt.toDate())),
                    if (debt.comment != null && debt.comment!.isNotEmpty) ...[
                      const Divider(height: 24),
                      _buildInfoRow('Izoh:', debt.comment!),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // To'lovlar tarixi
            Text("To'lovlar tarixi",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Expanded(
              child: debt.payments.isEmpty
                  ? const Center(child: Text("Hali to'lovlar qilinmagan."))
                  : ListView.builder(
                      itemCount: debt.payments.length,
                      itemBuilder: (context, index) {
                        final payment = debt.payments.reversed.toList()[index];
                        return Card(
                          child: ListTile(
                            leading:
                                const CircleAvatar(child: Icon(Icons.payment)),
                            title: Text(
                                '${currencyFormat.format(payment['amount'])} so\'m'),
                            subtitle: Text(DateFormat('dd.MM.yyyy HH:mm')
                                .format((payment['paidAt']).toDate())),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      // To'lov qilish tugmasi
      floatingActionButton: debt.isPaid
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                _showAddPaymentDialog(context, debt.id);
              },
              label: const Text("To'lov qilish"),
              icon: const Icon(Icons.add),
            ),
    );
  }

  // Ma'lumot qatorini yasovchi yordamchi vidjet
  Widget _buildInfoRow(String title, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
            color: isHighlight ? Colors.red.shade700 : null,
          ),
        ),
      ],
    );
  }

  // To'lov qilish dialogini ko'rsatish
  void _showAddPaymentDialog(BuildContext context, String debtId) {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final firestoreService = FirestoreService();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("To'lov miqdorini kiriting"),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: amountController,
              decoration: const InputDecoration(labelText: 'Summa (so\'mda)'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    double.parse(value) <= 0) {
                  return "To'g'ri summa kiriting";
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Bekor qilish")),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final amount = double.parse(amountController.text);
                  await firestoreService.addPaymentToDebt(
                      debtId: debtId, paymentAmount: amount);
                  if (context.mounted)
                    Navigator.pop(context); // Dialog oynasini yopish
                  if (context.mounted)
                    Navigator.pop(
                        context); // Detal sahifasini yopib, orqaga qaytish
                }
              },
              child: const Text("Saqlash"),
            ),
          ],
        );
      },
    );
  }
}
