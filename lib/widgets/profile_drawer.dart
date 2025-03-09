import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../providers/auth_provider.dart';
import '../utils/app_routes.dart' as routes;
import '../utils/app_constants.dart';

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({Key? key}) : super(key: key);

  Future<void> _updateProfileImage(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      try {
        // Upload image to Firebase Storage
        final ref = FirebaseStorage.instance
            .ref()
            .child('profile_images')
            .child('${authProvider.user!.uid}.jpg');

        if (kIsWeb) {
          // For web
          final bytes = await pickedFile.readAsBytes();
          await ref.putData(bytes);
        } else {
          // For mobile
          final file = File(pickedFile.path);
          await ref.putFile(file);
        }

        final imageUrl = await ref.getDownloadURL();

        // Update user profile
        await authProvider.updateProfile(imageUrl: imageUrl);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile image updated successfully')),
        );
      } catch (e) {
        print('Error updating profile image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                ),
                currentAccountPicture: GestureDetector(
                  onTap: () => _updateProfileImage(context),
                  child: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: auth.profileImageUrl != null
                        ? NetworkImage(auth.profileImageUrl!)
                        : null,
                    child: auth.profileImageUrl == null
                        ? const Icon(Icons.person, color: AppColors.primary)
                        : null,
                  ),
                ),
                accountName: Text(
                  auth.displayName,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                accountEmail: Text(auth.user?.email ?? ''),
              ),

              // Home option
              ListTile(
                leading: const Icon(Icons.home),
                title: const Text('Home'),
                onTap: () {
                  Navigator.pop(context); // Close drawer
                  Navigator.pushReplacementNamed(context, AppRoutes.home);
                },
              ),

              // Admin Panel (shown for admin users)
              if (auth.isAdmin)
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings,
                      color: AppColors.primary),
                  title: const Text(
                    'Admin Dashboard',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  tileColor: AppColors.primary.withOpacity(0.1),
                  onTap: () {
                    Navigator.pop(context); // Close drawer
                    Navigator.pushNamed(context, routes.AppRoutes.admin);
                  },
                ),

              // Cart option
              ListTile(
                leading: const Icon(Icons.shopping_cart),
                title: const Text('My Cart'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, routes.AppRoutes.cart);
                },
              ),

              // Notifications option
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, routes.AppRoutes.notifications);
                },
              ),

              // Profile option
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Edit Profile'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, AppRoutes.profile);
                },
              ),

              const Divider(),

              // Logout option
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title:
                    const Text('Logout', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await auth.signOut();
                  Navigator.pushReplacementNamed(context, AppRoutes.login);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
