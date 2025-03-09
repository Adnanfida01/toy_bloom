import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:toy_bloom/providers/auth_provider.dart' as auth;
import 'package:toy_bloom/providers/cart_provider.dart';
import 'package:toy_bloom/providers/notification_provider.dart';
import 'package:toy_bloom/providers/theme_provider.dart';
import 'package:toy_bloom/utils/app_constants.dart';
import 'package:toy_bloom/utils/app_routes.dart' as routes;
import 'package:toy_bloom/screens/user-panel/splash_screen.dart';
import 'package:toy_bloom/screens/user-panel/login_screen.dart';
import 'package:toy_bloom/screens/user-panel/signup_screen.dart';
import 'package:toy_bloom/screens/user-panel/forgot_password_screen.dart';
import 'package:toy_bloom/screens/user-panel/reset_password_screen.dart';
import 'package:toy_bloom/screens/user-panel/email_verification_screen.dart';
import 'package:toy_bloom/screens/user-panel/home_screen.dart';
import 'package:toy_bloom/utils/app_theme.dart' as theme;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyCUErwVNC9mzLWY4Ms2vnS0K0jUwxq-g1U",
      authDomain: "e-commerce-app-firbase.firebaseapp.com",
      projectId: "e-commerce-app-firbase",
      storageBucket: "e-commerce-app-firbase.appspot.com",
      messagingSenderId: "324495874811",
      appId: "1:324495874811:android:ed71f1935dba345de5ee5e",
    ),
  );

  await dotenv.load();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => auth.AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        // Other providers...
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Toy Bloom',
      theme: ThemeData(
        primarySwatch: Colors.deepOrange,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            return const HomeScreen();
          }

          return const LoginScreen();
        },
      ),
    );
  }
}
