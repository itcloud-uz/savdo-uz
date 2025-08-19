import 'package:firebase_auth/firebase_auth.dart'
    hide AuthProvider; // <-- 'AuthProvider' yashirildi
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/sale_model.dart';
import 'package:savdo_uz/providers/auth_provider.dart'; // <-- Bizning AuthProvider'imiz
import 'package:savdo_uz/screens/attendance/attendance_screen.dart';
import 'package:savdo_uz/screens/debt/debt_ledger_screen.dart';
import 'package:savdo_uz/screens/expenses/expenses_screen.dart';
import 'package:savdo_uz/screens/pos/pos_screen.dart';
import 'package:savdo_uz/screens/inventory/inventory_screen.dart';
import 'package:savdo_uz/screens/customer/customers_screen.dart';
import 'package:savdo_uz/screens/employee/employees_screen.dart';
import 'package:savdo_uz/screens/reports/reports_screen.dart';
import 'package:savdo_uz/services/firestore_service.dart';

// Tezkor amallar uchun model
class _QuickAction {
  final IconData icon;
  final String label;
  final Widget screen;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.screen,
  });
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Tezkor amallar ro'yxati
  final List<_QuickAction> _quickActions = [
    const _QuickAction(
        icon: Icons.point_of_sale_outlined,
        label: 'Kassa',
        screen: POSScreen()),
    const _QuickAction(
        icon: Icons.inventory_2_outlined,
        label: 'Omborxona',
        screen: InventoryScreen()),
    const _QuickAction(
        icon: Icons.people_outline,
        label: 'Mijozlar',
        screen: CustomersScreen()),
    const _QuickAction(
        icon: Icons.book_outlined,
        label: 'Qarz Daftari',
        screen: DebtLedgerScreen()),
    const _QuickAction(
        icon: Icons.request_quote_outlined,
        label: 'Xarajatlar',
        screen: ExpensesScreen()),
    const _QuickAction(
        icon: Icons.co_present_outlined,
        label: 'Davomat',
        screen: AttendanceScreen()),
    const _QuickAction(
        icon: Icons.group_outlined,
        label: 'Xodimlar',
        screen: EmployeesScreen()),
    const _QuickAction(
        icon: Icons.bar_chart_outlined,
        label: 'Hisobotlar',
        screen: ReportsScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    // Servis va Provayderlarni Provider orqali olamiz
    final firestoreService = context.read<FirestoreService>();
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Boshqaruv Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Chiqish',
            onPressed: () async {
              await authProvider.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingCard(currentUser),
            const SizedBox(height: 24),
            _buildSectionTitle('Umumiy Holat'),
            const SizedBox(height: 12),
            _buildSummaryCards(firestoreService),
            const SizedBox(height: 24),
            _buildSectionTitle('Tezkor Amallar'),
            const SizedBox(height: 12),
            _buildQuickActionsGrid(),
            const SizedBox(height: 24),
            _buildSectionTitle("So'nggi Sotuvlar"),
            const SizedBox(height: 12),
            _buildRecentSalesList(firestoreService),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingCard(User? user) {
    return Card(
      elevation: 0,
      color: Theme.of(context).primaryColor.withValues(0.05),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.person_pin, size: 40, color: Colors.blueGrey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Xush kelibsiz!',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    user?.email ??
                        'Foydalanuvchi', // Bu yerda ?? operatori o'rinli
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }

  Widget _buildQuickActionsGrid() {
    int crossAxisCount = (MediaQuery.of(context).size.width / 180).floor();
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount < 2 ? 2 : crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: _quickActions.length,
      itemBuilder: (context, index) {
        final action = _quickActions[index];
        return ActionCard(
          icon: action.icon,
          label: action.label,
          onTap: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => action.screen));
          },
        );
      },
    );
  }

  Widget _buildSummaryCards(FirestoreService firestoreService) {
    return StreamBuilder<List<Sale>>(
      stream: firestoreService.getSalesForToday(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Row(children: [
            Expanded(child: SummaryCard.loading()),
            SizedBox(width: 12),
            Expanded(child: SummaryCard.loading())
          ]);
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Ma'lumotlarni yuklashda xatolik"));
        }
        double totalSales = 0.0;
        int salesCount = 0;
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final sales = snapshot.data!;
          totalSales =
              sales.fold<double>(0.0, (sum, sale) => sum + sale.totalAmount);
          salesCount = sales.length;
        }
        return Row(
          children: [
            Expanded(
              child: SummaryCard(
                title: 'Bugungi Savdo',
                value: formatCurrency(totalSales),
                unit: "so'm",
                icon: Icons.trending_up,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SummaryCard(
                title: 'Sotuvlar Soni',
                value: salesCount.toString(),
                unit: 'ta',
                icon: Icons.receipt_long,
                color: Colors.orange,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentSalesList(FirestoreService firestoreService) {
    return StreamBuilder<List<Sale>>(
      stream: firestoreService.getRecentSales(limit: 5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Ma'lumotlarni yuklashda xatolik"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text("Hozircha sotuvlar mavjud emas")),
            ),
          );
        }
        final recentSales = snapshot.data!;
        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentSales.length,
            itemBuilder: (context, index) {
              final sale = recentSales[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.shopping_bag)),
                title: Text('Chek #${sale.saleId}'), // <-- ?? olib tashlandi
                subtitle: Text('${sale.items.length} ta mahsulot'),
                trailing: Text(
                  formatCurrency(sale.totalAmount),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.green),
                ),
              );
            },
            separatorBuilder: (context, index) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
          ),
        );
      },
    );
  }
}

// --- YORDAMCHI WIDGETLAR ---

class SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;
  final bool isLoading;

  const SummaryCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  }) : isLoading = false;

  const SummaryCard.loading({super.key})
      : title = '',
        value = '',
        unit = '',
        icon = Icons.hourglass_empty,
        color = Colors.grey,
        isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const SizedBox(
                height: 85, child: Center(child: CircularProgressIndicator()))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 28, color: color),
                  const SizedBox(height: 12),
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(value,
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2.0),
                        child: Text(unit,
                            style: Theme.of(context).textTheme.bodySmall),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

class ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const ActionCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(label,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// --- FORMATLANISH UCHUN FUNKSIYA ---
String formatCurrency(num amount) {
  // `intl` paketidan foydalanib, professional formatlash
  return NumberFormat.currency(locale: 'uz_UZ', symbol: '', decimalDigits: 0)
      .format(amount);
}
