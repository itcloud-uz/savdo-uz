import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:savdo_uz/models/product_model.dart';
import 'package:savdo_uz/services/firestore_service.dart';
import 'package:savdo_uz/screens/inventory/add_edit_product_screen.dart';
import 'package:savdo_uz/widgets/custom_search_bar.dart';
import 'package:savdo_uz/widgets/loading_list_tile.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = context.read<FirestoreService>();
    final currencyFormatter = NumberFormat.currency(
        locale: 'uz_UZ', symbol: 'so\'m', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Omborxona'),
      ),
      body: Column(
        children: [
          CustomSearchBar(
            controller: _searchController,
            onChanged: (query) =>
                setState(() => _searchQuery = query.toLowerCase()),
            hintText: 'Nomi yoki shtrix-kod bo\'yicha...',
          ),
          Expanded(
            child: StreamBuilder<List<Product>>(
              stream: firestoreService.getProducts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                      itemCount: 7,
                      itemBuilder: (ctx, i) => const LoadingListTile());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Xatolik: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Mahsulotlar mavjud emas.'));
                }

                final allProducts = snapshot.data!;
                final filteredProducts = allProducts.where((product) {
                  final name = product.name.toLowerCase();
                  final barcode = product.barcode;
                  return name.contains(_searchQuery) ||
                      barcode.contains(_searchQuery);
                }).toList();

                if (filteredProducts.isEmpty) {
                  return const Center(
                      child: Text('Qidiruv natijasi topilmadi.'));
                }

                return ListView.builder(
                  itemCount: filteredProducts.length,
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: ListTile(
                        title: Text(product.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Shtrix-kod: ${product.barcode}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(currencyFormatter.format(product.price)),
                            Text('${product.quantity} dona'),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AddEditProductScreen(product: product),
                              ));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddEditProductScreen(),
              ));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
