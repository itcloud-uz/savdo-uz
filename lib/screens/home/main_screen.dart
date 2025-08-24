import 'package:flutter/material.dart';
import 'dart:ui';
// Bu model fayli mavjudligiga ishonch hosil qiling (`lib/models/menu_item_model.dart`)
import 'package:savdo_uz/models/menu_item_model.dart';
import 'package:savdo_uz/screens/customer/customers_screen.dart';
import 'package:savdo_uz/screens/debt/debt_ledger_screen.dart';
import 'package:savdo_uz/screens/employee/employees_screen.dart';
import 'package:savdo_uz/screens/expenses/expenses_screen.dart';
import 'package:savdo_uz/screens/inventory/inventory_screen.dart';
import 'package:savdo_uz/screens/pos/pos_screen.dart';
import 'package:savdo_uz/screens/reports/reports_screen.dart';
import 'package:savdo_uz/screens/settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late final List<MenuItemModel> _menuItems;

  @override
  void initState() {
    super.initState();
    _menuItems = [
      // XATOLIK TUZATILDI: Barcha ekranlar `const` bilan to'g'ri yaratildi
      // va `onTap` uchun to'g'ri funksiyalar ishlatildi.
      MenuItemModel(
        title: 'Savdo (POS)',
        icon: Icons.point_of_sale,
        onTap: () => _navigateTo(const POSScreen()),
      ),
      MenuItemModel(
        title: 'Inventarizatsiya',
        icon: Icons.inventory_2,
        onTap: () => _navigateTo(const InventoryScreen()),
      ),
      MenuItemModel(
        title: 'Mijozlar',
        icon: Icons.people,
        onTap: () => _navigateTo(const CustomersScreen()),
      ),
      MenuItemModel(
        title: 'Xodimlar',
        icon: Icons.badge,
        onTap: () => _navigateTo(const EmployeesScreen()),
      ),
      MenuItemModel(
        title: 'Qarzlar',
        icon: Icons.money_off,
        onTap: () => _navigateTo(const DebtLedgerScreen()),
      ),
      MenuItemModel(
        title: 'Xarajatlar',
        icon: Icons.receipt_long,
        onTap: () => _navigateTo(const ExpensesScreen()),
      ),
      MenuItemModel(
        title: 'Hisobotlar',
        icon: Icons.bar_chart,
        onTap: () => _navigateTo(const ReportsScreen()),
      ),
      MenuItemModel(
        title: 'Sozlamalar',
        icon: Icons.settings,
        onTap: () => _navigateTo(const SettingsScreen()),
      ),
    ];
  }

  /// Sahifalarga xavfsiz o'tish uchun yordamchi funksiya
  void _navigateTo(Widget screen) {
    if (mounted) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Boshqaruv Paneli'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Menyular uchun orqafon rasmi va shisha/blur effekt
          Positioned.fill(
            child: Stack(
              children: [
                Image.asset(
                  'assets/images/Menyular_orqafoni.jpg',
                  fit: BoxFit.cover,
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      color: Colors.black.withOpacity(0.18),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Shaffof effekt
          Positioned.fill(
            child: Container(
              color: Theme.of(context)
                  .scaffoldBackgroundColor
                  .withAlpha((0.25 * 255).toInt()),
            ),
          ),
          // Menyu grid
          Center(
            child: GridView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 80.0),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 10.0,
                mainAxisSpacing: 10.0,
                childAspectRatio: 1.2,
              ),
              itemCount: 16, // 4x4 grid
              itemBuilder: (context, index) {
                if (index < _menuItems.length) {
                  final menuItem = _menuItems[index];
                  return GestureDetector(
                    onTap: menuItem.onTap,
                    child: Card(
                      elevation: 3.0,
                      color: Theme.of(context)
                          .cardColor
                          .withAlpha((0.85 * 255).toInt()),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              menuItem.icon,
                              size: 38,
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              menuItem.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                } else {
                  // Bo'sh kvadratlar
                  return Card(
                    elevation: 0,
                    color: Theme.of(context)
                        .cardColor
                        .withAlpha((0.3 * 255).toInt()),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
