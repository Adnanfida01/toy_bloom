import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFFF7043);
  static const Color secondary = Color(0xFFFFF3E0);

  // Light theme colors
  static const Color lightBackground = Colors.white;
  static const Color lightSurface = Colors.white;
  static const Color lightCard = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkCard = Color(0xFF242424);

  // Common colors
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color divider = Color(0xFFEEEEEE);
  static const Color inputBorder = Color(0xFFE0E0E0);
  static const Color inputFill = Color(0xFFF5F5F5);

  static const Color background = Colors.white;
  static const Color cardBackground = Colors.white;

  static const Color splashBackground = Color(0xFFFFF3E0);
  static const Color splashAccent = Color(0xFFFF7043);

  static const Color buttonPrimary = Color(0xFFFF7043);
  static const Color buttonSecondary = Color(0xFFFFF3E0);

  static const Color promotionBanner = Color(0xFFFF7043);
}

class AppRoutes {
  static const String home = '/home';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String emailVerification = '/email-verification';
  static const String profile = '/profile';
  static const String admin = '/admin';
  static const String cart = '/cart';
  static const String notifications = '/notifications';
  static const String productDetail = '/product-detail';
}

class AppConstants {
  static const List<String> categories = [
    'Toys',
    'Kids T-shirt',
    'Blankets',
    'Baby Care',
    'Kids Shoes',
    'Kids Accessories',
    'Kids Books',
    'Kids Furniture',
  ];

  static const List<String> colors = [
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Purple',
    'Orange',
    'Black',
    'White',
    'Pink',
    'Brown',
    'Gray',
    'Navy',
    'Maroon',
    'Teal',
    'Gold'
  ];

  static const List<String> sizes = [
    'XS',
    'S',
    'M',
    'L',
    'XL',
    '2XL',
    '3XL',
    'One Size'
  ];
}
