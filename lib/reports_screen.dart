import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// fl_chart kutubxonasini qo'shishimiz kerak.
// pubspec.yaml fayliga fl_chart: ^0.68.0 qo'shing.
// import 'package:fl_chart/fl_chart.dart'; // Hozircha kommentda qoldirilgan

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate =
              DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
  }

  void _showReport(String title, Widget reportContent) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: reportContent,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('dd.MM.yyyy');

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Sana oralig'ini tanlang",
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, true),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                                labelText: 'Boshlanish sanasi',
                                border: OutlineInputBorder()),
                            child: Text(formatter.format(_startDate)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context, false),
                          child: InputDecorator(
                            decoration: const InputDecoration(
                                labelText: 'Tugash sanasi',
                                border: OutlineInputBorder()),
                            child: Text(formatter.format(_endDate)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildReportCard(
            context,
            title: "Umumiy Savdo Hisoboti",
            subtitle: "Tanlangan davrdagi umumiy savdo va cheklar soni.",
            icon: Icons.receipt_long,
            onTap: () =>
                _showReport("Umumiy Savdo Hisoboti", _buildSalesReport()),
          ),
          _buildReportCard(
            context,
            title: "Mahsulotlar Hisoboti",
            subtitle: "Eng ko'p va eng kam sotilgan mahsulotlar ro'yxati.",
            icon: Icons.inventory_2_outlined,
            onTap: () =>
                _showReport("Mahsulotlar Hisoboti", _buildProductsReport()),
          ),
          _buildReportCard(
            context,
            title: "Xodimlar Hisoboti",
            subtitle: "Har bir xodimning savdo ko'rsatkichlari.",
            icon: Icons.people_outline,
            onTap: () => _showReport(
                "Xodimlar Hisoboti",
                const Center(
                    child: Text("Bu hisobot tez orada tayyor bo'ladi."))),
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(BuildContext context,
      {required String title,
      required String subtitle,
      required IconData icon,
      required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSalesReport() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('sales')
          .where('saleDate', isGreaterThanOrEqualTo: _startDate)
          .where('saleDate', isLessThanOrEqualTo: _endDate)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text("Bu davr uchun savdo ma'lumotlari topilmadi."));
        }

        double totalRevenue = 0;
        int totalChecks = snapshot.data!.docs.length;
        for (var doc in snapshot.data!.docs) {
          totalRevenue += (doc.data() as Map<String, dynamic>)['totalAmount'];
        }
        final currencyFormatter = NumberFormat.currency(
            locale: 'uz_UZ', symbol: "so'm", decimalDigits: 0);

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.attach_money,
                    color: Colors.green, size: 32),
                title: const Text("Umumiy Savdo"),
                trailing: Text(currencyFormatter.format(totalRevenue),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              ListTile(
                leading:
                    const Icon(Icons.receipt, color: Colors.blue, size: 32),
                title: const Text("Cheklar Soni"),
                trailing: Text(totalChecks.toString(),
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductsReport() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('sales')
          .where('saleDate', isGreaterThanOrEqualTo: _startDate)
          .where('saleDate', isLessThanOrEqualTo: _endDate)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
              child: Text("Bu davr uchun ma'lumotlar topilmadi."));
        }

        Map<String, int> productSales = {};
        for (var doc in snapshot.data!.docs) {
          final items = (doc.data() as Map<String, dynamic>)['items'] as List;
          for (var item in items) {
            final name = item['name'] as String;
            final quantity = (item['quantity'] as num).toInt();
            productSales[name] = (productSales[name] ?? 0) + quantity;
          }
        }
        final sortedProducts = productSales.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return ListView.builder(
          itemCount: sortedProducts.length,
          itemBuilder: (context, index) {
            final product = sortedProducts[index];
            return ListTile(
              leading: CircleAvatar(child: Text((index + 1).toString())),
              title: Text(product.key),
              trailing: Text("${product.value} dona sotilgan",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          },
        );
      },
    );
  }
}
