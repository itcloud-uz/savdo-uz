import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/providers/cart_provider.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:savdo_uz/screens/pos/checkout_screen.dart';

class POSScreen extends StatelessWidget {
  const POSScreen({super.key});

  Future<void> _scanBarcode(BuildContext context) async {
    try {
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#ff6666', 'Bekor qilish', true, ScanMode.BARCODE);

      if (barcodeScanRes != '-1' && context.mounted) {
        final firestoreService = context.read<FirestoreService>();
        final product =
            await firestoreService.getProductByBarcode(barcodeScanRes);
        if (product != null) {
          if (product.quantity > 0) {
            context.read<CartProvider>().addItem(product);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ushbu mahsulot omborda qolmagan.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mahsulot topilmadi.')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Skanerlashda xatolik: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final currencyFormatter = NumberFormat.currency(
        locale: 'uz_UZ', symbol: 'so\'m', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kassa (POS)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _scanBarcode(context),
            tooltip: 'Skanerlash',
          ),
          if (cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => context.read<CartProvider>().clearCart(),
              tooltip: 'Savatni tozalash',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: cart.items.isEmpty
                ? const Center(
                    child: Text(
                        'Savat bo\'sh.\nMahsulot qo\'shish uchun skanerlang.',
                        textAlign: TextAlign.center))
                : ListView.builder(
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final item = cart.items[i];
                      return ListTile(
                        leading: CircleAvatar(child: Text('${item.quantity}')),
                        title: Text(item.product.name),
                        subtitle:
                            Text(currencyFormatter.format(item.product.price)),
                        trailing: Text(
                          currencyFormatter.format(item.subtotal),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          // Mahsulot sonini o'zgartirish yoki o'chirish uchun dialog
                        },
                      );
                    },
                  ),
          ),
          if (cart.items.isNotEmpty)
            _buildCheckoutSection(context, cart, currencyFormatter),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(
      BuildContext context, CartProvider cart, NumberFormat formatter) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 0,
              blurRadius: 10)
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Jami:', style: Theme.of(context).textTheme.titleLarge),
              Text(
                formatter.format(cart.totalPrice),
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CheckoutScreen()),
                );
              },
              child: const Text('To\'lov'),
            ),
          ),
        ],
      ),
    );
  }
}
