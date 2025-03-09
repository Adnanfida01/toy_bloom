import '../models/product.dart';

class CartItem {
  final String id;
  final Product product;
  final String name;
  final int quantity;
  final String size;
  final String? color;

  CartItem({
    required this.id,
    required this.product,
    required this.name,
    required this.quantity,
    required this.size,
    this.color,
  });

  double get total => product.price * quantity;
}
