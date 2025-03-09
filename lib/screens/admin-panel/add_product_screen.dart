import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/notification_provider.dart';

class AddProductScreen extends StatefulWidget {
  // ... (existing code)
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  String _selectedCategory = '';
  String _imageUrl = '';
  // ... (existing code)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ... existing form widgets ...
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleAddProduct() async {
    final productData = {
      'name': _nameController.text,
      'price': double.parse(_priceController.text),
      'category': _selectedCategory,
      'imageUrl': _imageUrl,
    };

    try {
      final productRef =
          await _firestore.collection('products').add(productData);

      final notificationProvider =
          Provider.of<NotificationProvider>(context, listen: false);
      await notificationProvider.sendNewProductNotification(
        productData['name'] as String,
        productRef.id,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Product added successfully and notifications sent!')),
      );

      // ... (existing code)
    } catch (e) {
      // ... (existing code)
    }
  }
}
