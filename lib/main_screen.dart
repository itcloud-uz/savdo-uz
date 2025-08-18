import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Barcha kerakli sahifalarni import qilamiz
import 'package:savdo_uz/attendance_screen.dart';
import 'package:savdo_uz/debt_ledger_screen.dart';
import 'package:savdo_uz/expenses_screen.dart';
import 'package:savdo_uz/login_screen.dart';
import 'package:savdo_uz/pos_screen.dart';
import 'package:savdo_uz/inventory_screen.dart';
import 'package:savdo_uz/customers_screen.dart';
import 'package:savdo_uz/employees_screen.dart';
import 'package:savdo_uz/reports_screen.dart';
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

// Tezkor amallar ro'yxati (o'zgarmas)
final List<_QuickAction> _quickActions = [
  _QuickAction(
      icon: Icons.point_of_sale_outlined, label: 'Savdo', screen: PosScreen()),
  _QuickAction(
      icon: Icons.inventory_2_outlined,
      label: 'Mahsulotlar',
      screen: InventoryScreen()),
  _QuickAction(
      icon: Icons.people_outline, label: 'Mijozlar', screen: CustomersScreen()),
  _QuickAction(
      icon: Icons.book_outlined,
      label: 'Qarz Daftari',
      screen: DebtLedgerScreen()),
  _QuickAction(
      icon: Icons.request_quote_outlined,
      label: 'Xarajatlar',
      screen: ExpensesScreen()),
  _QuickAction(
      icon: Icons.co_present_outlined,
      label: 'Davomat',
      screen: AttendanceScreen()),
  _QuickAction(
      icon: Icons.group_outlined, label: 'Xodimlar', screen: EmployeesScreen()),
  _QuickAction(
      icon: Icons.bar_chart_outlined,
      label: 'Hisobotlar',
      screen: ReportsScreen()),
];

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boshqaruv Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Chiqish',
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGreetingCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('Umumiy Holat'),
            const SizedBox(height: 12),
            _buildSummaryCards(),
            const SizedBox(height: 24),
            _buildSectionTitle('Tezkor Amallar'),
            const SizedBox(height: 12),
            _buildQuickActionsGrid(),
            const SizedBox(height: 24),
            _buildSectionTitle("So'nggi Sotuvlar"),
            const SizedBox(height: 12),
            _buildRecentSalesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGreetingCard() {
    return Card(
      elevation: 0,
      color: Theme.of(context).primaryColor.withOpacity(0.05),
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
                    _currentUser?.email ?? 'Foydalanuvchi',
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

  Widget _buildSummaryCards() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getSalesForToday(),
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
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final salesDocs = snapshot.data!.docs;
          totalSales = salesDocs.fold<double>(0.0, (currentSum, doc) {
            final data = doc.data() as Map<String, dynamic>?;
            return currentSum + (data?['totalAmount'] as num? ?? 0.0);
          });
          salesCount = salesDocs.length;
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

  Widget _buildRecentSalesList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getRecentSales(limit: 5),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Ma'lumotlarni yuklashda xatolik"));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text("Hozircha sotuvlar mavjud emas")),
            ),
          );
        }
        final recentSales = snapshot.data!.docs;
        return Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: recentSales.length,
            itemBuilder: (context, index) {
              final sale = recentSales[index].data() as Map<String, dynamic>;
              final items = sale['items'] as List? ?? [];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.shopping_bag)),
                title: Text('Chek #${sale['saleId'] ?? 'N/A'}'),
                subtitle: Text('${items.length} ta mahsulot'),
                trailing: Text(
                  formatCurrency(sale['totalAmount'] as num? ?? 0),
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
// Pul summasini formatlash uchun. O'zingizga mos qilib o'zgartiring.
// Masalan: 1200000 -> 1 200 000 so'm kabi ko'rsatish uchun.
String formatCurrency(num amount) {
  // Oddiy usulda minglik ajratish
  return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ');
}
