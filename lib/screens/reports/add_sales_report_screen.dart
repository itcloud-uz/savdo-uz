import 'package:flutter/material.dart';

class AddSalesReportScreen extends StatelessWidget {
  const AddSalesReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yangi Hisobot Qo‘shish'),
      ),
      body: Center(
        child: Text(
          'Hisobot qo‘shish formasi bu yerda bo‘ladi.',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
    );
  }
}
