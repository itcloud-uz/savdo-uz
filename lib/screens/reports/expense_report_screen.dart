import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/models/expense_model.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class ExpenseReportScreen extends StatelessWidget {
  const ExpenseReportScreen({super.key});

  Future<void> _exportToPdf(
      BuildContext context, List<Expense> expenses) async {
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
                pw.Text('Izoh'),
                pw.Text('Summa'),
                pw.Text('Sana'),
              ]),
              ...List.generate(expenses.length, (i) {
                final e = expenses[i];
                return pw.TableRow(children: [
                  pw.Text('${i + 1}'),
                  pw.Text(e.description),
                  pw.Text(e.amount.toStringAsFixed(0)),
                  pw.Text('${e.date.day}.${e.date.month}.${e.date.year}'),
                ]);
              })
            ],
          );
        },
      ),
    );
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/xarajatlar_hisoboti.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF fayl saqlandi: $filePath'),
        action: SnackBarAction(
            label: 'Ulashish',
            onPressed: () => Share.shareXFiles([XFile(filePath)],
                text: 'Xarajatlar hisobot fayli')),
      ),
    );
  }

  Future<void> _exportToExcel(
      BuildContext context, List<Expense> expenses) async {
    final excel = Excel.createExcel();
    final sheet = excel['XarajatlarHisoboti'];
    sheet.appendRow([
      TextCellValue('№'),
      TextCellValue('Izoh'),
      TextCellValue('Summa'),
      TextCellValue('Sana'),
    ]);
    for (int i = 0; i < expenses.length; i++) {
      final e = expenses[i];
      sheet.appendRow([
        TextCellValue('${i + 1}'),
        TextCellValue(e.description),
        TextCellValue(e.amount.toStringAsFixed(0)),
        TextCellValue('${e.date.day}.${e.date.month}.${e.date.year}'),
      ]);
    }
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/xarajatlar_hisoboti.xlsx');
    await file.writeAsBytes(excel.encode()!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Excel fayl saqlandi: ${file.path}'),
        action: SnackBarAction(
            label: 'Ulashish',
            onPressed: () => Share.shareXFiles([XFile(file.path)],
                text: 'Xarajatlar hisobot fayli')),
      ),
    );
  }

  Future<void> _exportToCsv(
      BuildContext context, List<Expense> expenses) async {
    final buffer = StringBuffer();
    buffer.writeln('№,Izoh,Summa,Sana');
    for (int i = 0; i < expenses.length; i++) {
      final e = expenses[i];
      buffer.writeln(
          '${i + 1},${e.description},${e.amount.toStringAsFixed(0)},${e.date.day}.${e.date.month}.${e.date.year}');
    }
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/xarajatlar_hisoboti.csv');
    await file.writeAsString(buffer.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV fayl saqlandi: ${file.path}'),
        action: SnackBarAction(
            label: 'Ulashish',
            onPressed: () => Share.shareXFiles([XFile(file.path)],
                text: 'Xarajatlar hisobot fayli')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xarajatlar Hisoboti'),
        actions: [
          Consumer<FirestoreService>(
            builder: (context, firestore, _) {
              return StreamBuilder<List<Expense>>(
                stream: firestore.getExpenses(),
                builder: (context, snapshot) {
                  final expenses = snapshot.data ?? [];
                  return PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'pdf') _exportToPdf(context, expenses);
                      if (value == 'excel') _exportToExcel(context, expenses);
                      if (value == 'csv') _exportToCsv(context, expenses);
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
          return StreamBuilder<List<Expense>>(
            stream: firestore.getExpenses(),
            builder: (context, snapshot) {
              final expenses = snapshot.data ?? [];
              if (expenses.isEmpty) {
                return const Center(child: Text('Xarajatlar topilmadi.'));
              }
              return ListView.builder(
                itemCount: expenses.length,
                itemBuilder: (context, index) {
                  final e = expenses[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(e.description),
                    subtitle: Text('${e.amount.toStringAsFixed(0)} soʼm'),
                    trailing:
                        Text('${e.date.day}.${e.date.month}.${e.date.year}'),
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
