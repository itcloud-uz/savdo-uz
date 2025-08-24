import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/sale_model.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/widgets/loader_widget.dart';
import 'package:savdo_uz/widgets/empty_state_widget.dart';
import 'package:savdo_uz/widgets/error_retry_widget.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class CustomerReportScreen extends StatefulWidget {
  const CustomerReportScreen({super.key});

  @override
  State<CustomerReportScreen> createState() => _CustomerReportScreenState();
}

class _CustomerReportScreenState extends State<CustomerReportScreen> {
  Future<void> _shareFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: 'Hisobot fayli');
  }

  Future<void> _exportToExcel() async {
    final sortedEntries = _customerDebts.entries.toList();
    sortedEntries.sort((a, b) => b.value.compareTo(a.value));
    final excel = Excel.createExcel();
    final sheet = excel['MijozlarHisoboti'];
    sheet.appendRow([
      TextCellValue('№'),
      TextCellValue('Mijoz'),
      TextCellValue('Savdo'),
      TextCellValue('Qarzi'),
    ]);
    for (int i = 0; i < sortedEntries.length; i++) {
      final e = sortedEntries[i];
      final salesAmount = _customerSales[e.key] ?? 0;
      sheet.appendRow([
        TextCellValue('${i + 1}'),
        TextCellValue(e.key),
        TextCellValue(salesAmount.toStringAsFixed(0)),
        TextCellValue(e.value.toStringAsFixed(0)),
      ]);
    }
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/mijozlar_hisoboti.xlsx');
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

  Future<void> _exportToCsv() async {
    final sortedEntries = _customerDebts.entries.toList();
    sortedEntries.sort((a, b) => b.value.compareTo(a.value));
    final buffer = StringBuffer();
    buffer.writeln('№,Mijoz,Savdo,Qarzi');
    for (int i = 0; i < sortedEntries.length; i++) {
      final e = sortedEntries[i];
      final salesAmount = _customerSales[e.key] ?? 0;
      buffer.writeln(
          '${i + 1},${e.key},${salesAmount.toStringAsFixed(0)},${e.value.toStringAsFixed(0)}');
    }
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/mijozlar_hisoboti.csv');
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

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();
    final sortedEntries = _customerDebts.entries.toList();
    sortedEntries.sort((a, b) => b.value.compareTo(a.value));
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Mijozlar Hisoboti',
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
                      pw.Text('Mijoz',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Savdo',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Qarzi',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  ...List.generate(sortedEntries.length, (index) {
                    final e = sortedEntries[index];
                    final salesAmount = _customerSales[e.key] ?? 0;
                    return pw.TableRow(
                      children: [
                        pw.Text('${index + 1}'),
                        pw.Text(e.key),
                        pw.Text('${salesAmount.toStringAsFixed(0)} soʼm'),
                        pw.Text('${e.value.toStringAsFixed(0)} soʼm'),
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
    final filePath = '${directory.path}/mijozlar_hisoboti.pdf';
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

  bool _isLoading = false;
  String? _errorMessage;
  // Removed unused _salesData field
  Map<String, double> _customerSales = {};
  Map<String, double> _customerDebts = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final firestoreService = context.read<FirestoreService>();
    try {
      final sales = await firestoreService.getAllSales();
      final customers = await firestoreService.getCustomers().first;
      setState(() {
        _customerSales = _calculateCustomerSales(sales);
        _customerDebts = {for (var c in customers) c.name: c.debt};
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Xatolik: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, double> _calculateCustomerSales(List<Sale> sales) {
    final Map<String, double> result = {};
    for (var sale in sales) {
      if (sale.customerName != null && sale.customerName!.isNotEmpty) {
        result[sale.customerName!] =
            (result[sale.customerName!] ?? 0) + sale.totalAmount;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mijozlar Hisoboti'),
        actions: [
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
                  errorMessage: _errorMessage!, onRetry: _loadData)
              : _customerSales.isEmpty
                  ? const EmptyStateWidget(
                      message: 'Maʼlumot topilmadi.',
                      icon: Icons.people_outline)
                  : _buildReportBody(),
    );
  }

  Widget _buildReportBody() {
    // Eng ko'p qarz olgan mijozlar yuqorida chiqadi
    final sorted = _customerDebts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final entry = sorted[index];
        final salesAmount = _customerSales[entry.key] ?? 0;
        return ListTile(
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text(entry.key),
          subtitle: Text('Savdo: ${salesAmount.toStringAsFixed(0)} soʼm'),
          trailing: Text('Qarzi: ${entry.value.toStringAsFixed(0)} soʼm',
              style: TextStyle(
                  color: entry.value > 0 ? Colors.red : Colors.green)),
        );
      },
    );
  }
}
