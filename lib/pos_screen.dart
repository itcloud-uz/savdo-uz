import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// --- Ma'lumotlar Modellari ---

// Mahsulot uchun model
class Product {
  final String id;
  final String name;
  final double price;
  final String unit;
  // Mahsulot rasmi uchun (kelajakda ishlatiladi)
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.unit,
    this.imageUrl,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? 'Nomsiz',
      price: (data['sellingPrice'] ?? 0.0).toDouble(),
      unit: data['unit'] ?? 'dona',
      imageUrl: data['imageUrl'],
    );
  }
}

// Savatdagi mahsulot uchun model
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
  final List<CartItem> _cartItems = [];
  final currencyFormatter =
      NumberFormat.currency(locale: 'uz_UZ', symbol: "so'm", decimalDigits: 0);

  // --- Mantiq (Logika) ---
  void _addToCart(Product product) {
    setState(() {
      for (var item in _cartItems) {
        if (item.product.id == product.id) {
          item.quantity++;
          return;
        }
      }
      _cartItems.add(CartItem(product: product));
    });
  }

  void _updateQuantity(CartItem item, int change) {
    setState(() {
      item.quantity += change;
      if (item.quantity <= 0) {
        _cartItems.remove(item);
      }
    });
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in _cartItems) {
      total += item.totalPrice;
    }
    return total;
  }

  // --- UI (Interfeys) ---
  @override
  Widget build(BuildContext context) {
    final isLargeScreen = MediaQuery.of(context).size.width > 800;
    return isLargeScreen
        ? _buildLargeScreenLayout()
        : _buildSmallScreenLayout();
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
          TextField(
            decoration: InputDecoration(
              hintText: 'Mahsulotni qidirish...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('shop_stock')
                  .where('quantity', isGreaterThan: 0)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("Do'konda mahsulotlar mavjud emas."));
                }

                final products = snapshot.data!.docs
                    .map((doc) => Product.fromFirestore(doc))
                    .toList();

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 150,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _buildProductItem(products[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCart() {
    final total = _calculateTotal();
    return Card(
      margin: const EdgeInsets.all(16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      itemBuilder: (context, index) {
                        return _buildCartItem(_cartItems[index]);
                      },
                    ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Umumiy:",
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(currencyFormatter.format(total),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal),
                        child: const Text("Naqd"))),
                const SizedBox(width: 16),
                Expanded(
                    child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo),
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
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _addToCart(product),
        child: Column(
          children: [
            Expanded(
              child: CachedNetworkImage(
                imageUrl: product.imageUrl ??
                    'https://placehold.co/100x100/EBF4FF/3B82F6?text=${product.name.substring(0, 1)}',
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
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
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(currencyFormatter.format(product.price),
                      style: const TextStyle(color: Colors.grey)),
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
                Text(currencyFormatter.format(item.product.price),
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
}
