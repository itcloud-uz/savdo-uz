import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import 'package:savdo_uz/providers/auth_provider.dart';
import 'package:savdo_uz/providers/theme_provider.dart';
import 'package:savdo_uz/providers/locale_provider.dart';
import 'package:savdo_uz/screens/settings/about_screen.dart';
import 'package:savdo_uz/screens/settings/company_info_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tilni tanlang'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('O‘zbekcha'),
              onTap: () {
                _setLocale(context, const Locale('uz'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Русский'),
              onTap: () {
                _setLocale(context, const Locale('ru'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('English'),
              onTap: () {
                _setLocale(context, const Locale('en'));
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Türkçe'),
              onTap: () {
                _setLocale(context, const Locale('tr'));
                Navigator.pop(context);
              },
            ),
          ],
        ),
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

  void _setLocale(BuildContext context, Locale locale) {
    context.read<LocaleProvider>().setLocale(locale);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    return Consumer2<LocaleProvider, ThemeProvider>(
      builder: (context, localeProvider, themeProvider, child) {
        final textStyle = Theme.of(context).textTheme.bodyLarge;
        return Scaffold(
          appBar: AppBar(
            title: Text('Sozlamalar', style: textStyle),
          ),
          body: Stack(
            children: [
              Positioned.fill(
                child: Stack(
                  children: [
                    Image.asset(
                      'assets/images/sozlamlar.jpg',
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
              ListView(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text('Tilni tanlash', style: textStyle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLanguageDialog(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.brightness_6_outlined),
                    title: Text('Mavzu (Yorug\'/Qorong\'u)', style: textStyle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showThemeDialog(context),
                  ),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text('Dastur haqida', style: textStyle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.business),
                    title: Text('Kompaniya haqida', style: textStyle),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CompanyInfoScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.logout,
                        color: Theme.of(context).colorScheme.error),
                    title: Text(
                      'Chiqish',
                      style: textStyle?.copyWith(
                          color: Theme.of(context).colorScheme.error),
                    ),
                    onTap: () async {
                      await authProvider.signOut();
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
