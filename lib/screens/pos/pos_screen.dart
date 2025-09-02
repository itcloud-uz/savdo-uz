import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/providers/cart_provider.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:savdo_uz/screens/pos/checkout_screen.dart';
import 'package:savdo_uz/widgets/empty_state_widget.dart';

class POSScreen extends StatelessWidget {
  const POSScreen({super.key});

  Future<void> _scanBarcode(BuildContext context) async {
    try {
      String barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666',
        'Bekor qilish',
        true,
        ScanMode.BARCODE,
      );

      if (barcodeScanRes != '-1') {
        if (!context.mounted) return;

        final firestoreService = context.read<FirestoreService>();
        final product =
            await firestoreService.getProductByBarcode(barcodeScanRes);

        if (!context.mounted) return;

        if (product != null) {
          if (product.quantity > 0) {
            context.read<CartProvider>().addItem(product);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ushbu mahsulot omborda qolmagan.'),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mahsulot topilmadi.')),
          );
        }
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Skanerlashda xatolik: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final currencyFormatter = NumberFormat.currency(
        locale: 'uz_UZ', symbol: "so'm", decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kassa (POS)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Mahsulot qidirish',
            onPressed: () async {
              await showDialog(
                context: context,
                builder: (ctx) => const ProductSearchDialog(),
              );
            },
          ),
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
                ? const EmptyStateWidget(
                    message:
                        "Savat bo'sh. Mahsulot qo'shish uchun skanerlang.",
                    icon: Icons.shopping_cart_outlined,
                  )
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
                          // Mahsulot sonini o'zgartirish yoki o'chirish uchun dialog qo'shishingiz mumkin
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
            color: Colors.black.withOpacity(0.1), // ✅ withValues → withOpacity
            spreadRadius: 0,
            blurRadius: 10,
          ),
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
                    builder: (context) => const CheckoutScreen(),
                  ),
                );
              },
              child: const Text("To'lov"),
            ),
          ),
        ],
      ),
    );
  }
}

// --- Mahsulot qidirish va qo'shish dialogi ---
class ProductSearchDialog extends StatefulWidget {
  const ProductSearchDialog({super.key});

  @override
  State<ProductSearchDialog> createState() => _ProductSearchDialogState();
}

class _ProductSearchDialogState extends State<ProductSearchDialog> {
  final _searchController = TextEditingController();
  List products = [];
  bool _isLoading = false;
  String _error = '';

  Future<void> _searchProduct() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    final query = _searchController.text.trim();
    try {
      final firestoreService = context.read<FirestoreService>();
      products = await firestoreService.searchProduct(query);
    } catch (e) {
      _error = 'Xatolik: $e';
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Mahsulot qidirish yoki qo'shish"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              labelText: 'ID yoki nomi',
              suffixIcon: Icon(Icons.search),
            ),
            onSubmitted: (_) => _searchProduct(),
          ),
          const SizedBox(height: 12),
          if (_isLoading) const CircularProgressIndicator(),
          if (_error.isNotEmpty)
            Text(_error, style: const TextStyle(color: Colors.red)),
          if (products.isNotEmpty)
            SizedBox(
              height: 180,
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (ctx, i) {
                  final p = products[i];
                  return ListTile(
                    title: Text(p.name),
                    subtitle: Text('ID: ${p.id}'),
                    trailing: ElevatedButton(
                      child: const Text("Qo'shish"),
                      onPressed: () {
                        context.read<CartProvider>().addItem(p);
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          child: const Text('Yopish'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
