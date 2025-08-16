import 'package:flutter/material.dart';

// Bu bizning yangi, shaxsiy Card vidjetimiz
class CustomCard extends StatelessWidget {
  final Widget child;
  const CustomCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Katta ekranlar uchun optimallashtirish
    final isLargeScreen = MediaQuery.of(context).size.width > 800;

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        // Statistik kartochkalar
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isLargeScreen ? 4 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: isLargeScreen ? 2 : 1.5,
          children: const [
            StatCard(
              title: "Bugungi Savdo",
              value: "1,250,000 so'm",
              icon: Icons.attach_money,
              color: Colors.blue,
            ),
            StatCard(
              title: "Bugungi Cheklar",
              value: "84 ta",
              icon: Icons.shopping_bag_outlined,
              color: Colors.green,
            ),
            StatCard(
              title: "Yangi Mijozlar",
              value: "12 ta",
              icon: Icons.person_add_alt_1_outlined,
              color: Colors.orange,
            ),
            StatCard(
              title: "Tugayotgan mahsulotlar",
              value: "8 ta",
              icon: Icons.warning_amber_rounded,
              color: Colors.red,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Grafika va Top mahsulotlar
        isLargeScreen
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildSalesChartCard()),
                  const SizedBox(width: 16),
                  Expanded(flex: 1, child: _buildTopProductsCard()),
                ],
              )
            : Column(
                children: [
                  _buildSalesChartCard(),
                  const SizedBox(height: 16),
                  _buildTopProductsCard(),
                ],
              )
      ],
    );
  }

  // Savdo grafigi uchun karta
  Widget _buildSalesChartCard() {
    // OGOHLANTIRISH TUZATILDI: 'const' qo'shildi
    return const CustomCard(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Haftalik Savdo Dinamikasi",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: Center(child: Text("Grafik shu yerda bo'ladi")),
            ),
          ],
        ),
      ),
    );
  }

  // Top mahsulotlar uchun karta
  Widget _buildTopProductsCard() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Top Mahsulotlar",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildTopProductItem(
                rank: 1, name: "Coca-Cola 1.5L", value: "125 ta"),
            _buildTopProductItem(
                rank: 2, name: "Non (buxanka)", value: "98 ta"),
            _buildTopProductItem(
                rank: 3, name: "Olma 'Golden'", value: "56 kg"),
          ],
        ),
      ),
    );
  }

  // Top mahsulotlar ro'yxatidagi har bir element
  Widget _buildTopProductItem(
      {required int rank, required String name, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: Colors.grey[200],
            child: Text(
              rank.toString(),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black54),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: const TextStyle(fontSize: 15))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(40),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(color: Colors.grey[600]),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
