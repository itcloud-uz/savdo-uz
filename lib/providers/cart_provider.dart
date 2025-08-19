// Kassa (POS) savatini boshqarish uchun provayder.
import 'package:flutter/material.dart';
import 'package:savdo_uz/models/cart_item_model.dart';
import 'package:savdo_uz/models/product_model.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => [..._items];

  int get itemCount => _items.length;

  double get totalPrice {
    return _items.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  void addItem(Product product) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index != -1) {
      _items[index].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int newQuantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index != -1) {
      if (newQuantity > 0) {
        _items[index].quantity = newQuantity;
      } else {
        removeItem(productId);
      }
    }
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
