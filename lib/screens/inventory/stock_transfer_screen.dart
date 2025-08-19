import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// O'tkazilayotgan mahsulot uchun model
class TransferItem {
  final DocumentSnapshot productDoc;
  double quantity;

  TransferItem({required this.productDoc, required this.quantity});
}

class StockTransferScreen extends StatefulWidget {
  const StockTransferScreen({super.key});

  @override
  State<StockTransferScreen> createState() => _StockTransferScreenState();
}

class _StockTransferScreenState extends State<StockTransferScreen> {
  final List<TransferItem> _transferList = [];
  bool _isLoading = false;

  // Miqdorni kiritish uchun oyna ochish
  Future<void> _showQuantityDialog(DocumentSnapshot productDoc) async {
    final quantityController = TextEditingController();
    final productData = productDoc.data() as Map<String, dynamic>?;
    if (productData == null) return;

    final availableQuantity =
        (productData['quantity'] as num?)?.toDouble() ?? 0.0;

    final quantity = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("${productData['name']} miqdorini kiriting"),
          content: TextField(
            controller: quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: "Mavjud: $availableQuantity ${productData['unit']}",
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Bekor qilish")),
            ElevatedButton(
              onPressed: () {
                final enteredQuantity =
                    double.tryParse(quantityController.text);
                if (enteredQuantity != null &&
                    enteredQuantity > 0 &&
                    enteredQuantity <= availableQuantity) {
                  Navigator.pop(context, enteredQuantity);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          "Noto'g'ri yoki mavjud miqdordan ko'p kiritildi!"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text("Qo'shish"),
            ),
          ],
        );
      },
    );

    if (quantity != null) {
      if (mounted) {
        setState(() {
          final existingItemIndex = _transferList
              .indexWhere((item) => item.productDoc.id == productDoc.id);
          if (existingItemIndex != -1) {
            _transferList[existingItemIndex].quantity = quantity;
          } else {
            _transferList
                .add(TransferItem(productDoc: productDoc, quantity: quantity));
          }
        });
      }
    }
  }

  // O'tkazishni tasdiqlash funksiyasi (YANGILANGAN VA XAVFSIZLANTIRILGAN)
  Future<void> _confirmTransfer() async {
    if (_isLoading) return; // Qayta-qayta bosishdan himoya
    setState(() => _isLoading = true);

    final firestore = FirebaseFirestore.instance;

    try {
      await firestore.runTransaction((transaction) async {
        for (final item in _transferList) {
          final productData = item.productDoc.data() as Map<String, dynamic>?;
          final productName = productData?['name'] ?? 'Nomsiz mahsulot';

          final warehouseDocRef =
              firestore.collection('products').doc(item.productDoc.id);
          final shopDocRef =
              firestore.collection('shop_stock').doc(item.productDoc.id);

          final warehouseSnapshot = await transaction.get(warehouseDocRef);

          if (!warehouseSnapshot.exists || warehouseSnapshot.data() == null) {
            throw Exception("$productName omborda topilmadi!");
          }

          final warehouseData = warehouseSnapshot.data()!;
          final currentWarehouseQty =
              (warehouseData['quantity'] as num?)?.toDouble() ?? 0.0;

          if (currentWarehouseQty < item.quantity) {
            throw Exception(
                "$productName mahsulotidan yetarli qoldiq yo'q (mavjud: $currentWarehouseQty)!");
          }

          // Ombordagi qoldiqni kamaytiramiz
          transaction.update(warehouseDocRef,
              {'quantity': currentWarehouseQty - item.quantity});

          // Do'kondagi qoldiqni yangilaymiz yoki yangi dokument yaratamiz
          final shopSnapshot = await transaction.get(shopDocRef);
          if (shopSnapshot.exists && shopSnapshot.data() != null) {
            final shopData = shopSnapshot.data()!;
            final currentShopQty =
                (shopData['quantity'] as num?)?.toDouble() ?? 0.0;
            transaction.update(
                shopDocRef, {'quantity': currentShopQty + item.quantity});
          } else {
            // Do'konda bu mahsulot hali yo'q, yangi dokument yaratamiz
            transaction.set(shopDocRef, {
              'name': warehouseData['name'] ?? 'Nomsiz mahsulot',
              'unit': warehouseData['unit'] ?? 'dona',
              'sellingPrice':
                  (warehouseData['sellingPrice'] as num?)?.toDouble() ?? 0.0,
              'quantity': item.quantity,
              'productId': item.productDoc.id,
              'imageUrl':
                  warehouseData['imageUrl'], // Bu 'null' bo'lishi mumkin
            });
          }
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Mahsulotlar do'konga muvaffaqiyatli o'tkazildi!"),
              backgroundColor: Colors.green),
        );
        setState(() => _transferList.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("O'tkazishda xatolik: ${e.toString()}"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildStockListPanel()),
          const VerticalDivider(width: 1),
          Expanded(child: _buildTransferListPanel()),
        ],
      ),
    );
  }

  Widget _buildStockListPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Ombordagi mahsulotlar",
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('quantity', isGreaterThan: 0)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Omborda mahsulotlar yo'q."));
                }
                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>?;
                    if (data == null) {
                      return const SizedBox.shrink();
                    }
                    final quantity =
                        (data['quantity'] as num?)?.toDouble() ?? 0.0;
                    final unit = (data['unit'] as String?) ?? 'dona';

                    return Card(
                      child: ListTile(
                        title: Text((data['name'] as String?) ?? 'Nomsiz'),
                        subtitle: Text("Qoldiq: $quantity $unit"),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline,
                              color: Colors.green),
                          onPressed: () => _showQuantityDialog(doc),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferListPanel() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text("Do'konga o'tkazish ro'yxati",
              style: Theme.of(context).textTheme.headlineSmall),
          const Divider(height: 32),
          Expanded(
            child: _transferList.isEmpty
                ? const Center(child: Text("Mahsulot tanlanmagan"))
                : ListView.builder(
                    itemCount: _transferList.length,
                    itemBuilder: (context, index) {
                      final item = _transferList[index];
                      final data =
                          item.productDoc.data() as Map<String, dynamic>?;
                      if (data == null) return const SizedBox.shrink();

                      final unit = (data['unit'] as String?) ?? 'dona';
                      return Card(
                        child: ListTile(
                          title: Text((data['name'] as String?) ?? 'Nomsiz'),
                          subtitle: Text("Miqdor: ${item.quantity} $unit"),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline,
                                color: Colors.red),
                            onPressed: () =>
                                setState(() => _transferList.removeAt(index)),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 16),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton.icon(
                  onPressed: _transferList.isEmpty || _isLoading
                      ? null
                      : _confirmTransfer,
                  icon: const Icon(Icons.check_circle),
                  label: const Text("O'tkazishni tasdiqlash"),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                )
        ],
      ),
    );
  }
}
