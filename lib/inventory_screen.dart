import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

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
        body: TabBarView(
          children: [
            // 1-varaq: Do'kon
            _buildInventoryList(shopStream, "Do'konda mahsulotlar mavjud emas"),
            // 2-varaq: Omborxona
            _buildInventoryList(
                warehouseStream, "Omborda mahsulotlar mavjud emas"),
          ],
        ),
      ),
    );
  }

  // Qoldiqlar ro'yxatini chizuvchi umumiy vidjet
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

        return ListView(
          padding: const EdgeInsets.all(8.0),
          children: snapshot.data!.docs.map((DocumentSnapshot document) {
            Map<String, dynamic> data =
                document.data()! as Map<String, dynamic>;
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  child: Text(data['name']?.substring(0, 1) ?? '?'),
                ),
                title: Text(data['name'] ?? 'Nomsiz',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                    "Narxi: ${data['sellingPrice']?.toStringAsFixed(0) ?? '0'} so'm"),
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
