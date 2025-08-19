import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:savdo_uz/models/sale_model.dart';

class ReceiptScreen extends StatelessWidget {
  final Sale sale;
  const ReceiptScreen({super.key, required this.sale});

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
        locale: 'uz_UZ', symbol: 'so\'m', decimalDigits: 0);
    final dateFormatter = DateFormat('dd.MM.yyyy HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chek'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          // Bosh sahifaga qaytish
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Savdo Muvaffaqiyatli!',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green)),
            const SizedBox(height: 24),
            QrImageView(
              data:
                  'Chek ID: ${sale.saleId}\nSana: ${sale.timestamp}\nSumma: ${sale.totalAmount}',
              version: QrVersions.auto,
              size: 150.0,
            ),
            const SizedBox(height: 24),
            Text('Chek raqami: ${sale.saleId}',
                style: const TextStyle(fontSize: 16)),
            Text('Sana: ${dateFormatter.format(sale.timestamp)}',
                style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            const Divider(),
            // Sotilgan mahsulotlar ro'yxati
            ...sale.items.map((item) => ListTile(
                  title: Text(item.product.name),
                  subtitle: Text(
                      '${item.quantity} x ${currencyFormatter.format(item.product.price)}'),
                  trailing: Text(currencyFormatter.format(item.subtotal)),
                )),
            const Divider(),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Jami Summa',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              trailing: Text(
                currencyFormatter.format(sale.totalAmount),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            ListTile(
              title: const Text('To\'lov turi'),
              trailing: Text(sale.paymentType.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            if (sale.customerName != null)
              ListTile(
                title: const Text('Mijoz'),
                trailing: Text(sale.customerName!,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }
}
