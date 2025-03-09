const admin = require('firebase-admin');

// Initialize Firebase Admin (This will use GOOGLE_APPLICATION_CREDENTIALS env var if available)
// If not, it will attempt to use the application default credentials
admin.initializeApp({
  projectId: 'e-commerce-app-firbase',
  // You can find this key in your Firebase project settings under "Service accounts"
  // You may need to create a service account with "Firebase Admin" role
  // and download the key if running this script locally
  credential: admin.credential.applicationDefault()
});

const db = admin.firestore();

// Sample products data
const products = [
  {
    name: 'Vapor Max Flyknit',
    description: 'Kids sneakers with breathable flyknit upper for maximum comfort. Perfect for active kids who love to run and play.',
    price: 89.99,
    originalPrice: 109.99,
    imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff',
    category: 'shoes',
    rating: 4.7,
    reviews: 128,
    sizes: ['US 5', 'US 6', 'US 7', 'US 8', 'US 9'],
    colors: ['Blue', 'Purple', 'Green', 'Red'],
    isAvailable: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    name: 'Kids Classic T-shirt',
    description: 'Soft cotton t-shirt for everyday wear. Comfortable fit and breathable fabric makes it perfect for playtime or casual outings.',
    price: 29.99,
    originalPrice: 34.99,
    imageUrl: 'https://images.unsplash.com/photo-1576566588028-4147f3842f27',
    category: 'kids T-shirt',
    rating: 4.5,
    reviews: 85,
    sizes: ['XS', 'S', 'M', 'L', 'XL'],
    colors: ['Blue', 'White', 'Black', 'Green'],
    isAvailable: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    name: 'Beats Solo Wireless Headphones',
    description: 'Kid-friendly wireless headphones with volume limiting technology to protect young ears. Comfortable cushions and adjustable headband.',
    price: 99.99,
    originalPrice: 129.99, 
    imageUrl: 'https://images.unsplash.com/photo-1583394838336-acd977736f90',
    category: 'accessories',
    rating: 4.8,
    reviews: 56,
    sizes: ['One Size'],
    colors: ['Black', 'Red', 'Blue', 'White'],
    isAvailable: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    name: 'Classic Analog Watch',
    description: 'Stylish analog watch for kids. Water-resistant and durable with comfortable strap. Great for teaching kids to tell time.',
    price: 45.99,
    originalPrice: null,
    imageUrl: 'https://images.unsplash.com/photo-1539874754764-5a96559165b0',
    category: 'accessories',
    rating: 4.3,
    reviews: 42,
    sizes: ['One Size'],
    colors: ['Silver', 'Gold', 'Rose Gold', 'Black'],
    isAvailable: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    name: 'Stuffed Teddy Bear',
    description: 'Super soft and huggable teddy bear. Made from premium plush fabric that\'s gentle on sensitive skin. Perfect bedtime companion.',
    price: 24.99,
    originalPrice: 29.99,
    imageUrl: 'https://images.unsplash.com/photo-1585155770447-2f66e2a397b5',
    category: 'toys',
    rating: 4.9,
    reviews: 112,
    sizes: ['Small', 'Medium', 'Large'],
    colors: ['Brown', 'White', 'Honey'],
    isAvailable: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    name: 'Cozy Kids Blanket',
    description: 'Ultra-soft micro plush blanket for children. Perfect for nap time, bedtime, or cuddling on the couch. Machine washable.',
    price: 35.99,
    originalPrice: 45.99,
    imageUrl: 'https://images.unsplash.com/photo-1596179152005-c059cbc340a0',
    category: 'blankets',
    rating: 4.6,
    reviews: 78,
    sizes: ['Small (36" x 48")', 'Medium (48" x 60")', 'Large (60" x 72")'],
    colors: ['Pink', 'Blue', 'Gray', 'Green'],
    isAvailable: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    name: 'Building Blocks Set',
    description: 'Creative building blocks for children of all ages. Enhances problem-solving skills and imagination. Compatible with major brands.',
    price: 39.99,
    originalPrice: null,
    imageUrl: 'https://images.unsplash.com/photo-1560961911-ba7ef651a56c',
    category: 'toys',
    rating: 4.7,
    reviews: 154,
    sizes: ['100 Pieces', '200 Pieces', '500 Pieces'],
    colors: ['Multi-color', 'Primary Colors', 'Pastel Colors'],
    isAvailable: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    name: 'Kids Sport Shoes',
    description: 'Durable sports shoes with non-slip soles and comfortable cushioning. Lightweight design for active children.',
    price: 59.99,
    originalPrice: 69.99,
    imageUrl: 'https://images.unsplash.com/photo-1560769629-975ec94e6a86',
    category: 'shoes',
    rating: 4.4,
    reviews: 86,
    sizes: ['US 1', 'US 2', 'US 3', 'US 4', 'US 5'],
    colors: ['Green', 'Blue', 'Red', 'Black'],
    isAvailable: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  }
];

// Function to add products to Firestore
async function addProducts() {
  try {
    // Add each product to Firestore
    for (const product of products) {
      await db.collection('products').add(product);
      console.log(`Added product: ${product.name}`);
    }
    
    console.log('All products have been added successfully');
    process.exit(0);
  } catch (error) {
    console.error('Error adding products:', error);
    process.exit(1);
  }
}

// Execute the function
addProducts(); 