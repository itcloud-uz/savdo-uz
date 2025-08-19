import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/providers/auth_provider.dart';
import 'package:savdo_uz/screens/dashboard/dashboard_screen.dart';
import 'package:savdo_uz/screens/inventory/inventory_screen.dart';
import 'package:savdo_uz/screens/pos/pos_screen.dart';
import 'package:savdo_uz/screens/settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Pastki menyudagi har bir bo'lim uchun ekranlar ro'yxati
  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(), // Boshqaruv paneli
    POSScreen(), // Kassa
    InventoryScreen(), // Omborxona
    SettingsScreen(), // Sozlamalar
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack ekranlar orasida o'tganda ularning holatini saqlab qoladi
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Boshqaruv',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_outlined),
            activeIcon: Icon(Icons.point_of_sale),
            label: 'Kassa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Ombor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Sozlamalar',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType
            .fixed, // Yorliqlar doim ko'rinib turishi uchun
        showUnselectedLabels: true,
      ),
    );
  }
}
