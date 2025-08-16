import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

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
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: reportContent,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('dd.MM.yyyy');
    final isLargeScreen = MediaQuery.of(context).size.width > 800;
    final int crossAxisCount = isLargeScreen ? 2 : 1;

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
          GridView.count(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildReportCard(
                context,
                title: "Umumiy Savdo Hisoboti",
                subtitle: "Tanlangan davrdagi savdo dinamikasi va jami summa.",
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
            ],
          )
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
          .orderBy('saleDate')
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
        final Map<DateTime, double> dailySales = {};

        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalRevenue += data['totalAmount'];
          final saleDate = (data['saleDate'] as Timestamp).toDate();
          final day = DateTime(saleDate.year, saleDate.month, saleDate.day);
          dailySales[day] = (dailySales[day] ?? 0) + data['totalAmount'];
        }

        final List<FlSpot> spots = dailySales.entries.map((entry) {
          return FlSpot(
              entry.key.millisecondsSinceEpoch.toDouble(), entry.value);
        }).toList();

        final currencyFormatter = NumberFormat.currency(
            locale: 'uz_UZ', symbol: "so'm", decimalDigits: 0);

        return ListView(
          children: [
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.attach_money,
                          color: Colors.green, size: 32),
                      title: const Text("Umumiy Savdo"),
                      subtitle: Text(currencyFormatter.format(totalRevenue),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.receipt,
                          color: Colors.blue, size: 32),
                      title: const Text("Cheklar Soni"),
                      subtitle: Text(totalChecks.toString(),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text("Kunlik Savdo Dinamikasi",
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: true),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 30,
                            interval: _calculateInterval(dailySales.keys),
                            // --- XATOLIK TUZATILGAN QISM ---
                            getTitlesWidget: (value, meta) {
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                  value.toInt());
                              // SideTitleWidget o'rniga to'g'ridan-to'g'ri Text vidjetini qaytaramiz
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(DateFormat('dd.MM').format(date)),
                              );
                            },
                            // --- TUZATISH TUGADI ---
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 80,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                  "${(value / 1000).toStringAsFixed(0)}k",
                                  style: const TextStyle(fontSize: 12));
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.grey.shade300)),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: Colors.blue,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color.fromRGBO(33, 150, 243, 0.3),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                currencyFormatter.format(spot.y),
                                const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
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
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text((index + 1).toString())),
                title: Text(product.key),
                trailing: Text("${product.value} dona sotilgan",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
    );
  }

  double _calculateInterval(Iterable<DateTime> dates) {
    if (dates.length <= 1) {
      return const Duration(days: 1).inMilliseconds.toDouble();
    }
    final minDate = dates.reduce((a, b) => a.isBefore(b) ? a : b);
    final maxDate = dates.reduce((a, b) => a.isAfter(b) ? a : b);
    final difference = maxDate.difference(minDate).inDays;

    if (difference <= 7) {
      return const Duration(days: 1).inMilliseconds.toDouble();
    } else if (difference <= 30) {
      return const Duration(days: 3).inMilliseconds.toDouble();
    } else {
      return const Duration(days: 7).inMilliseconds.toDouble();
    }
  }
}
