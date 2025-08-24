import 'package:flutter/material.dart';

class CompanyInfoScreen extends StatelessWidget {
  const CompanyInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kompaniya Ma\'lumotlari'),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/kompaniya_haqida_malumot.jpg',
              fit: BoxFit.cover,
            ),
          ),
          const SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  leading: Icon(Icons.business),
                  title: Text('Kompaniya ITC'),
                  subtitle: Text('IT Cloud'),
                ),
                ListTile(
                  leading: Icon(Icons.location_on_outlined),
                  title: Text('Manzil'),
                  subtitle: Text('Urgut Shahri'),
                ),
                ListTile(
                  leading: Icon(Icons.phone_outlined),
                  title: Text('Telefon'),
                  subtitle: Text('+998 91 187 37 30'),
                ),
                ListTile(
                  leading: Icon(Icons.alternate_email),
                  title: Text('Email'),
                  subtitle: Text('itclouduz@gmail.com'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
