import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createAdminUser(User user, String adminCode) async {
    // Get admin code from environment variables
    final validAdminCode = dotenv.env['ADMIN_CODE'] ?? 'TOYBLOOM_ADMIN_2024';

    if (adminCode != validAdminCode) {
      throw "Invalid admin code. Please use the correct admin code to create an admin account.";
    }

    // Validate user data
    if (user.email == null || user.email!.isEmpty) {
      throw "Invalid user email";
    }

    try {
      final batch = _firestore.batch();
      final userRef = _firestore.collection('users').doc(user.uid);

      // Create user document
      batch.set(userRef, {
        'email': user.email,
        'isAdmin': true,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'status': 'active'
      });

      // Create admin role document
      final adminRoleRef = _firestore.collection('admin_roles').doc(user.uid);
      batch.set(adminRoleRef, {
        'userId': user.uid,
        'permissions': ['manage_users', 'manage_products', 'manage_orders'],
        'createdAt': FieldValue.serverTimestamp()
      });

      await batch.commit();
    } catch (e) {
      throw "Failed to create admin user: $e";
    }
  }

  Future<bool> isUserAdmin(String uid) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      final adminRoleDoc =
          await _firestore.collection('admin_roles').doc(uid).get();

      return userDoc.data()?['isAdmin'] == true &&
          userDoc.data()?['status'] == 'active' &&
          adminRoleDoc.exists;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }
}
