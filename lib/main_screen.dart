import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:savdo_uz/login_screen.dart';
import 'package:savdo_uz/pos_screen.dart';
import 'package:savdo_uz/inventory_screen.dart';
import 'package:savdo_uz/employees_screen.dart';
import 'package:savdo_uz/reports_screen.dart';
import 'package:savdo_uz/services/firestore_service.dart'; // Yangi servisni import qilamiz

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final FirestoreService _firestoreService =
      FirestoreService(); // Servisdan nusxa olamiz

  // Chiqish funksiyasi
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
    // withOpacity() o'rniga Colors.blueGrey.withAlpha() ishlatamiz, chunki withOpacity deprecated
    final primaryColorWithOpacity =
        Theme.of(context).primaryColor.withAlpha(25); // 0.1 * 255 ≈ 25

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
            _buildGreetingCard(primaryColorWithOpacity),
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Umumiy Holat'),
            const SizedBox(height: 12),
            _buildSummaryCards(), // Bu endi dinamik bo'ladi
            const SizedBox(height: 24),
            _buildSectionTitle(context, 'Tezkor Amallar'),
            const SizedBox(height: 12),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            _buildSectionTitle(context, "So'nggi Sotuvlar"),
            const SizedBox(height: 12),
            _buildRecentSales(), // Bu ham dinamik bo'ladi
          ],
        ),
      ),
    );
  }

  // Foydalanuvchi bilan salomlashish kartasi
  Widget _buildGreetingCard(Color bgColor) {
    return Card(
      elevation: 0,
      color: bgColor,
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
                    style: Theme.of(context).textTheme.titleMedium,
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

  // Bo'lim sarlavhasi
  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall,
    );
  }

  // Asosiy bo'limlarga o'tish tugmalari
  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      {
        'icon': Icons.point_of_sale,
        'label': 'Savdo',
        'screen': const PosScreen()
      },
      {
        'icon': Icons.inventory,
        'label': 'Omborxona',
        'screen': const InventoryScreen()
      },
      {
        'icon': Icons.people,
        'label': 'Xodimlar',
        'screen': const EmployeesScreen()
      },
      {
        'icon': Icons.bar_chart,
        'label': 'Hisobotlar',
        'screen': const ReportsScreen()
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        return ActionCard(
          icon: actions[index]['icon'] as IconData,
          label: actions[index]['label'] as String,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => actions[index]['screen'] as Widget),
            );
          },
        );
      },
    );
  }

  // --- Yangilangan Dinamik Widgetlar ---

  // Umumiy holat kartalarini StreamBuilder bilan qurish
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
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Row(children: [
            Expanded(
                child: SummaryCard(
                    title: 'Bugungi Savdo',
                    value: '0',
                    unit: "so'm",
                    icon: Icons.trending_up,
                    color: Colors.green)),
            SizedBox(width: 12),
            Expanded(
                child: SummaryCard(
                    title: 'Sotuvlar Soni',
                    value: '0',
                    unit: 'ta',
                    icon: Icons.receipt_long,
                    color: Colors.orange)),
          ]);
        }

        final salesDocs = snapshot.data!.docs;

        // Bu yerda 'sum' o'rniga 'currentSum' nomini ishlatamiz
        double totalSales = salesDocs.fold<double>(0.0, (currentSum, doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return currentSum + (data?['totalAmount'] as num? ?? 0.0);
        });
        int salesCount = salesDocs.length;

        return Row(
          children: [
            Expanded(
                child: SummaryCard(
                    title: 'Bugungi Savdo',
                    value: formatCurrency(totalSales)
                        .replaceAll('so\'m', '')
                        .trim(),
                    unit: "so'm",
                    icon: Icons.trending_up,
                    color: Colors.green)),
            const SizedBox(width: 12),
            Expanded(
                child: SummaryCard(
                    title: 'Sotuvlar Soni',
                    value: salesCount.toString(),
                    unit: 'ta',
                    icon: Icons.receipt_long,
                    color: Colors.orange)),
          ],
        );
      },
    );
  }

  // Oxirgi sotuvlar ro'yxatini StreamBuilder bilan qurish
  Widget _buildRecentSales() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestoreService.getRecentSales(),
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
                  child: Center(child: Text("Hozircha sotuvlar mavjud emas"))));
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

// --- YORDAMCHI WIDGETLAR (SummaryCard'ga o'zgartirish kiritildi) ---

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
            Text(label, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}

// formatCurrency funksiyasini o'zingiz qayerdadir aniqlagan bo'lsangiz, uni ishlatishda davom eting.
// Agar yo'q bo'lsa, uni intl paketidan import qilishingiz mumkin:
// import 'package:intl/intl.dart';
// String formatCurrency(num amount) => NumberFormat.currency(locale: 'uz_UZ', symbol: 'so\'m').format(amount);
