import 'package:flutter/material.dart';
import '../models/product.dart';
import '../models/cart_item.dart';
import 'package:provider/provider.dart';
import 'notification_provider.dart';
import 'package:flutter/foundation.dart';

class CartItem {
  final Product product;
  final int quantity;
  final String size;
  final String? color;

  CartItem({
    required this.product,
    required this.quantity,
    required this.size,
    this.color,
  });

  double get total => product.price * quantity;
  String get name => product.name;
}

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    double total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.product.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(
    BuildContext context,
    Product product,
    String size,
    String? color,
  ) {
    if (_items.containsKey(product.id)) {
      // Only update quantity
      _items.update(
        product.id,
        (existingItem) => CartItem(
          product: existingItem.product,
          quantity: existingItem.quantity + 1,
          size: existingItem.size,
          color: existingItem.color,
        ),
      );
    } else {
      // Add new item
      _items.putIfAbsent(
        product.id,
        () => CartItem(
          product: product,
          quantity: 1,
          size: size,
          color: color,
        ),
      );

      // Create notification for new item added
      try {
        final notificationProvider =
            Provider.of<NotificationProvider>(context, listen: false);
        notificationProvider.addNotification(
          title: 'Added to Cart',
          message: 'You added ${product.name} to your cart',
          type: 'cart',
        );
      } catch (e) {
        print('Error creating notification: $e');
      }
    }
    notifyListeners();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        duration: Duration(seconds: 2),
        action: SnackBarAction(
          label: 'VIEW CART',
          onPressed: () {
            Navigator.of(context).pushNamed('/cart');
          },
        ),
      ),
    );
  }

  void addToCart(String productId, String name, double price, String imageUrl,
      int quantity,
      {required String size, String? color}) {
    // Create a simplified product for the cart
    final product = Product(
      id: productId,
      name: name,
      description: '',
      price: price,
      imageUrl: imageUrl,
      category: '',
      rating: 0,
      sizes: [size],
      colors: color != null ? [color] : [],
      isAvailable: true,
      createdAt: DateTime.now(),
    );

    final cartItemId =
        color != null ? '${productId}_${size}_$color' : '${productId}_$size';

    if (_items.containsKey(cartItemId)) {
      // Update existing item
      _items.update(
        cartItemId,
        (existingItem) => CartItem(
          product: existingItem.product,
          quantity: existingItem.quantity + quantity,
          size: existingItem.size,
          color: existingItem.color,
        ),
      );
    } else {
      // Add new item
      _items.putIfAbsent(
        cartItemId,
        () => CartItem(
          product: product,
          quantity: quantity,
          size: size,
          color: color,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeItemAndNotify(BuildContext context, String productId) {
    if (!_items.containsKey(productId)) return;
    
    final removedItem = _items[productId]!;
    _items.remove(productId);
    notifyListeners();

    // Show deletion notification in the current screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Product removed from cart'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );

    // Add notification to the NotificationProvider
    Provider.of<NotificationProvider>(context, listen: false).addNotification(
      title: 'Product Removed',
      message: '${removedItem.name} has been removed from your cart',
      type: 'removal',
    );
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity < 1 || !_items.containsKey(productId)) return;
    
    _items.update(
      productId,
      (existingItem) => CartItem(
        product: existingItem.product,
        quantity: newQuantity,
        size: existingItem.size,
        color: existingItem.color,
      ),
    );
    notifyListeners();
  }

  void clear() {
    _items = {};
    notifyListeners();
  }
}
