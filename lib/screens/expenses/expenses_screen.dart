import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// XATOLIK TUZATILDI: Import yo'li to'g'rilandi.
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/expense_model.dart';
import 'package:savdo_uz/screens/expenses/add_edit_expense_screen.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/widgets/custom_search_bar.dart';
import 'package:savdo_uz/widgets/loading_list_tile.dart';
import 'package:savdo_uz/widgets/error_retry_widget.dart';
import 'package:savdo_uz/widgets/empty_state_widget.dart';
import 'package:savdo_uz/widgets/accessible_icon_button.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchQuery = _searchController.text.toLowerCase();
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Xarajatlar'),
      ),
      body: Column(
        children: [
          CustomSearchBar(
            controller: _searchController,
            hintText: 'Xarajat tavsifi bo\'yicha qidirish...',
            // XATOLIK TUZATILDI: `onChanged` parametri qo'shildi (agar kerak bo'lsa).
            // Agar sizning `CustomSearchBar` vidjetingizda bu parametr bo'lmasa,
            // bu qatorni olib tashlashingiz mumkin. Asosiysi `addListener` ishlayapti.
            onChanged: (query) {
              // `addListener` allaqachon bu ishni qilmoqda, shuning uchun bu yerda
              // qo'shimcha kod yozish shart emas.
            },
          ),
          Expanded(
            child: StreamBuilder<List<Expense>>(
              stream: firestoreService.getExpenses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    itemCount: 5,
                    itemBuilder: (ctx, i) => const LoadingListTile(),
                  );
                }
                if (snapshot.hasError) {
                  return ErrorRetryWidget(
                    errorMessage: 'Xatolik: ${snapshot.error}',
                    onRetry: () => setState(() {}),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'Xarajatlar mavjud emas.',
                    icon: Icons.receipt_long_outlined,
                  );
                }

                final allExpenses = snapshot.data!;
                final filteredExpenses = allExpenses.where((expense) {
                  return (expense.description)
                      .toLowerCase()
                      .contains(_searchQuery);
                }).toList();

                if (filteredExpenses.isEmpty) {
                  return const EmptyStateWidget(
                    message: 'Qidiruv natijasi topilmadi.',
                    icon: Icons.search_off,
                  );
                }

                return ListView.builder(
                  itemCount: filteredExpenses.length,
                  itemBuilder: (context, index) {
                    final expense = filteredExpenses[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.receipt_long_outlined),
                        ),
                        title: Text(expense.description,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        // XATOLIK TUZATILDI: `date` maydoni endi mavjud.
                        subtitle:
                            Text(DateFormat('dd/MM/yyyy').format(expense.date)),
                        trailing: Text(
                          "${NumberFormat.currency(locale: 'uz_UZ', symbol: '', decimalDigits: 0).format(expense.amount)} so'm",
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AddEditExpenseScreen(expense: expense),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: AccessibleIconButton(
        icon: Icons.add,
        semanticLabel: 'Yangi xarajat qo‘shish',
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditExpenseScreen(),
            ),
          );
        },
        color: Colors.white,
        size: 28,
      ),
    );
  }
}
