import 'package:flutter/material.dart';
import 'package:savdo_uz/customers_screen.dart';
import 'package:savdo_uz/employees_screen.dart';
import 'package:savdo_uz/face_scan_screen.dart';
import 'package:savdo_uz/inventory_screen.dart';
import 'package:savdo_uz/pos_screen.dart';
import 'package:savdo_uz/reports_screen.dart';
import 'package:savdo_uz/stock_receive_screen.dart';
import 'package:savdo_uz/stock_transfer_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:savdo_uz/login_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  // --- YANGI, QAYTA ISHLANADIGAN WIDGET ---
  Widget _buildDashboardItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Theme.of(context).primaryColor),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boshqaruv Paneli'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        // --- YANGILANGAN GRIDVIEW DIZAYNI ---
        child: GridView.count(
          crossAxisCount: 2, // Ustunlar soni
          crossAxisSpacing: 12, // Gorizontal oraliq
          mainAxisSpacing: 12, // Vertikal oraliq
          childAspectRatio: 1.1, // Elementlarning bo'yi va eni nisbati
          children: [
            _buildDashboardItem(
              context: context,
              icon: Icons.point_of_sale,
              label: 'Savdo',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const POSScreen())),
            ),
            _buildDashboardItem(
              context: context,
              icon: Icons.inventory_2,
              label: 'Omborxona',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const InventoryScreen())),
            ),
            _buildDashboardItem(
              context: context,
              icon: Icons.group,
              label: 'Xodimlar',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const EmployeesScreen())),
            ),
            _buildDashboardItem(
              context: context,
              icon: Icons.bar_chart,
              label: 'Hisobotlar',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const ReportsScreen())),
            ),
            _buildDashboardItem(
              context: context,
              icon: Icons.face,
              label: 'Yuzni Skanerlash',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const FaceScanScreen())),
            ),
            _buildDashboardItem(
              context: context,
              icon: Icons.people_alt,
              label: 'Mijozlar',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CustomersScreen())),
            ),
            _buildDashboardItem(
              context: context,
              icon: Icons.call_received,
              label: 'Mahsulot Qabul',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const StockReceiveScreen())),
            ),
            _buildDashboardItem(
              context: context,
              icon: Icons.send_to_mobile,
              label: 'Mahsulot O\'tkazish',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const StockTransferScreen())),
            ),
          ],
        ),
      ),
    );
  }
}
