import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/models/debt_model.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class DebtReportScreen extends StatelessWidget {
  const DebtReportScreen({super.key});

  Future<void> _exportToPdf(BuildContext context, List<Debt> debts) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(children: [
                pw.Text('№',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Mijoz'),
                pw.Text('Qarz'),
                pw.Text('Holat'),
              ]),
              ...List.generate(debts.length, (i) {
                final d = debts[i];
                return pw.TableRow(children: [
                  pw.Text('${i + 1}'),
                  pw.Text(d.customerName),
                  pw.Text(d.remainingAmount.toStringAsFixed(0)),
                  pw.Text(d.isPaid ? 'Toʻlangan' : 'Tolmagan'),
                ]);
              })
            ],
          );
        },
      ),
    );
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/qarzdorlik_hisoboti.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF fayl saqlandi: $filePath'),
        action: SnackBarAction(
            label: 'Ulashish',
            onPressed: () => Share.shareXFiles([XFile(filePath)],
                text: 'Qarzdorlik hisobot fayli')),
      ),
    );
  }

  Future<void> _exportToExcel(BuildContext context, List<Debt> debts) async {
    final excel = Excel.createExcel();
    final sheet = excel['QarzdorlikHisoboti'];
    sheet.appendRow([
      TextCellValue('№'),
      TextCellValue('Mijoz'),
      TextCellValue('Qarz'),
      TextCellValue('Holat'),
    ]);
    for (int i = 0; i < debts.length; i++) {
      final d = debts[i];
      sheet.appendRow([
        TextCellValue('${i + 1}'),
        TextCellValue(d.customerName),
        TextCellValue(d.remainingAmount.toStringAsFixed(0)),
        TextCellValue(d.isPaid ? 'Toʻlangan' : 'Tolmagan'),
      ]);
    }
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/qarzdorlik_hisoboti.xlsx');
    await file.writeAsBytes(excel.encode()!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Excel fayl saqlandi: ${file.path}'),
        action: SnackBarAction(
            label: 'Ulashish',
            onPressed: () => Share.shareXFiles([XFile(file.path)],
                text: 'Qarzdorlik hisobot fayli')),
      ),
    );
  }

  Future<void> _exportToCsv(BuildContext context, List<Debt> debts) async {
    final buffer = StringBuffer();
    buffer.writeln('№,Mijoz,Qarz,Holat');
    for (int i = 0; i < debts.length; i++) {
      final d = debts[i];
      buffer.writeln(
          '${i + 1},${d.customerName},${d.remainingAmount.toStringAsFixed(0)},${d.isPaid ? 'Toʻlangan' : 'Tolmagan'}');
    }
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/qarzdorlik_hisoboti.csv');
    await file.writeAsString(buffer.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV fayl saqlandi: ${file.path}'),
        action: SnackBarAction(
            label: 'Ulashish',
            onPressed: () => Share.shareXFiles([XFile(file.path)],
                text: 'Qarzdorlik hisobot fayli')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qarzdorlik Hisoboti'),
        actions: [
          Consumer<FirestoreService>(
            builder: (context, firestore, _) {
              return StreamBuilder<List<Debt>>(
                stream: firestore.getDebts(),
                builder: (context, snapshot) {
                  final debts = snapshot.data ?? [];
                  return PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'pdf') _exportToPdf(context, debts);
                      if (value == 'excel') _exportToExcel(context, debts);
                      if (value == 'csv') _exportToCsv(context, debts);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                          value: 'pdf', child: Text('PDFga eksport')),
                      const PopupMenuItem(
                          value: 'excel', child: Text('Excelga eksport')),
                      const PopupMenuItem(
                          value: 'csv', child: Text('CSVga eksport')),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<FirestoreService>(
        builder: (context, firestore, _) {
          return StreamBuilder<List<Debt>>(
            stream: firestore.getDebts(),
            builder: (context, snapshot) {
              final debts = snapshot.data ?? [];
              if (debts.isEmpty) {
                return const Center(child: Text('Qarzdorlik topilmadi.'));
              }
              return ListView.builder(
                itemCount: debts.length,
                itemBuilder: (context, index) {
                  final d = debts[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(d.customerName),
                    subtitle: Text(
                        'Qarz: ${d.remainingAmount.toStringAsFixed(0)} soʼm'),
                    trailing: Text(d.isPaid ? 'Toʻlangan' : 'Tolmagan',
                        style: TextStyle(
                            color: d.isPaid ? Colors.green : Colors.red)),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
