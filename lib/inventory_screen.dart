import 'package:flutter/material.dart';
import 'package:savdo_uz/barcode_scanner_screen.dart'; // Yangi skaner sahifasini import qilamiz

// TODO: Bu sahifani Firestore bilan bog'lash kerak bo'ladi. Hozircha dizayn va mantiq tayyor.

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // Qidiruv uchun TextEditingController
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  // Skaner sahifasini ochish va natijani olish
  Future<void> _scanBarcode() async {
    // Skaner sahifasiga o'tamiz va natijani (shtrix-kodni) kutamiz
    final String? barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );

    if (barcode != null && barcode.isNotEmpty) {
      // Skanerlangan kodni qidiruv maydoniga joylaymiz va qidiruvni boshlaymiz
      setState(() {
        _searchController.text = barcode;
        _searchQuery = barcode;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Qidiruv maydonidagi o'zgarishlarni kuzatib boramiz
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
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
    // TODO: Bu ro'yxatni Firestore'dan olingan haqiqiy mahsulotlar bilan almashtiring
    final List<Map<String, String>> allProducts = [
      {'name': 'Non', 'barcode': '1234567890123', 'quantity': '50 dona'},
      {'name': 'Sut (1L)', 'barcode': '9876543210987', 'quantity': '30 dona'},
      {
        'name': 'Coca-Cola (1.5L)',
        'barcode': '5432109876543',
        'quantity': '100 dona'
      },
    ];

    // Qidiruv natijasiga ko'ra mahsulotlarni filtrlash
    final List<Map<String, String>> filteredProducts = _searchQuery.isEmpty
        ? allProducts
        : allProducts.where((product) {
            final nameLower = product['name']!.toLowerCase();
            final barcodeLower = product['barcode']!.toLowerCase();
            final queryLower = _searchQuery.toLowerCase();
            return nameLower.contains(queryLower) ||
                barcodeLower.contains(queryLower);
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Omborxona (Mahsulotlar)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Yangi mahsulot qo\'shish',
            onPressed: () {
              // TODO: Yangi mahsulot qo'shish logikasi
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Qidiruv va Skanerlash paneli
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Nomi yoki shtrix-kod bo\'yicha qidirish',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      // Qidiruv maydonini tozalash tugmasi
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Skanerlash tugmasi
                IconButton.filled(
                  iconSize: 30,
                  icon: const Icon(Icons.qr_code_scanner),
                  onPressed: _scanBarcode,
                  tooltip: 'Shtrix-kodni skanerlash',
                ),
              ],
            ),
          ),

          // Mahsulotlar ro'yxati
          Expanded(
            child: filteredProducts.isEmpty
                ? const Center(child: Text("Mahsulotlar topilmadi."))
                : ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        child: ListTile(
                          leading: const CircleAvatar(
                              child: Icon(Icons.inventory_2_outlined)),
                          title: Text(product['name']!),
                          subtitle: Text("Shtrix-kod: ${product['barcode']!}"),
                          trailing: Text(
                            product['quantity']!,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
