// lib/screens/debt/debt_ledger_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/debt_model.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/screens/debt/add_debt_screen.dart';
import 'package:savdo_uz/screens/debt/debt_detail_screen.dart';
import 'package:savdo_uz/widgets/loading_list_tile.dart';
import 'package:savdo_uz/widgets/error_retry_widget.dart';
import 'package:savdo_uz/widgets/empty_state_widget.dart';
import 'package:savdo_uz/widgets/accessible_icon_button.dart';

class DebtLedgerScreen extends StatelessWidget {
  const DebtLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final currencyFormatter = NumberFormat.currency(
      locale: 'uz_UZ',
      symbol: 'so\'m',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Qarz Daftari'),
      ),
      body: StreamBuilder<List<Debt>>(
        stream: firestoreService.getDebts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              itemCount: 5,
              itemBuilder: (ctx, i) => const LoadingListTile(),
            );
          }
          if (snapshot.hasError) {
            return ErrorRetryWidget(
              errorMessage: 'Xatolik yuz berdi: ${snapshot.error}',
              onRetry: () => {},
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyStateWidget(
              message:
                  'Qarzlar mavjud emas. Yangi qarz qo‘shish uchun + tugmasini bosing.',
              icon: Icons.money_off,
            );
          }

          final debts = snapshot.data!;

          return ListView.builder(
            itemCount: debts.length,
            itemBuilder: (context, index) {
              final debt = debts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: debt.isPaid
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    child: Icon(
                      debt.isPaid
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: debt.isPaid ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(
                    debt.customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Sana: ${DateFormat('dd.MM.yyyy').format(debt.createdAt)}',
                  ),
                  trailing: Text(
                    currencyFormatter.format(debt.remainingAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: debt.isPaid
                          ? Colors.green
                          : (debt.remainingAmount > 0
                              ? Colors.red
                              : Colors.grey),
                      decoration: debt.isPaid
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DebtDetailScreen(debt: debt),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: AccessibleIconButton(
        icon: Icons.add,
        semanticLabel: 'Yangi qarz qo‘shish',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddDebtScreen()),
          );
        },
        color: Colors.white,
        size: 28,
      ),
    );
  }
}
