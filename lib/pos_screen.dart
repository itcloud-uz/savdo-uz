import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:savdo_uz/barcode_scanner_screen.dart';
import 'package:savdo_uz/services/firestore_service.dart';

// --- Ma'lumotlar Modellari ---

class Product {
  final String id;
  final String name;
  final double price;
  final String unit;
  final String? barcode;
  final String? imageUrl;
  final num quantity;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    this.barcode,
    this.imageUrl,
    required this.quantity,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? 'Nomsiz',
      price: (data['price'] ?? 0.0).toDouble(),
      unit: data['unit'] ?? 'dona',
      barcode: data['barcode'],
      imageUrl: data['imageUrl'],
      quantity: data['quantity'] as num? ?? 0,
    );
  }
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get totalPrice => product.price * quantity;
}

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final List<CartItem> _cartItems = [];
  final _searchController = TextEditingController();
  String _searchQuery = "";
  bool _isProcessingSale = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Savat Mantiqi ---
  void _addToCart(Product product) {
    setState(() {
      final existingItem =
          _cartItems.where((item) => item.product.id == product.id).firstOrNull;
      if (existingItem != null) {
        if (existingItem.quantity < product.quantity) existingItem.quantity++;
      } else {
        if (product.quantity > 0) _cartItems.add(CartItem(product: product));
      }
    });
  }

  void _updateQuantity(CartItem item, int change) {
    setState(() {
      if (item.quantity + change > 0 &&
          item.quantity + change <= item.product.quantity) {
        item.quantity += change;
      } else if (item.quantity + change <= 0) {
        _cartItems.remove(item);
      }
    });
  }

  double _calculateTotal() {
    return _cartItems.fold(0.0, (total, item) => total + item.totalPrice);
  }

  // --- Skanerlash Mantiqi ---
  Future<void> _scanBarcodeAndAdd() async {
    final String? barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()),
    );
    if (barcode != null && barcode.isNotEmpty) {
      final productDoc = await _firestoreService.getProductByBarcode(barcode);
      if (productDoc != null && productDoc.exists) {
        _addToCart(Product.fromFirestore(productDoc));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Mahsulot (kod: $barcode) topilmadi!"),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  // --- Savdoni Yakunlash Mantiqi ---
  Future<void> _completeSale(String paymentMethod) async {
    if (_cartItems.isEmpty) return;
    setState(() => _isProcessingSale = true);

    try {
      // TODO: Savdoni FirestoreService orqali amalga oshirish kerak bo'ladi
      // Hozircha eski mantiq qoldiriladi, keyingi bosqichda servisga o'tkaziladi.
      final saleId = await _performSaleTransaction(paymentMethod);
      if (mounted) {
        _showReceiptDialog(_calculateTotal(), List.from(_cartItems), saleId);
        setState(() => _cartItems.clear());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Xatolik: $e"),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isProcessingSale = false);
    }
  }

  // VAQTINCHALIK FUNKSIYA (Keyinchalik FirestoreService'ga ko'chiriladi)
  Future<String> _performSaleTransaction(String paymentMethod) async {
    final firestore = FirebaseFirestore.instance;
    final totalAmount = _calculateTotal();
    final saleDocRef = firestore.collection('sales').doc();

    await firestore.runTransaction((transaction) async {
      for (final item in _cartItems) {
        final docRef = firestore.collection('products').doc(item.product.id);
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists)
          throw Exception("${item.product.name} topilmadi.");
        final currentQuantity = (snapshot.data()?['quantity'] as num? ?? 0);
        if (currentQuantity < item.quantity)
          throw Exception("${item.product.name} dan yetarli qoldiq yo'q.");
        transaction
            .update(docRef, {'quantity': currentQuantity - item.quantity});
      }
      transaction.set(saleDocRef, {
        'saleId': saleDocRef.id,
        'items': _cartItems
            .map((item) => {
                  'productId': item.product.id,
                  'name': item.product.name,
                  'quantity': item.quantity,
                  'price': item.product.price,
                })
            .toList(),
        'totalAmount': totalAmount,
        'paymentMethod': paymentMethod,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
    return saleDocRef.id;
  }

  // --- UI Qismi ---
  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Savdo Oynasi"),
        leading: isLargeScreen
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context)),
      ),
      body:
          isLargeScreen ? _buildLargeScreenLayout() : _buildSmallScreenLayout(),
    );
  }

  Widget _buildLargeScreenLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 3, child: _buildProductsGrid()),
        Expanded(flex: 2, child: _buildCart()),
      ],
    );
  }

  Widget _buildSmallScreenLayout() {
    return Column(
      children: [
        Expanded(flex: 6, child: _buildProductsGrid()),
        Expanded(flex: 4, child: _buildCart()),
      ],
    );
  }

  Widget _buildProductsGrid() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Mahsulotni qidirish...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchController.clear())
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.grey[200],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // SKANERLASH TUGMASI
              IconButton.filled(
                iconSize: 30,
                icon: const Icon(Icons.qr_code_scanner),
                onPressed: _scanBarcodeAndAdd,
                tooltip: 'Shtrix-kodni skanerlash',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('products')
                  .where('quantity', isGreaterThan: 0)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                var products = snapshot.data!.docs
                    .map((doc) => Product.fromFirestore(doc))
                    .toList();
                if (_searchQuery.isNotEmpty) {
                  products = products
                      .where((p) => p.name
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 150,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16),
                  itemCount: products.length,
                  itemBuilder: (context, index) =>
                      _buildProductItem(products[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCart() {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Savat",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            Expanded(
              child: _cartItems.isEmpty
                  ? const Center(
                      child: Text("Savat bo'sh",
                          style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _cartItems.length,
                      itemBuilder: (context, index) =>
                          _buildCartItem(_cartItems[index]),
                    ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Umumiy:",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(formatCurrency(_calculateTotal()),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            if (_isProcessingSale)
              const Center(child: CircularProgressIndicator())
            else
              Row(
                children: [
                  Expanded(
                      child: ElevatedButton(
                          onPressed: _cartItems.isEmpty
                              ? null
                              : () => _completeSale('Naqd'),
                          style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text("Naqd"))),
                  const SizedBox(width: 16),
                  Expanded(
                      child: ElevatedButton(
                          onPressed: _cartItems.isEmpty
                              ? null
                              : () => _completeSale('Karta'),
                          style: ElevatedButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16)),
                          child: const Text("Karta"))),
                ],
              )
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(Product product) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _addToCart(product),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: product.imageUrl ??
                    'https://placehold.co/100x100?text=${product.name.substring(0, 1)}',
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(product.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12)),
                  Text(formatCurrency(product.price),
                      style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(formatCurrency(item.product.price),
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                  onPressed: () => _updateQuantity(item, -1),
                  icon: const Icon(Icons.remove_circle_outline,
                      size: 20, color: Colors.red)),
              Text(item.quantity.toString(),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(
                  onPressed: () => _updateQuantity(item, 1),
                  icon: const Icon(Icons.add_circle_outline,
                      size: 20, color: Colors.green)),
            ],
          )
        ],
      ),
    );
  }

  void _showReceiptDialog(
      double totalAmount, List<CartItem> items, String saleId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Chek", textAlign: TextAlign.center),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...items.map((item) => ListTile(
                      title: Text(item.product.name),
                      trailing: Text(
                          "${item.quantity} x ${formatCurrency(item.product.price)}"),
                    )),
                const Divider(),
                ListTile(
                  title: const Text("Jami"),
                  trailing: Text(formatCurrency(totalAmount),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18)),
                ),
                const SizedBox(height: 16),
                QrImageView(
                    data: saleId, version: QrVersions.auto, size: 150.0),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Yopish")),
          ],
        );
      },
    );
  }
}
