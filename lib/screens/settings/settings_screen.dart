import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/providers/auth_provider.dart';
import 'package:savdo_uz/providers/theme_provider.dart';
import 'package:savdo_uz/screens/settings/about_screen.dart';
import 'package:savdo_uz/screens/settings/company_info_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // ... (_showThemeDialog metodi o'zgarishsiz qoladi) ...

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sozlamalar'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.business_outlined),
            title: const Text('Kompaniya ma\'lumotlari'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CompanyInfoScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.brightness_6_outlined),
            title: const Text('Mavzu (Yorug\'/Qorong\'u)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showThemeDialog(context),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Dastur haqida'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading:
                Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text(
              'Chiqish',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () async {
              await authProvider.signOut();
            },
          ),
        ],
      ),
    );
  }

  void _showThemeDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mavzuni tanlang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('Tizim sozlamasi'),
              value: ThemeMode.system,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) themeProvider.setThemeMode(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Yorug\' rejim'),
              value: ThemeMode.light,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) themeProvider.setThemeMode(value);
                Navigator.pop(context);
              },
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Qorong\'u rejim'),
              value: ThemeMode.dark,
              groupValue: themeProvider.themeMode,
              onChanged: (value) {
                if (value != null) themeProvider.setThemeMode(value);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
