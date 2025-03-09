import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../utils/app_constants.dart';

class ProductFormDialog extends StatefulWidget {
  final Map<String, dynamic>? product;

  const ProductFormDialog({
    Key? key,
    this.product,
  }) : super(key: key);

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _networkImageController = TextEditingController();
  final _reviewController = TextEditingController();
  final _ratingController = TextEditingController();
  final _reviewsController = TextEditingController();

  String _selectedCategory = AppConstants.categories.first;
  dynamic _pickedImage;
  String? _imageUrl;
  bool _isLoading = false;
  String? _errorMessage;

  // Color selection
  List<String> _selectedColors = [];
  Map<String, int> _colorQuantities = {};

  // Reviews
  List<Map<String, dynamic>> _reviews = [];
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _loadExistingProduct();
    }
  }

  void _loadExistingProduct() {
    final product = widget.product!;
    _titleController.text = product['name'] ?? '';
    _descriptionController.text = product['description'] ?? '';
    _priceController.text = product['price']?.toString() ?? '';
    _discountedPriceController.text =
        product['discountedPrice']?.toString() ?? '';
    _selectedCategory = product['category'] ?? AppConstants.categories.first;
    _imageUrl = product['imageUrl'];
    _selectedColors = List<String>.from(product['colors'] ?? []);
    _reviews = List<Map<String, dynamic>>.from(product['reviews'] ?? []);
    _averageRating = product['rating']?.toDouble() ?? 0.0;
    _reviewsController.text = product['reviewCount']?.toString() ?? '0';

    // Load color quantities
    Map<String, dynamic>? colorData = product['colorQuantities'];
    if (colorData != null) {
      colorData.forEach((key, value) {
        _colorQuantities[key] = value as int;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountedPriceController.dispose();
    _networkImageController.dispose();
    _reviewController.dispose();
    _ratingController.dispose();
    _reviewsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _pickedImage = pickedFile;
          _networkImageController
              .clear(); // Clear network URL when picking image
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error selecting image: $e';
      });
    }
  }

  Future<String?> _getImageUrl() async {
    // If network image URL is provided, validate it
    if (_networkImageController.text.isNotEmpty) {
      try {
        final response =
            await http.get(Uri.parse(_networkImageController.text));
        if (response.statusCode == 200) {
          return _networkImageController.text;
        } else {
          throw Exception('Invalid image URL');
        }
      } catch (e) {
        setState(() {
          _errorMessage = 'Invalid image URL: $e';
        });
        return null;
      }
    }

    // If no network URL, handle uploaded image
    if (_pickedImage == null) return _imageUrl;

    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('products')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      if (kIsWeb) {
        final bytes = await _pickedImage.readAsBytes();
        final snapshot = await ref.putData(
          bytes,
          SettableMetadata(contentType: 'image/jpeg'),
        );
        return await snapshot.ref.getDownloadURL();
      } else {
        final uploadTask = ref.putFile(File(_pickedImage.path));
        final snapshot = await uploadTask.whenComplete(() {});
        return await snapshot.ref.getDownloadURL();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error uploading image: $e';
      });
      return null;
    }
  }

  void _updateColorQuantity(String color, int quantity) {
    setState(() {
      _colorQuantities[color] = quantity;
    });
  }

  void _addReview() {
    if (_reviewController.text.isNotEmpty &&
        _ratingController.text.isNotEmpty) {
      double rating = double.tryParse(_ratingController.text) ?? 0.0;
      if (rating < 0) rating = 0.0;
      if (rating > 5) rating = 5.0;

      setState(() {
        _reviews.add({
          'text': _reviewController.text,
          'rating': rating,
          'date': DateTime.now().toIso8601String(),
        });
        _reviewController.clear();
        _ratingController.clear();
        _calculateAverageRating();
      });
    }
  }

  void _calculateAverageRating() {
    if (_reviews.isEmpty) {
      _averageRating = 0.0;
      return;
    }
    double sum = _reviews.fold(
        0.0, (prev, review) => prev + (review['rating'] as double));
    _averageRating = sum / _reviews.length;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final imageUrl = await _getImageUrl();
      if (imageUrl == null) {
        throw Exception('Failed to process image');
      }

      // Filter out colors with no quantity
      Map<String, int> selectedColorQuantities = {};
      for (String color in _selectedColors) {
        if (_colorQuantities.containsKey(color) &&
            _colorQuantities[color]! > 0) {
          selectedColorQuantities[color] = _colorQuantities[color]!;
        }
      }

      final data = {
        'name': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text),
        'discountedPrice': _discountedPriceController.text.isEmpty
            ? null
            : double.parse(_discountedPriceController.text),
        'category': _selectedCategory,
        'imageUrl': imageUrl,
        'colors': _selectedColors,
        'colorQuantities': selectedColorQuantities,
        'rating': _averageRating,
        'reviewCount': _reviews.length,
        'reviews': _reviews,
        'isAvailable': true,
        'createdAt': widget.product == null
            ? FieldValue.serverTimestamp()
            : widget.product!['createdAt'],
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.product == null) {
        await FirebaseFirestore.instance.collection('products').add(data);
      } else {
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.product!['id'])
            .update(data);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving product: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Product Image',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Image'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _networkImageController,
          decoration: InputDecoration(
            labelText: 'Or enter image URL',
            hintText: 'https://example.com/image.jpg',
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _networkImageController.clear();
                });
              },
            ),
          ),
          onChanged: (value) {
            setState(() {
              _pickedImage = null; // Clear picked image when entering URL
            });
          },
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: _buildImagePreview(),
        ),
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700], fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePreview() {
    if (_networkImageController.text.isNotEmpty) {
      return Image.network(
        _networkImageController.text,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.error_outline, color: Colors.red, size: 40),
          );
        },
      );
    }

    if (_pickedImage != null) {
      if (kIsWeb) {
        return FutureBuilder<Uint8List>(
          future: _pickedImage.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return Image.memory(snapshot.data!, fit: BoxFit.cover);
            }
            return const Center(child: CircularProgressIndicator());
          },
        );
      } else {
        return Image.file(File(_pickedImage.path), fit: BoxFit.cover);
      }
    }

    if (_imageUrl != null) {
      return Image.network(
        _imageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Center(
            child: Icon(Icons.error_outline, color: Colors.red, size: 40),
          );
        },
      );
    }

    return const Center(
      child: Icon(Icons.add_photo_alternate, size: 50, color: Colors.grey),
    );
  }

  Widget _buildColorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Colors',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.colors.map((color) {
            final isSelected = _selectedColors.contains(color);
            return FilterChip(
              label: Text(color),
              selected: isSelected,
              selectedColor: _getColorValue(color).withOpacity(0.3),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedColors.add(color);
                  } else {
                    _selectedColors.remove(color);
                    _colorQuantities.remove(color);
                  }
                });
              },
              avatar: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getColorValue(color),
                  shape: BoxShape.circle,
                ),
              ),
            );
          }).toList(),
        ),
        if (_selectedColors.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Color Quantities',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _selectedColors.map((color) {
              return SizedBox(
                width: 150,
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: _getColorValue(color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue: _colorQuantities[color]?.toString() ?? '',
                        decoration: InputDecoration(
                          labelText: color,
                          border: const OutlineInputBorder(),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _updateColorQuantity(
                            color,
                            int.tryParse(value) ?? 0,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Reviews',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_reviews.isNotEmpty)
              Text(
                'Average Rating: ${_averageRating.toStringAsFixed(1)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _reviewController,
                decoration: const InputDecoration(
                  labelText: 'Review Text',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: TextFormField(
                controller: _ratingController,
                decoration: const InputDecoration(
                  labelText: 'Rating (0-5)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: _addReview,
          child: const Text('Add Review'),
        ),
        if (_reviews.isNotEmpty) ...[
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _reviews.length,
            itemBuilder: (context, index) {
              final review = _reviews[index];
              return Card(
                child: ListTile(
                  title: Row(
                    children: [
                      Text('Rating: ${review['rating']}'),
                      const SizedBox(width: 8),
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < (review['rating'] as double).floor()
                                ? Icons.star
                                : Icons.star_border,
                            size: 16,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(review['text']),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () {
                      setState(() {
                        _reviews.removeAt(index);
                        _calculateAverageRating();
                      });
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Color _getColorValue(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'pink':
        return Colors.pink;
      case 'brown':
        return Colors.brown;
      case 'gray':
        return Colors.grey;
      case 'navy':
        return Colors.indigo;
      case 'maroon':
        return Colors.red[900] ?? Colors.red;
      case 'teal':
        return Colors.teal;
      case 'gold':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.product != null ? 'Edit Product' : 'Add New Product',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Image Section
                _buildImageSection(),
                const SizedBox(height: 24),

                // Basic Info
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a title' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter a description'
                      : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: AppConstants.categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter a price';
                          }
                          if (double.tryParse(value!) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _discountedPriceController,
                        decoration: const InputDecoration(
                          labelText: 'Discounted Price (Optional)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) return null;
                          if (double.tryParse(value!) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Colors Section
                _buildColorSection(),
                const SizedBox(height: 24),

                // Reviews Section
                _buildReviewsSection(),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProduct,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(widget.product != null ? 'Update' : 'Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
