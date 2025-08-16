import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Qidiruv funksiyasi uchun StatefulWidget'ga o'zgartirdik
class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  // --- QIDIRUV UCHUN YANGI QO'SHIMCHALAR ---
  final _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
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
  // --- QIDIRUV QISMI TUGADI ---

  @override
  Widget build(BuildContext context) {
    // Ombordagi mahsulotlar uchun stream
    final Stream<QuerySnapshot> warehouseStream =
        FirebaseFirestore.instance.collection('products').snapshots();
    // Do'kondagi mahsulotlar uchun stream
    final Stream<QuerySnapshot> shopStream =
        FirebaseFirestore.instance.collection('shop_stock').snapshots();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 1,
          title: const TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: "Do'kon Qoldig'i"),
              Tab(text: "Ombor Qoldig'i"),
            ],
          ),
        ),
        // Qidiruv maydonini va TabBarView'ni Column'ga o'radik
        body: Column(
          children: [
            // --- YANGI QIDIRUV MAYDONI ---
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Mahsulotni qidirish...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                ),
              ),
            ),
            // --- QIDIRUV MAYDONI TUGADI ---
            Expanded(
              child: TabBarView(
                children: [
                  _buildInventoryList(
                      shopStream, "Do'konda mahsulotlar mavjud emas"),
                  _buildInventoryList(
                      warehouseStream, "Omborda mahsulotlar mavjud emas"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Qoldiqlar ro'yxatini chizuvchi umumiy vidjet (qidiruv mantig'i bilan)
  Widget _buildInventoryList(
      Stream<QuerySnapshot> stream, String emptyMessage) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Xatolik yuz berdi'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.data!.docs.isEmpty) {
          return Center(child: Text(emptyMessage));
        }

        // --- QIDIRUV BO'YICHA FILTRLASH ---
        var documents = snapshot.data!.docs;
        if (_searchQuery.isNotEmpty) {
          documents = documents.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] as String?)?.toLowerCase() ?? '';
            return name.contains(_searchQuery.toLowerCase());
          }).toList();
        }

        if (documents.isEmpty) {
          return const Center(
              child: Text("Qidiruv bo'yicha mahsulot topilmadi."));
        }
        // --- FILTRLASH TUGADI ---

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          children: documents.map((DocumentSnapshot document) {
            Map<String, dynamic> data =
                document.data()! as Map<String, dynamic>;
            // Narxni to'g'ri maydondan olish (do'kon uchun 'sellingPrice', ombor uchun 'costPrice')
            final price = data.containsKey('sellingPrice')
                ? data['sellingPrice']
                : data['costPrice'];

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(data['name']?.substring(0, 1) ?? '?'),
                ),
                title: Text(data['name'] ?? 'Nomsiz',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle:
                    Text("Narxi: ${price?.toStringAsFixed(0) ?? '0'} so'm"),
                trailing: Text(
                  "${data['quantity']} ${data['unit']}",
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
