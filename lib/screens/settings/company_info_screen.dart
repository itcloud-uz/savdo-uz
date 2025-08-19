import 'package:flutter/material.dart';

class CompanyInfoScreen extends StatelessWidget {
  const CompanyInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kompaniya Ma\'lumotlari'),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: Icon(Icons.business),
              title: Text('Kompaniya Nomi'),
              subtitle: Text('Savdo-UZ MChJ'),
            ),
            ListTile(
              leading: Icon(Icons.location_on_outlined),
              title: Text('Manzil'),
              subtitle: Text('Toshkent shahri, Amir Temur ko\'chasi, 1-uy'),
            ),
            ListTile(
              leading: Icon(Icons.phone_outlined),
              title: Text('Telefon'),
              subtitle: Text('+998 71 234 56 78'),
            ),
            ListTile(
              leading: Icon(Icons.alternate_email),
              title: Text('Email'),
              subtitle: Text('info@savdo.uz'),
            ),
          ],
        ),
      ),
    );
  }
}
