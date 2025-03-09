import 'dart:io';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountedPriceController = TextEditingController();
  final _brandController = TextEditingController();
  final _networkImageUrlController = TextEditingController();
  final _ratingController = TextEditingController(text: '0.0');
  final _reviewsCountController = TextEditingController(text: '0');

  // Main colors to match login/signup screens
  final Color primaryColor = const Color(0xFFFF5722); // Orange/coral color
  final Color secondaryColor =
      const Color(0xFFFFF3F0); // Light orange/coral background
  final Color backgroundColor = Colors.white;
  final Color textColor = Colors.black87;

  File? _imageFile;
  List<File> _imageFiles = [];
  Uint8List? _webImage;
  List<Uint8List> _webImages = [];
  String? _pickedImagePath;
  bool _isLoading = false;
  bool _isUploading = false;
  bool _isSizeRequired = false;
  double _uploadProgress = 0.0;
  int _retryCount = 0;
  final int _maxRetries = 3;
  int _selectedThumbnailIndex = 0;

  final List<String> _selectedSizes = [];
  final List<String> _availableSizes = ['XS', 'S', 'M', 'L', 'XL'];

  final List<String> _categories = [
    'kids t-shirt',
    'blankets',
    'toys',
    'shoes',
    'accessories',
  ];
  String _selectedCategory = 'toys';

  final List<String> _availableColors = [
    'Red',
    'Blue',
    'Green',
    'Yellow',
    'Black',
    'White',
    'Orange',
    'Purple',
    'Pink',
    'Brown',
    'Grey'
  ];
  final List<String> _selectedColors = [];

  final List<String> _networkImageUrls = [];

  Future<void> _pickImage({bool isMultiple = false}) async {
    final picker = ImagePicker();

    if (isMultiple) {
      final pickedFiles = await picker.pickMultiImage(
        imageQuality: 50,
        maxWidth: 600,
        maxHeight: 600,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() => _isLoading = true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Processing images...'),
            duration: Duration(seconds: 1),
          ),
        );

        try {
          if (kIsWeb) {
            List<Uint8List> newWebImages = [];
            for (var file in pickedFiles) {
              try {
                final bytes = await file.readAsBytes();
                if (bytes.length > 1 * 1024 * 1024) {
                  // Skip oversized images
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Image ${file.name} is too large and was skipped.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else {
                  newWebImages.add(bytes);
                }
              } catch (e) {
                print('Error processing image ${file.name}: $e');
              }
            }

            setState(() {
              _webImages.addAll(newWebImages);
              if (_webImages.isNotEmpty && _selectedThumbnailIndex == 0) {
                _webImage = _webImages.first;
              }
            });
          } else {
            List<File> newFiles = [];
            for (var file in pickedFiles) {
              newFiles.add(File(file.path));
            }

            setState(() {
              _imageFiles.addAll(newFiles);
              if (_imageFiles.isNotEmpty && _selectedThumbnailIndex == 0) {
                _imageFile = _imageFiles.first;
              }
            });
          }
        } finally {
          setState(() => _isLoading = false);
        }
      }
    } else {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
        maxWidth: 600,
        maxHeight: 600,
      );

      if (pickedFile != null) {
        try {
          setState(() => _isLoading = true);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Processing image...'),
              duration: Duration(seconds: 1),
            ),
          );

          if (kIsWeb) {
            try {
              final bytes = await pickedFile.readAsBytes();
              if (bytes.length > 1 * 1024 * 1024) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Image is too large. Please select an image smaller than 1MB.'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 4),
                  ),
                );
              } else {
                setState(() {
                  _pickedImagePath = pickedFile.path;
                  _webImage = bytes;
                  _webImages.add(bytes);
                });
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error processing image: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } else {
            setState(() {
              _pickedImagePath = pickedFile.path;
              _imageFile = File(pickedFile.path);
              _imageFiles.add(File(pickedFile.path));
            });
          }
        } finally {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _setThumbnail(int index) {
    setState(() {
      _selectedThumbnailIndex = index;
      if (kIsWeb) {
        if (index < _webImages.length) {
          _webImage = _webImages[index];
        }
      } else {
        if (index < _imageFiles.length) {
          _imageFile = _imageFiles[index];
        }
      }
    });
  }

  void _removeImage(int index) {
    setState(() {
      if (kIsWeb) {
        if (index < _webImages.length) {
          _webImages.removeAt(index);
          if (_selectedThumbnailIndex >= _webImages.length) {
            _selectedThumbnailIndex = _webImages.isEmpty ? 0 : 0;
          }
          if (_webImages.isNotEmpty) {
            _webImage = _webImages[_selectedThumbnailIndex];
          } else {
            _webImage = null;
          }
        }
      } else {
        if (index < _imageFiles.length) {
          _imageFiles.removeAt(index);
          if (_selectedThumbnailIndex >= _imageFiles.length) {
            _selectedThumbnailIndex = _imageFiles.isEmpty ? 0 : 0;
          }
          if (_imageFiles.isNotEmpty) {
            _imageFile = _imageFiles[_selectedThumbnailIndex];
          } else {
            _imageFile = null;
          }
        }
      }
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final bool hasImages =
        kIsWeb ? _webImages.isNotEmpty : _imageFiles.isNotEmpty;
    final bool hasNetworkImages = _networkImageUrls.isNotEmpty;

    if (!hasImages && !hasNetworkImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    // Validate colors
    if (_selectedColors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one color')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Uploading product... This may take a moment.'),
          duration: Duration(seconds: 2),
        ),
      );

      List<String> imageUrls = [..._networkImageUrls];
      String thumbnailUrl = '';

      // Upload local images if any
      if (hasImages) {
        if (kIsWeb) {
          // Upload each web image
          for (int i = 0; i < _webImages.length; i++) {
            final ref = FirebaseStorage.instance
                .ref()
                .child('products/${DateTime.now().millisecondsSinceEpoch}_$i');

            final metadata = SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {'picked-from': 'AddProductScreen'},
            );

            final uploadTask = ref.putData(_webImages[i], metadata);

            uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
              setState(() {
                _uploadProgress =
                    snapshot.bytesTransferred / snapshot.totalBytes;
              });
            });

            try {
              await uploadTask.timeout(
                const Duration(seconds: 60),
                onTimeout: () {
                  throw TimeoutException('Upload timed out for image $i');
                },
              );

              // Get download URL
              final url = await ref.getDownloadURL();
              imageUrls.add(url);
            } catch (e) {
              if (e is TimeoutException && _retryCount < _maxRetries) {
                _retryCount++;
                await Future.delayed(const Duration(seconds: 2));
                continue;
              }
              rethrow;
            }
          }
        } else {
          // Upload each mobile image
          for (int i = 0; i < _imageFiles.length; i++) {
            final ref = FirebaseStorage.instance
                .ref()
                .child('products/${DateTime.now().millisecondsSinceEpoch}_$i');

            final uploadTask = ref.putFile(_imageFiles[i]);

            uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
              setState(() {
                _uploadProgress =
                    snapshot.bytesTransferred / snapshot.totalBytes;
              });
            });

            await uploadTask.timeout(
              const Duration(seconds: 60),
              onTimeout: () {
                throw TimeoutException('Image upload timed out for image $i');
              },
            );

            // Get download URL
            final url = await ref.getDownloadURL();
            imageUrls.add(url);
          }
        }
      }

      // Set thumbnail URL
      final allImages = [..._networkImageUrls, ...imageUrls];
      if (allImages.isNotEmpty) {
        thumbnailUrl = allImages[_selectedThumbnailIndex];
      }

      // Parse values
      final double price = double.tryParse(_priceController.text) ?? 0;
      double? discountedPrice;
      if (_discountedPriceController.text.isNotEmpty) {
        discountedPrice = double.tryParse(_discountedPriceController.text);
      }
      final double rating = double.tryParse(_ratingController.text) ?? 0.0;
      final int reviewsCount = int.tryParse(_reviewsCountController.text) ?? 0;

      // Prepare product data
      final productData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': price,
        'brand': _brandController.text,
        'thumbnailUrl': thumbnailUrl,
        'imageUrls': allImages,
        'category': _selectedCategory,
        'sizes': _selectedSizes,
        'colors': _selectedColors,
        'hasSizes': _isSizeRequired,
        'discountedPrice': discountedPrice,
        'rating': rating,
        'reviews': reviewsCount,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Save product to Firestore
      await FirebaseFirestore.instance
          .collection('products')
          .add(productData)
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException(
              'Database operation timed out. Please try again.');
        },
      );

      _retryCount = 0;

      // Success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // Error handling
      String errorMessage = 'An error occurred. Please try again.';

      if (e is TimeoutException) {
        errorMessage =
            'Operation timed out. Please try again with smaller images or check your connection.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection.';
      } else if (e.toString().contains('permission-denied')) {
        errorMessage =
            'Permission denied. You may not have proper access rights.';
      } else if (e.toString().contains('storage')) {
        errorMessage =
            'Storage error. Image upload failed. Try smaller images.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _submitForm,
              textColor: Colors.white,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.of(context).size.width > 900;
    final screenPadding = isWideScreen
        ? const EdgeInsets.symmetric(horizontal: 100, vertical: 24)
        : const EdgeInsets.all(16);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        elevation: 0,
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
        ),
        child: SingleChildScrollView(
          padding: screenPadding,
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isWideScreen ? 800 : double.infinity,
              ),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Add New Product',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),

                        // Main image upload section (thumbnail)
                        Center(
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: _isLoading ? null : () => _pickImage(),
                                child: Container(
                                  width: 250,
                                  height: 250,
                                  decoration: BoxDecoration(
                                    color: secondaryColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: primaryColor.withOpacity(0.3),
                                      width: 2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryColor.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: _isUploading
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              CircularProgressIndicator(
                                                value: _uploadProgress > 0
                                                    ? _uploadProgress
                                                    : null,
                                                color: primaryColor,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Uploading: ${(_uploadProgress * 100).toStringAsFixed(0)}%',
                                                style: TextStyle(
                                                  color: primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      : ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(18),
                                          child: _getImageWidget(),
                                        ),
                                ),
                              ),

                              // Camera icon overlay
                              if (!_isUploading)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.2),
                                          blurRadius: 5,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Thumbnail label
                        Center(
                          child: Text(
                            'Thumbnail Image',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // Multiple image upload section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: secondaryColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: primaryColor.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Additional Product Images',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : () => _pickImage(isMultiple: true),
                                    icon: const Icon(Icons.add_photo_alternate),
                                    label: const Text('Add Images'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Image gallery
                              _buildImageGallery(),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Form fields
                        LayoutBuilder(builder: (context, constraints) {
                          return constraints.maxWidth > 600
                              ? _buildWideLayoutForm()
                              : _buildNarrowLayoutForm();
                        }),

                        const SizedBox(height: 20),

                        // Size options section
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: secondaryColor.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: primaryColor.withOpacity(0.2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Product has different sizes',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Switch(
                                    value: _isSizeRequired,
                                    activeColor: primaryColor,
                                    onChanged: (value) {
                                      setState(() {
                                        _isSizeRequired = value;
                                        if (!value) {
                                          _selectedSizes.clear();
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                              if (_isSizeRequired) ...[
                                const SizedBox(height: 12),
                                const Text(
                                  'Select available sizes:',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: _availableSizes.map((size) {
                                    final isSelected =
                                        _selectedSizes.contains(size);
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedSizes.remove(size);
                                          } else {
                                            _selectedSizes.add(size);
                                          }
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? primaryColor
                                              : Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                        child: Text(
                                          size,
                                          style: TextStyle(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.black87,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        // Submit button
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  )
                                : const Text(
                                    'Add Product',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),

                        if (_retryCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Center(
                              child: Text(
                                'Retry attempt $_retryCount of $_maxRetries',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery() {
    final List<dynamic> allImages = [
      ..._networkImageUrls.map((url) => {'type': 'network', 'data': url}),
      ...kIsWeb
          ? _webImages.map((bytes) => {'type': 'web', 'data': bytes})
          : _imageFiles.map((file) => {'type': 'file', 'data': file}),
    ];

    if (allImages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Text(
            'No images added yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Thumbnail Image',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1,
          ),
          itemCount: allImages.length,
          itemBuilder: (context, index) {
            final image = allImages[index];
            final bool isSelected = index == _selectedThumbnailIndex;

            return Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedThumbnailIndex = index;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? primaryColor : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: image['type'] == 'network'
                          ? Image.network(
                              image['data'],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            )
                          : image['type'] == 'web'
                              ? Image.memory(
                                  image['data'],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : Image.file(
                                  image['data'],
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                    ),
                  ),
                ),
                if (isSelected)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                Positioned(
                  top: 5,
                  right: isSelected ? 30 : 5,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        if (image['type'] == 'network') {
                          _networkImageUrls.removeAt(index);
                        } else if (image['type'] == 'web') {
                          _webImages.removeAt(index - _networkImageUrls.length);
                        } else {
                          _imageFiles
                              .removeAt(index - _networkImageUrls.length);
                        }
                        if (_selectedThumbnailIndex >= allImages.length - 1) {
                          _selectedThumbnailIndex = allImages.length - 2;
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.7),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        color: Colors.red[700],
                        size: 12,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildNetworkImageInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _networkImageUrlController,
                decoration: InputDecoration(
                  labelText: 'Network Image URL',
                  hintText: 'Enter image URL',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                if (_networkImageUrlController.text.isNotEmpty) {
                  setState(() {
                    _networkImageUrls.add(_networkImageUrlController.text);
                    _networkImageUrlController.clear();
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ],
        ),
        if (_networkImageUrls.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _networkImageUrls
                .map(
                  (url) => Chip(
                    label: Text(
                      url.split('/').last,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onDeleted: () {
                      setState(() {
                        _networkImageUrls.remove(url);
                      });
                    },
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildWideLayoutForm() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildInputField(
                controller: _nameController,
                label: 'Product Name',
                icon: Icons.shopping_bag,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a name' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInputField(
                controller: _brandController,
                label: 'Brand',
                icon: Icons.business,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a brand' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _descriptionController,
          label: 'Description',
          icon: Icons.description,
          maxLines: 3,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter a description' : null,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildInputField(
                controller: _priceController,
                label: 'Price (\$)',
                icon: Icons.attach_money,
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a price' : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInputField(
                controller: _discountedPriceController,
                label: 'Discounted Price (\$) (Optional)',
                icon: Icons.discount,
                hintText: 'Leave empty if no discount',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildNetworkImageInput(),
        const SizedBox(height: 20),

        // Color selection section with visual color indicators
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: secondaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.color_lens, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Available Colors',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableColors.map((color) {
                  final isSelected = _selectedColors.contains(color);
                  final materialColor = _getColorFromString(color);
                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: materialColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        Text(color),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedColors.add(color);
                        } else {
                          _selectedColors.remove(color);
                        }
                      });
                    },
                    selectedColor: primaryColor.withOpacity(0.2),
                    checkmarkColor: primaryColor,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? primaryColor : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  );
                }).toList(),
              ),
              if (_selectedColors.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Selected colors: ${_selectedColors.join(", ")}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Reviews and Rating section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: secondaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Ratings & Reviews',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField(
                          controller: _ratingController,
                          label: 'Initial Rating (0-5)',
                          icon: Icons.star_rate,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) return null;
                            final rating = double.tryParse(value);
                            if (rating == null || rating < 0 || rating > 5) {
                              return 'Rating must be between 0 and 5';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter a rating between 0 and 5 (e.g., 4.5)',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInputField(
                          controller: _reviewsCountController,
                          label: 'Number of Reviews',
                          icon: Icons.reviews,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty) return null;
                            final count = int.tryParse(value);
                            if (count == null || count < 0) {
                              return 'Reviews count must be 0 or greater';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enter the total number of reviews',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayoutForm() {
    return Column(
      children: [
        _buildInputField(
          controller: _nameController,
          label: 'Product Name',
          icon: Icons.shopping_bag,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter a name' : null,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _brandController,
          label: 'Brand',
          icon: Icons.business,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter a brand' : null,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _descriptionController,
          label: 'Description',
          icon: Icons.description,
          maxLines: 3,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter a description' : null,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _priceController,
          label: 'Price (\$)',
          icon: Icons.attach_money,
          keyboardType: TextInputType.number,
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter a price' : null,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          controller: _discountedPriceController,
          label: 'Discounted Price (\$) (Optional)',
          icon: Icons.discount,
          hintText: 'Leave empty if no discount',
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        _buildNetworkImageInput(),
        const SizedBox(height: 20),

        // Color selection section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: secondaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.color_lens, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Available Colors',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _availableColors.map((color) {
                  final isSelected = _selectedColors.contains(color);
                  final materialColor = _getColorFromString(color);
                  return FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 16,
                          height: 16,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            color: materialColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                        ),
                        Text(color),
                      ],
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedColors.add(color);
                        } else {
                          _selectedColors.remove(color);
                        }
                      });
                    },
                    selectedColor: primaryColor.withOpacity(0.2),
                    checkmarkColor: primaryColor,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? primaryColor : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  );
                }).toList(),
              ),
              if (_selectedColors.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Selected colors: ${_selectedColors.join(", ")}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Reviews and Rating section
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: secondaryColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: primaryColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.star, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Ratings & Reviews',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _ratingController,
                label: 'Initial Rating (0-5)',
                icon: Icons.star_rate,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  final rating = double.tryParse(value);
                  if (rating == null || rating < 0 || rating > 5) {
                    return 'Rating must be between 0 and 5';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Enter a rating between 0 and 5 (e.g., 4.5)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              _buildInputField(
                controller: _reviewsCountController,
                label: 'Number of Reviews',
                icon: Icons.reviews,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) return null;
                  final count = int.tryParse(value);
                  if (count == null || count < 0) {
                    return 'Reviews count must be 0 or greater';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the total number of reviews',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: secondaryColor.withOpacity(0.2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        filled: true,
        fillColor: secondaryColor.withOpacity(0.2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      value: _selectedCategory,
      items: _categories.map((category) {
        return DropdownMenuItem(
          value: category,
          child: Text(
            category,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCategory = value;
          });
        }
      },
      validator: (value) => value == null ? 'Please select a category' : null,
      icon: Icon(Icons.arrow_drop_down, color: primaryColor),
      isExpanded: true,
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget _getImageWidget() {
    if (_webImage != null && kIsWeb) {
      return Image.memory(_webImage!, fit: BoxFit.cover);
    } else if (_imageFile != null && !kIsWeb) {
      return Image.file(_imageFile!, fit: BoxFit.cover);
    } else {
      return Container(
        color: secondaryColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate,
              size: 64,
              color: primaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              'Add Product Image',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Click to upload thumbnail (JPG, PNG)',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'brown':
        return Colors.brown;
      case 'grey':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountedPriceController.dispose();
    _brandController.dispose();
    _networkImageUrlController.dispose();
    _ratingController.dispose();
    _reviewsCountController.dispose();
    super.dispose();
  }
}
