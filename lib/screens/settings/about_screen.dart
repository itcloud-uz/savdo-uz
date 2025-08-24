import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dastur Haqida'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/sozlamlar.jpg',
              fit: BoxFit.cover,
            ),
          ),
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Savdo-UZ',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Versiya 1.0.0'),
                  SizedBox(height: 24),
                  Text(
                    'Ushbu dastur kichik va o\'rta biznes uchun savdo, omborxona va xodimlarni boshqarishni avtomatlashtirishga mo\'ljallangan.',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  Text('\u00a9 2025. Barcha huquqlar himoyalangan.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
