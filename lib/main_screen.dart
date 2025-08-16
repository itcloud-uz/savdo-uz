import 'package:flutter/material.dart';
import 'package:savdo_uz/dashboard_screen.dart';
import 'package:savdo_uz/pos_screen.dart';
import 'package:savdo_uz/stock_receive_screen.dart';
import 'package:savdo_uz/employees_screen.dart';
import 'package:savdo_uz/stock_transfer_screen.dart';
import 'package:savdo_uz/inventory_screen.dart';
import 'package:savdo_uz/reports_screen.dart';
import 'package:savdo_uz/login_screen.dart';

class AppPage {
  final String title;
  final IconData icon;
  final Widget page;
  final List<String> roles;

  AppPage(
      {required this.title,
      required this.icon,
      required this.page,
      required this.roles});
}

class MainScreen extends StatefulWidget {
  final String userRole;
  const MainScreen({super.key, required this.userRole});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  late List<AppPage> _visiblePages;

  final List<AppPage> _allPages = [
    AppPage(
        title: 'Boshqaruv paneli',
        icon: Icons.dashboard_outlined,
        page: const DashboardScreen(),
        roles: ['Admin', 'Sotuvchi', 'Omborchi']),
    AppPage(
        title: 'Savdo Nuqtasi (POS)',
        icon: Icons.shopping_basket_outlined,
        page: const PosScreen(),
        roles: ['Admin', 'Sotuvchi']),
    AppPage(
        title: 'Mahsulot qabuli',
        icon: Icons.archive_outlined,
        page: const StockReceiveScreen(),
        roles: ['Admin', 'Omborchi']),
    AppPage(
        title: 'Do\'konga o\'tkazish',
        icon: Icons.arrow_right_alt,
        page: const StockTransferScreen(),
        roles: ['Admin', 'Omborchi']),
    AppPage(
        title: 'Qoldiqlar',
        icon: Icons.inventory_2_outlined,
        page: const InventoryScreen(),
        roles: ['Admin', 'Omborchi', 'Sotuvchi']),
    AppPage(
        title: 'Xodimlar',
        icon: Icons.people_outline,
        page: const EmployeesScreen(),
        roles: ['Admin']),
    AppPage(
        title: 'Hisobotlar',
        icon: Icons.bar_chart_outlined,
        page: const ReportsScreen(),
        roles: ['Admin']),
  ];

  @override
  void initState() {
    super.initState();
    _visiblePages =
        _allPages.where((p) => p.roles.contains(widget.userRole)).toList();
    _selectedIndex = 0;
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context);
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_visiblePages.isEmpty) {
      return const Scaffold(
          body: Center(child: Text('Bu rol uchun sahifalar mavjud emas')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_visiblePages[_selectedIndex].title),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Text(widget.userRole.substring(0, 1))),
                const SizedBox(width: 8),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Foydalanuvchi',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.userRole,
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Row(children: [
                Icon(Icons.shopping_cart_rounded,
                    color: Colors.white, size: 40),
                SizedBox(width: 16),
                Text('Savdo.uz',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
            ..._visiblePages.asMap().entries.map((entry) {
              int index = entry.key;
              AppPage page = entry.value;
              return _buildDrawerItem(
                  icon: page.icon,
                  title: page.title,
                  index: index,
                  onTap: () => _onItemTapped(index));
            }),
            const Divider(),
            _buildDrawerItem(
                icon: Icons.logout,
                title: 'Chiqish',
                index: 99,
                onTap: _logout),
          ],
        ),
      ),
      body: _visiblePages[_selectedIndex].page,
    );
  }

  Widget _buildDrawerItem(
      {required IconData icon,
      required String title,
      required int index,
      required VoidCallback onTap}) {
    final bool isSelected = _selectedIndex == index;
    return ListTile(
      leading: Icon(icon, color: isSelected ? Colors.blue : Colors.grey[700]),
      title: Text(title,
          style: TextStyle(
              color: isSelected ? Colors.blue : Colors.black87,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      tileColor: isSelected ? Colors.blue.withAlpha(25) : null,
      onTap: onTap,
    );
  }
}
