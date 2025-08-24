import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/sale_model.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart';
import 'package:share_plus/share_plus.dart';
import 'package:savdo_uz/widgets/loader_widget.dart';
import 'package:savdo_uz/widgets/empty_state_widget.dart';
import 'package:savdo_uz/widgets/accessible_icon_button.dart';
import 'package:savdo_uz/widgets/error_retry_widget.dart';
import 'package:savdo_uz/screens/reports/add_sales_report_screen.dart';

class SalesReportScreen extends StatefulWidget {
  const SalesReportScreen({super.key});

  @override
  State<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends State<SalesReportScreen> {
  Future<void> _shareFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: 'Hisobot fayli');
  }

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();
    final sorted = _salesData ?? [];
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Savdo Hisoboti',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Text('№',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Sana',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Summa',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  ...List.generate(sorted.length, (index) {
                    final sale = sorted[index];
                    return pw.TableRow(
                      children: [
                        pw.Text('${index + 1}'),
                        pw.Text(
                            DateFormat('dd.MM.yyyy').format(sale.timestamp)),
                        pw.Text('${sale.totalAmount.toStringAsFixed(0)} soʼm'),
                      ],
                    );
                  }),
                ],
              ),
            ],
          );
        },
      ),
    );
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/savdo_hisoboti.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF fayl saqlandi: $filePath'),
        action: SnackBarAction(
          label: 'Ulashish',
          onPressed: () => _shareFile(filePath),
        ),
      ),
    );
  }

  Future<void> _exportToCsv() async {
    final sorted = _salesData ?? [];
    final buffer = StringBuffer();
    buffer.writeln('№,Sana,Summa');
    for (int i = 0; i < sorted.length; i++) {
      final sale = sorted[i];
      buffer.writeln(
          '${i + 1},${DateFormat('dd.MM.yyyy').format(sale.timestamp)},${sale.totalAmount.toStringAsFixed(0)}');
    }
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/savdo_hisoboti.csv');
    await file.writeAsString(buffer.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV fayl saqlandi: ${file.path}'),
        action: SnackBarAction(
          label: 'Ulashish',
          onPressed: () => _shareFile(file.path),
        ),
      ),
    );
  }

  Future<void> _exportToExcel() async {
    final sorted = _salesData ?? [];
    final excel = Excel.createExcel();
    final sheet = excel['SavdoHisoboti'];
    sheet.appendRow([
      TextCellValue('№'),
      TextCellValue('Sana'),
      TextCellValue('Summa'),
    ]);
    for (int i = 0; i < sorted.length; i++) {
      final sale = sorted[i];
      sheet.appendRow([
        TextCellValue('${i + 1}'),
        TextCellValue(DateFormat('dd.MM.yyyy').format(sale.timestamp)),
        TextCellValue(sale.totalAmount.toStringAsFixed(0)),
      ]);
    }
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/savdo_hisoboti.xlsx');
    await file.writeAsBytes(excel.encode()!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Excel fayl saqlandi: ${file.path}'),
        action: SnackBarAction(
          label: 'Ulashish',
          onPressed: () => _shareFile(file.path),
        ),
      ),
    );
  }

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  List<Sale>? _salesData;
  bool _isLoading = false;
  String? _errorMessage;

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
      _errorMessage = null;
    });
    final firestoreService = context.read<FirestoreService>();
    try {
      final sales =
          await firestoreService.getSalesBetweenDates(_startDate, _endDate);
      setState(() {
        _salesData = sales;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Xatolik: $e';
        _isLoading = false;
      });
    }
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
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'pdf') _exportToPdf();
              if (value == 'csv') _exportToCsv();
              if (value == 'excel') _exportToExcel();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Text('PDFga eksport'),
              ),
              const PopupMenuItem(
                value: 'excel',
                child: Text('Excelga eksport'),
              ),
              const PopupMenuItem(
                value: 'csv',
                child: Text('CSVga eksport'),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const LoaderWidget(message: 'Hisobot yuklanmoqda...')
          : _errorMessage != null
              ? ErrorRetryWidget(
                  errorMessage: _errorMessage!,
                  onRetry: _generateReport,
                )
              : _salesData == null || _salesData!.isEmpty
                  ? const EmptyStateWidget(
                      message: "Bu oraliqda ma'lumot topilmadi.",
                      icon: Icons.bar_chart,
                    )
                  : _buildReportBody(),
      floatingActionButton: AccessibleIconButton(
        icon: Icons.add,
        semanticLabel: 'Hisobot qo‘shish',
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddSalesReportScreen(),
              ));
        },
        color: Colors.white,
        size: 28,
      ),
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
