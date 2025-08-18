-import 'dart.typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:fl_chart/fl_chart.dart'; // Grafiklar uchun kutubxona
import 'package:savdo_uz/services/firestore_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  // Boshlang'ich sana oralig'i: oxirgi 7 kun
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 6));
  DateTime _endDate = DateTime.now();
  bool _isPdfLoading = false;

  // Sana tanlash funksiyasi
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
          // Kunning oxirigacha bo'lgan vaqtni olish uchun
          _endDate = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Hisobotlar"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Sana oralig'ini tanlash uchun karta
          _buildDatePickerCard(),
          const SizedBox(height: 24),

          // Hisobot turlari
          _buildReportCard(
            title: "Savdo Tahlili",
            subtitle: "Tanlangan davrdagi savdo dinamikasi va jami summa.",
            icon: Icons.bar_chart_rounded,
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => SalesReportDetailScreen(
                  startDate: _startDate, endDate: _endDate),
            )),
          ),
          _buildReportCard(
            title: "PDF Hisobot Yuklash",
            subtitle: "Tanlangan davrdagi savdolar haqida PDF hujjat.",
            icon: Icons.picture_as_pdf_outlined,
            isLoading: _isPdfLoading,
            onTap: _generateAndShowPdf,
          ),
        ],
      ),
    );
  }

  // Sana tanlash vidjeti
  Widget _buildDatePickerCard() {
    final DateFormat formatter = DateFormat('dd.MM.yyyy');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Sana oralig'ini tanlang", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Boshlanish', border: OutlineInputBorder()),
                      child: Text(formatter.format(_startDate)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Tugash', border: OutlineInputBorder()),
                      child: Text(formatter.format(_endDate)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // Hisobot kartasi vidjeti
  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(child: Icon(icon)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: isLoading 
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) 
          : const Icon(Icons.arrow_forward_ios),
        onTap: isLoading ? null : onTap,
      ),
    );
  }

  // --- PDF YARATISH LOGIKASI ---
  Future<void> _generateAndShowPdf() async {
    setState(() => _isPdfLoading = true);
    try {
      final salesDocs = await _firestoreService.getSalesBetweenDates(_startDate, _endDate);
      final pdfBytes = await _createPdf(salesDocs, _startDate, _endDate);
      await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdfBytes);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("PDF yaratishda xatolik: $e")));
    } finally {
      if (mounted) setState(() => _isPdfLoading = false);
    }
  }

  Future<Uint8List> _createPdf(List<QueryDocumentSnapshot> sales, DateTime start, DateTime end) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();
    double totalSum = 0;

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      header: (context) => pw.Header(
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text('Savdo Hisoboti', style: pw.TextStyle(font: boldFont, fontSize: 20)),
            pw.Text(
              '${DateFormat('dd.MM.yy').format(start)} - ${DateFormat('dd.MM.yy').format(end)}',
              style: pw.TextStyle(font: font, fontSize: 16)
            ),
          ],
        ),
      ),
      build: (pw.Context context) {
        if (sales.isEmpty) {
          return [pw.Center(child: pw.Text("Ushbu davrda savdolar bo'lmagan."))];
        }
        final headers = ['ID', 'Sana', 'Vaqti', 'Summa'];
        final data = sales.map((doc) {
          final sale = doc.data() as Map<String, dynamic>;
          totalSum += (sale['totalAmount'] as num? ?? 0.0);
          final timestamp = (sale['timestamp'] as Timestamp).toDate();
          return [
            sale['saleId'] ?? 'N/A',
            DateFormat('dd.MM.yyyy').format(timestamp),
            DateFormat('HH:mm').format(timestamp),
            '${formatCurrency(sale['totalAmount'] as num? ?? 0)}',
          ];
        }).toList();

        return [
          pw.Table.fromTextArray(
            headers: headers,
            data: data,
            headerStyle: pw.TextStyle(font: boldFont),
            cellStyle: pw.TextStyle(font: font),
            border: pw.TableBorder.all(),
            cellAlignments: { 3: pw.Alignment.centerRight },
          ),
          pw.SizedBox(height: 20),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Jami: ${formatCurrency(totalSum)}', style: pw.TextStyle(font: boldFont, fontSize: 18)),
          ),
        ];
      },
    ));
    return pdf.save();
  }
}


// --- SAVDO TAHLILI UCHUN ALOHIDA SAHIFA ---
class SalesReportDetailScreen extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final FirestoreService _firestoreService = FirestoreService();

  SalesReportDetailScreen({
    super.key,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Savdo Tahlili"),
      ),
      body: FutureBuilder<List<QueryDocumentSnapshot>>(
        future: _firestoreService.getSalesBetweenDates(startDate, endDate),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Xatolik: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Bu davr uchun ma'lumotlar topilmadi."));
          }

          double totalRevenue = 0;
          int totalChecks = snapshot.data!.length;
          final Map<DateTime, double> dailySales = {};

          for (var doc in snapshot.data!) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['totalAmount'] as num? ?? 0.0).toDouble();
            totalRevenue += amount;
            final saleDate = (data['timestamp'] as Timestamp).toDate();
            final day = DateTime(saleDate.year, saleDate.month, saleDate.day);
            dailySales[day] = (dailySales[day] ?? 0) + amount;
          }

          final List<FlSpot> spots = dailySales.entries.map((e) {
            return FlSpot(e.key.millisecondsSinceEpoch.toDouble(), e.value);
          }).toList()..sort((a, b) => a.x.compareTo(b.x));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(child: _buildStatCard("Umumiy Savdo", formatCurrency(totalRevenue), Icons.attach_money, Colors.green)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatCard("Cheklar Soni", totalChecks.toString(), Icons.receipt, Colors.blue)),
                ],
              ),
              const SizedBox(height: 24),
              Text("Kunlik Savdo Dinamikasi", style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: LineChart(_buildChartData(spots)),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Statistik ma'lumot kartasi
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // Grafik uchun ma'lumotlar
  LineChartData _buildChartData(List<FlSpot> spots) {
    return LineChartData(
      gridData: const FlGridData(show: true),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: _calculateInterval(spots),
            getTitlesWidget: (value, meta) {
              final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(DateFormat('dd.MM').format(date), style: const TextStyle(fontSize: 12)),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (value, meta) {
              if (value == meta.max || value == meta.min) return const Text('');
              return Text("${(value / 1000).toStringAsFixed(0)}k", style: const TextStyle(fontSize: 12));
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade300)),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.3)),
        ),
      ],
    );
  }
  
  // Grafikda sanalar intervalini hisoblash
  double _calculateInterval(List<FlSpot> spots) {
    if(spots.length <= 1) return const Duration(days: 1).inMilliseconds.toDouble();
    final minDay = spots.first.x;
    final maxDay = spots.last.x;
    final difference = maxDay - minDay;
    int days = Duration(milliseconds: difference.toInt()).inDays;
    
    if (days <= 7) return const Duration(days: 1).inMilliseconds.toDouble();
    if (days <= 31) return const Duration(days: 5).inMilliseconds.toDouble();
    return const Duration(days: 30).inMilliseconds.toDouble();
  }
}