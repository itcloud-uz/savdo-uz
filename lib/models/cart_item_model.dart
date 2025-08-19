import 'package:savdo_uz/models/product_model.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.price * quantity;

  // Firestore'ga yozish uchun Map'ga o'girish
  Map<String, dynamic> toMap() {
    return {
      'productId': product.id,
      'productName': product.name,
      'price': product.price,
      'quantity': quantity,
    };
  }

  // Firestore'dan o'qish uchun Map'dan obyektga o'girish
  factory CartItem.fromMap(Map<String, dynamic> map) {
    // Bu yerda Product'ning barcha ma'lumotlari yo'q,
    // shuning uchun soddalashtirilgan Product obyekti yaratamiz.
    final tempProduct = Product(
      id: map['productId'],
      name: map['productName'],
      price: map['price'],
      barcode: '', // Sotuv tarixida shtrix-kod shart emas
      quantity: 0, // Sotuv tarixida ombordagi qoldiq shart emas
    );
    return CartItem(
      product: tempProduct,
      quantity: map['quantity'],
    );
  }
}
