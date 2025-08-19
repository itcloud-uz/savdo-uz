import 'package:flutter/material.dart';
import 'package:savdo_uz/screens/reports/sales_report_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hisobotlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          _buildReportCard(
            context,
            title: 'Savdo Hisoboti',
            subtitle: 'Belgilangan vaqt oralig\'idagi sotuvlar tahlili',
            icon: Icons.bar_chart,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SalesReportScreen()),
              );
            },
          ),
          _buildReportCard(
            context,
            title: 'Mahsulotlar Hisoboti',
            subtitle: 'Eng ko\'p va kam sotilgan mahsulotlar',
            icon: Icons.inventory_2_outlined,
            onTap: () {
              // Kelajakda bu ekran ham quriladi
            },
          ),
          _buildReportCard(
            context,
            title: 'Mijozlar Hisoboti',
            subtitle: 'Eng faol va eng ko\'p qarz olgan mijozlar',
            icon: Icons.people_outline,
            onTap: () {
              // Kelajakda bu ekran ham quriladi
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
