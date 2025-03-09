class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final List<String> sizes;
  final double rating; // Add this line
  final String category; // Add this line

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.sizes,
    required this.rating, // Add this line
    required this.category, // Add this line
  });

  // Update the sample products to include ratings
  static List<Product> sampleProducts = [
    Product(
      id: '1',
      name: 'Kids T-Shirt',
      description: 'Comfortable cotton t-shirt for kids',
      price: 19.99,
      imageUrl: 'https://example.com/kids-tshirt.jpg',
      sizes: ['S', 'M', 'L'],
      rating: 4.5, // Add rating
      category: 'Clothing',
    ),
    Product(
      id: '2',
      name: 'Soft Blanket',
      description: 'Cozy blanket for children',
      price: 29.99,
      imageUrl: 'https://example.com/soft-blanket.jpg',
      sizes: ['One Size'],
      rating: 4.8, // Add rating
      category: 'Home',
    ),
    // Add more sample products with ratings...
  ];
}
