import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final double price;
  final double? originalPrice;
  final String? description;
  final String category;
  final String imageUrl;
  final double rating;
  final int reviews;
  final List<String> colors;
  final List<String> sizes;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.originalPrice,
    this.description,
    required this.category,
    required this.imageUrl,
    this.rating = 0.0,
    this.reviews = 0,
    this.colors = const [],
    this.sizes = const [],
    this.isAvailable = true,
    required this.createdAt,
    this.updatedAt,
  });

  // Create a copy of the product with optional new values
  Product copyWith({
    String? name,
    double? price,
    double? originalPrice,
    String? description,
    String? category,
    String? imageUrl,
    double? rating,
    int? reviews,
    List<String>? colors,
    List<String>? sizes,
    bool? isAvailable,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id,
      name: name ?? this.name,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      description: description ?? this.description,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      rating: rating ?? this.rating,
      reviews: reviews ?? this.reviews,
      colors: colors ?? this.colors,
      sizes: sizes ?? this.sizes,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert product to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'originalPrice': originalPrice,
      'description': description,
      'category': category,
      'imageUrl': imageUrl,
      'rating': rating,
      'reviews': reviews,
      'colors': colors,
      'sizes': sizes,
      'isAvailable': isAvailable,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  // Create a Product from a Firestore document
  factory Product.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      originalPrice: (data['originalPrice'] as num?)?.toDouble(),
      description: data['description'],
      category: data['category'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      rating: (data['rating'] ?? 0.0).toDouble(),
      reviews: (data['reviews'] ?? 0).toInt(),
      colors: List<String>.from(data['colors'] ?? []),
      sizes: List<String>.from(data['sizes'] ?? []),
      isAvailable: data['isAvailable'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
