import 'package:flutter/material.dart';
import 'package:savdo_uz/screens/reports/sales_report_screen.dart';
import 'package:savdo_uz/screens/reports/product_report_screen.dart';
import 'package:savdo_uz/screens/reports/customer_report_screen.dart';
import 'package:savdo_uz/screens/reports/employee_report_screen.dart';
import 'package:savdo_uz/screens/reports/expense_report_screen.dart';
import 'package:savdo_uz/screens/reports/debt_report_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hisobotlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(4.0),
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
                  builder: (context) => const SalesReportScreen(),
                ),
              );
            },
          ),
          _buildReportCard(
            context,
            title: 'Mahsulotlar Hisoboti',
            subtitle: 'Eng ko\'p va kam sotilgan mahsulotlar',
            icon: Icons.inventory_2_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProductReportScreen(),
                ),
              );
            },
          ),
          _buildReportCard(
            context,
            title: 'Mijozlar Hisoboti',
            subtitle: 'Eng faol va eng ko\'p qarz olgan mijozlar',
            icon: Icons.people_outline,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomerReportScreen(),
                ),
              );
            },
          ),
          _buildReportCard(
            context,
            title: 'Xodimlar Hisoboti',
            subtitle: 'Xodimlar statistikasi va eksport',
            icon: Icons.badge_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmployeeReportScreen(),
                ),
              );
            },
          ),
          _buildReportCard(
            context,
            title: 'Xarajatlar Hisoboti',
            subtitle: 'Xarajatlar statistikasi va eksport',
            icon: Icons.money_off,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExpenseReportScreen(),
                ),
              );
            },
          ),
          _buildReportCard(
            context,
            title: 'Qarzdorlik Hisoboti',
            subtitle: 'Qarzdorlik statistikasi va eksport',
            icon: Icons.assignment_late_outlined,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DebtReportScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        leading: CircleAvatar(
          radius: 16,
          backgroundColor:
              Theme.of(context).primaryColor.withValues(alpha: 0.1),
          child: Icon(icon, color: Theme.of(context).primaryColor, size: 18),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 18),
        onTap: onTap,
      ),
    );
  }
}
