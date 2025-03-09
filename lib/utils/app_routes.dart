import 'package:flutter/material.dart';
import '../models/product.dart';
import '../screens/user-panel/cart_screen.dart';
import '../screens/user-panel/home_screen.dart';
import '../screens/user-panel/login_screen.dart';
import '../screens/user-panel/product_detail_screen.dart';
import '../screens/user-panel/signup_screen.dart';
import '../screens/user-panel/splash_screen.dart';
import '../screens/user-panel/notifications_screen.dart';
import '../screens/user-panel/profile_screen.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/admin/add_product_screen.dart';
import '../screens/user-panel/forgot_password_screen.dart';
import '../screens/user-panel/email_verification_screen.dart';
import '../screens/user-panel/reset_password_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String productDetail = '/product-detail';
  static const String cart = '/cart';
  static const String notifications = '/notifications';
  static const String admin = '/admin';
  static const String addProduct = '/add-product';
  static const String profile = '/profile';
  static const String forgotPassword = '/forgot-password';
  static const String emailVerification = '/email-verification';
  static const String resetPassword = '/reset-password';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());

      case signup:
        return MaterialPageRoute(builder: (_) => const SignupScreen());

      case forgotPassword:
        return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());

      case emailVerification:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => EmailVerificationScreen(
            email: args['email'] as String,
            purpose: args['purpose'] as String,
            signupData: args['signupData'] as Map<String, dynamic>?,
          ),
        );

      case resetPassword:
        final email = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => ResetPasswordScreen(email: email),
        );

      case home:
        return MaterialPageRoute(
          builder: (context) => HomeScreen(),
        );

      case productDetail:
        final product = settings.arguments as Product;
        return MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        );

      case cart:
        return MaterialPageRoute(builder: (_) => const CartScreen());

      case notifications:
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());

      case admin:
        return MaterialPageRoute(builder: (_) => const AdminDashboard());

      case addProduct:
        return MaterialPageRoute(builder: (_) => const AddProductScreen());

      case profile:
        return MaterialPageRoute(builder: (_) => const ProfileScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(
              child: Text('Route not found!'),
            ),
          ),
        );
    }
  }
}
