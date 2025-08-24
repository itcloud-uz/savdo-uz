import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/models/employee_model.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class EmployeeReportScreen extends StatelessWidget {
  Future<void> _exportToPdf(
      BuildContext context, List<Employee> employees) async {
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
                pw.Text('Ism'),
                pw.Text('Lavozim'),
                pw.Text('Telefon'),
              ]),
              ...List.generate(employees.length, (i) {
                final e = employees[i];
                return pw.TableRow(children: [
                  pw.Text('${i + 1}'),
                  pw.Text(e.name),
                  pw.Text(e.position),
                  pw.Text(e.phone ?? '-'),
                ]);
              })
            ],
          );
        },
      ),
    );
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/xodimlar_hisoboti.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF fayl saqlandi: $filePath'),
        action: SnackBarAction(
            label: 'Ulashish',
            onPressed: () => Share.shareXFiles([XFile(filePath)],
                text: 'Xodimlar hisobot fayli')),
      ),
    );
  }

  Future<void> _exportToExcel(
      BuildContext context, List<Employee> employees) async {
    final excel = Excel.createExcel();
    final sheet = excel['XodimlarHisoboti'];
    sheet.appendRow([
      TextCellValue('№'),
      TextCellValue('Ism'),
      TextCellValue('Lavozim'),
      TextCellValue('Telefon'),
    ]);
    for (int i = 0; i < employees.length; i++) {
      final e = employees[i];
      sheet.appendRow([
        TextCellValue('${i + 1}'),
        TextCellValue(e.name),
        TextCellValue(e.position),
        TextCellValue(e.phone ?? '-'),
      ]);
    }
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/xodimlar_hisoboti.xlsx');
    await file.writeAsBytes(excel.encode()!);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Excel fayl saqlandi: ${file.path}'),
        action: SnackBarAction(
            label: 'Ulashish',
            onPressed: () => Share.shareXFiles([XFile(file.path)],
                text: 'Xodimlar hisobot fayli')),
      ),
    );
  }

  Future<void> _exportToCsv(
      BuildContext context, List<Employee> employees) async {
    final buffer = StringBuffer();
    buffer.writeln('№,Ism,Lavozim,Telefon');
    for (int i = 0; i < employees.length; i++) {
      final e = employees[i];
      buffer.writeln('${i + 1},${e.name},${e.position},${e.phone ?? '-'}');
    }
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/xodimlar_hisoboti.csv');
    await file.writeAsString(buffer.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('CSV fayl saqlandi: ${file.path}'),
        action: SnackBarAction(
            label: 'Ulashish',
            onPressed: () => Share.shareXFiles([XFile(file.path)],
                text: 'Xodimlar hisobot fayli')),
      ),
    );
  }

  const EmployeeReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xodimlar Hisoboti'),
        actions: [
          Consumer<FirestoreService>(
            builder: (context, firestore, _) {
              return StreamBuilder<List<Employee>>(
                stream: firestore.getEmployees(),
                builder: (context, snapshot) {
                  final employees = snapshot.data ?? [];
                  return PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'pdf') _exportToPdf(context, employees);
                      if (value == 'excel') _exportToExcel(context, employees);
                      if (value == 'csv') _exportToCsv(context, employees);
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
          return StreamBuilder<List<Employee>>(
            stream: firestore.getEmployees(),
            builder: (context, snapshot) {
              final employees = snapshot.data ?? [];
              if (employees.isEmpty) {
                return const Center(child: Text('Xodimlar topilmadi.'));
              }
              return ListView.builder(
                itemCount: employees.length,
                itemBuilder: (context, index) {
                  final e = employees[index];
                  return ListTile(
                    leading: CircleAvatar(child: Text('${index + 1}')),
                    title: Text(e.name),
                    subtitle: Text(e.position),
                    trailing: Text(e.phone ?? '-'),
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
