import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/sale_model.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  List<Sale>? _salesData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _generateReport();
  }

  Future<void> _pickDateRange() async {
    final newDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (newDateRange != null) {
      setState(() {
        _startDate = newDateRange.start;
        _endDate = newDateRange.end;
      });
      _generateReport();
    }
  }

  Future<void> _generateReport() async {
    setState(() {
      _isLoading = true;
    });
    final firestoreService = context.read<FirestoreService>();
    final sales =
        await firestoreService.getSalesBetweenDates(_startDate, _endDate);
    setState(() {
      _salesData = sales;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savdo Hisoboti'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _pickDateRange,
            tooltip: 'Vaqt oralig\'ini tanlash',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _salesData == null || _salesData!.isEmpty
              ? const Center(child: Text('Bu oraliqda ma\'lumot topilmadi.'))
              : _buildReportBody(),
    );
  }

  Widget _buildReportBody() {
    final currencyFormatter = NumberFormat.currency(
        locale: 'uz_UZ', symbol: 'so\'m', decimalDigits: 0);
    double totalSales =
        _salesData!.fold(0.0, (sum, sale) => sum + sale.totalAmount);
    int salesCount = _salesData!.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${DateFormat('dd.MM.yyyy').format(_startDate)} - ${DateFormat('dd.MM.yyyy').format(_endDate)}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildSummaryCards(totalSales, salesCount, currencyFormatter),
          const SizedBox(height: 24),
          Text('Kunlik Savdo Grafikasi',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          _buildSalesChart(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(
      double totalSales, int salesCount, NumberFormat formatter) {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Umumiy Savdo',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(formatter.format(totalSales),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: Colors.green)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text('Sotuvlar Soni',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(salesCount.toString(),
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(color: Colors.blue)),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesChart() {
    // Ma'lumotlarni kunlar bo'yicha guruhlash
    Map<int, double> dailySales = {};
    for (var sale in _salesData!) {
      final day = sale.timestamp.day;
      dailySales[day] = (dailySales[day] ?? 0) + sale.totalAmount;
    }

    List<BarChartGroupData> barGroups = dailySales.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key,
        barRods: [
          BarChartRodData(toY: entry.value, color: Colors.blue, width: 16)
        ],
      );
    }).toList();

    return SizedBox(
      height: 250,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barGroups: barGroups,
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) =>
                        Text(value.toInt().toString()),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
