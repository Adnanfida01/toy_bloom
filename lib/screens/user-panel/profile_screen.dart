import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import '../../providers/auth_provider.dart';
import '../../utils/app_constants.dart';
import '../../utils/app_routes.dart' as routes;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isLoading = false;
  dynamic _pickedImage;
  String? _imagePreview;

  @override
  void initState() {
    super.initState();
    _nameController.text =
        Provider.of<AuthProvider>(context, listen: false).displayName;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      setState(() => _isLoading = true);

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
        maxWidth: 600, // Lower resolution is fine for profile images
        maxHeight: 600,
      );

      if (pickedFile != null) {
        // Show processing message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Processing image...'),
            duration: Duration(seconds: 1),
          ),
        );

        if (kIsWeb) {
          try {
            // For web, read bytes with a size check
            final bytes = await pickedFile.readAsBytes();

            // Check if image is too large (>1MB for profile)
            if (bytes.length > 1 * 1024 * 1024) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                      'Image is too large. Please select a smaller image (under 1MB).'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 4),
                ),
              );
            } else {
              setState(() {
                _pickedImage = pickedFile;
                _imagePreview = null; // Will use bytes for preview on web
              });
            }
          } catch (e) {
            print('Error processing image: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error processing image: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // For mobile
          setState(() {
            _pickedImage = File(pickedFile.path);
            _imagePreview = null;
          });
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error selecting image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    if (_nameController.text.trim().isEmpty) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Display a progress message
    scaffoldMessenger.showSnackBar(
      const SnackBar(
        content: Text('Updating profile... This may take a moment.'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      String? imageUrl;

      // Upload image if one was selected
      if (_pickedImage != null) {
        final ref = FirebaseStorage.instance.ref().child('profile_images').child(
            '${authProvider.user!.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

        UploadTask uploadTask;

        if (kIsWeb) {
          // For web, use bytes data from XFile with careful error handling
          try {
            final bytes = await _pickedImage.readAsBytes().timeout(
              const Duration(seconds: 30), // Increased timeout
              onTimeout: () {
                throw TimeoutException(
                    'Reading image data timed out. Please try again with a smaller image.');
              },
            );

            // Add content type metadata for better handling
            uploadTask =
                ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
          } catch (e) {
            if (e is TimeoutException) {
              rethrow;
            }
            throw Exception('Failed to process image: ${e.toString()}');
          }
        } else {
          // For mobile, use File
          uploadTask = ref.putFile(_pickedImage);
        }

        // Show upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
        });

        // Add timeout to the upload task with a longer duration
        await uploadTask.timeout(
          const Duration(seconds: 60), // Increased to 60 seconds
          onTimeout: () {
            throw TimeoutException(
                'Image upload timed out. Please try again with a smaller image or check your connection.');
          },
        );

        // Get download URL with timeout
        imageUrl = await ref.getDownloadURL().timeout(
          const Duration(seconds: 15), // Increased to 15 seconds
          onTimeout: () {
            throw TimeoutException(
                'Failed to get image URL. Please try again.');
          },
        );
      }

      // Update profile with timeout
      await authProvider
          .updateProfile(
        displayName: _nameController.text.trim(),
        imageUrl: imageUrl,
      )
          .timeout(
        const Duration(seconds: 20), // Increased to 20 seconds
        onTimeout: () {
          throw TimeoutException('Profile update timed out. Please try again.');
        },
      );

      // Only show success if we're still mounted and the update completed
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error updating profile: $e');

      // Provide more specific error messages
      String errorMessage = 'An error occurred while updating your profile.';

      if (e is TimeoutException) {
        errorMessage = e.message ??
            'Operation timed out. Please try again with a smaller image.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e.toString().contains('permission-denied')) {
        errorMessage =
            'Permission denied. You may not have proper access rights.';
      } else if (e.toString().contains('storage')) {
        errorMessage =
            'Storage error. Image upload failed. Try a smaller image.';
      }

      // Only show error if we're still mounted
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _updateProfile,
              textColor: Colors.white,
            ),
          ),
        );
      }
    } finally {
      // Only update state if the widget is still mounted
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Profile Image
              Stack(
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[200],
                      image: _pickedImage != null
                          ? kIsWeb
                              ? null // We'll handle web preview differently
                              : DecorationImage(
                                  image: FileImage(_pickedImage as File),
                                  fit: BoxFit.cover,
                                )
                          : authProvider.profileImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(
                                      authProvider.profileImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                    ),
                    child: _pickedImage != null && kIsWeb
                        ? FutureBuilder<Uint8List>(
                            future: _pickedImage.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                      ConnectionState.done &&
                                  snapshot.hasData) {
                                return ClipRRect(
                                  borderRadius: BorderRadius.circular(60),
                                  child: Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                    width: 120,
                                    height: 120,
                                  ),
                                );
                              }
                              return const CircularProgressIndicator();
                            },
                          )
                        : (_pickedImage == null &&
                                authProvider.profileImageUrl == null)
                            ? const Icon(Icons.person,
                                size: 60, color: Colors.grey)
                            : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 20),
                        onPressed: _pickImage,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // User Email
              Text(
                authProvider.user?.email ?? 'Not signed in',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),

              const SizedBox(height: 30),

              // Display Name Field
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Display Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.person),
                ),
              ),

              const SizedBox(height: 30),

              // Update Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Update Profile',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),

              if (authProvider.isAdmin)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Column(
                    children: [
                      const Divider(),
                      const SizedBox(height: 16),
                      Text(
                        'Admin Options',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.admin_panel_settings),
                          label: const Text('Go to Admin Dashboard'),
                          onPressed: () => Navigator.pushNamed(
                              context, routes.AppRoutes.admin),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
