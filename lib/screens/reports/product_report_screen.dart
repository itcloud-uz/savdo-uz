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

class ProductReportScreen extends StatefulWidget {
  const ProductReportScreen({super.key});

  @override
  State<ProductReportScreen> createState() => _ProductReportScreenState();
}

class _ProductReportScreenState extends State<ProductReportScreen> {
  Future<void> _shareFile(String filePath) async {
    await Share.shareXFiles([XFile(filePath)], text: 'Hisobot fayli');
  }

  Future<void> _exportToExcel() async {
    final sorted = _productSales.entries.toList();
    sorted.sort((a, b) => b.value.compareTo(a.value));
    final excel = Excel.createExcel();
    final sheet = excel['MahsulotlarHisoboti'];
    sheet.appendRow([
      TextCellValue('№'),
      TextCellValue('Mahsulot'),
      TextCellValue('Soni'),
    ]);
    for (int i = 0; i < sorted.length; i++) {
      final entry = sorted[i];
      sheet.appendRow([
        TextCellValue('${i + 1}'),
        TextCellValue(entry.key),
        TextCellValue(entry.value.toString()),
      ]);
    }
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/mahsulotlar_hisoboti.xlsx');
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
    final sorted = _productSales.entries.toList();
    sorted.sort((a, b) => b.value.compareTo(a.value));
    final buffer = StringBuffer();
    buffer.writeln('№,Mahsulot,Soni');
    for (int i = 0; i < sorted.length; i++) {
      final entry = sorted[i];
      buffer.writeln('${i + 1},${entry.key},${entry.value}');
    }
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/mahsulotlar_hisoboti.csv');
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
    final sorted = _productSales.entries.toList();
    sorted.sort((a, b) => b.value.compareTo(a.value));
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Mahsulotlar Hisoboti',
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
                      pw.Text('Mahsulot',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text('Soni',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  ...List.generate(sorted.length, (index) {
                    final entry = sorted[index];
                    return pw.TableRow(
                      children: [
                        pw.Text('${index + 1}'),
                        pw.Text(entry.key),
                        pw.Text('${entry.value} dona'),
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
    final filePath = '${directory.path}/mahsulotlar_hisoboti.pdf';
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
  Map<String, int> _productSales = {};

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
      setState(() {
        _productSales = _calculateProductSales(sales);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Xatolik: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, int> _calculateProductSales(List<Sale> sales) {
    final Map<String, int> result = {};
    for (var sale in sales) {
      for (var item in sale.items) {
        result[item.product.name] =
            (result[item.product.name] ?? 0) + item.quantity;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mahsulotlar Hisoboti'),
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
              : _productSales.isEmpty
                  ? const EmptyStateWidget(
                      message: 'Maʼlumot topilmadi.',
                      icon: Icons.inventory_2_outlined)
                  : _buildReportBody(),
    );
  }

  Widget _buildReportBody() {
    final sorted = _productSales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final entry = sorted[index];
        return ListTile(
          leading: CircleAvatar(child: Text('${index + 1}')),
          title: Text(entry.key),
          trailing: Text('${entry.value} dona'),
        );
      },
    );
  }
}
