import 'dart:io';
import 'package:flutter/material.dart';
import 'package:exhibae/core/theme/app_theme.dart';
import 'package:exhibae/core/utils/responsive_utils.dart';
import 'package:exhibae/core/widgets/responsive_card.dart';
import 'package:exhibae/core/services/supabase_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class BrandGalleryFormScreen extends StatefulWidget {
  final Map<String, dynamic>? galleryItem;
  final String brandId;

  const BrandGalleryFormScreen({
    super.key,
    this.galleryItem,
    required this.brandId,
  });

  @override
  State<BrandGalleryFormScreen> createState() => _BrandGalleryFormScreenState();
}

class _BrandGalleryFormScreenState extends State<BrandGalleryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _imageUrl;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.galleryItem != null;
    if (_isEditing) {
      _titleController.text = widget.galleryItem!['title'] ?? '';
      _descriptionController.text = widget.galleryItem!['description'] ?? '';
      _imageUrl = widget.galleryItem!['image_url'];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _isLoading = true;
        });

        try {
          // Upload image to Supabase Storage
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
          final filePath = '${widget.brandId}/gallery/$fileName';
          
          String? fileUrl;
          if (image.path.startsWith('http')) {
            // Web platform - get bytes
            final bytes = await image.readAsBytes();
            final uploadResult = await SupabaseService.instance.uploadFile(
              bucket: 'gallery',
              path: filePath,
              fileBytes: bytes,
              contentType: 'image/${path.extension(image.path).replaceAll('.', '')}',
            );
            fileUrl = uploadResult;
          } else {
            // Mobile/Desktop platforms - use file path
            final uploadResult = await SupabaseService.instance.uploadFile(
              bucket: 'gallery',
              path: filePath,
              filePath: image.path,
              contentType: 'image/${path.extension(image.path).replaceAll('.', '')}',
            );
            fileUrl = uploadResult;
          }

          if (fileUrl != null) {
            setState(() {
              _imageUrl = fileUrl;
            });
          } else {
            throw Exception('Failed to upload image');
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error uploading image: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveGalleryItem() async {
    print('Starting to save gallery item...');
    
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }
    
    if (_imageUrl == null) {
      print('No image URL available');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    print('Image URL: $_imageUrl');
    print('Brand ID: ${widget.brandId}');
    print('Title: ${_titleController.text.trim()}');
    print('Description: ${_descriptionController.text.trim()}');

    setState(() {
      _isLoading = true;
    });

    try {
      // Check storage buckets first
      final supabaseService = SupabaseService.instance;
      print('Checking storage buckets...');
      final buckets = await supabaseService.listStorageBuckets();
      print('Available buckets: $buckets');
      
      final galleryData = {
        'brand_id': widget.brandId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image_url': _imageUrl,
      };

      print('Gallery data to save: $galleryData');

      Map<String, dynamic>? result;

      if (_isEditing) {
        print('Updating existing gallery item...');
        result = await supabaseService.updateBrandGalleryItem(
          widget.galleryItem!['id'],
          galleryData,
        );
      } else {
        print('Creating new gallery item...');
        result = await supabaseService.createBrandGalleryItem(galleryData);
      }

      print('Database operation result: $result');

      if (result != null) {
        print('Gallery item saved successfully!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing 
                ? 'Gallery item updated successfully!' 
                : 'Gallery item created successfully!'
              ),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        print('Database operation returned null');
        throw Exception('Failed to save gallery item - database returned null');
      }
    } catch (e) {
      print('Error saving gallery item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
         } finally {
       if (mounted) {
         setState(() {
           _isLoading = false;
         });
       }
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLightGray,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Gallery Item' : 'Add Gallery Item'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 24, desktop: 32)),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ResponsiveCard(
              child: Padding(
                padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, mobile: 20, tablet: 24, desktop: 32)),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'Edit Gallery Item' : 'Add New Gallery Item',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getFontSize(context, mobile: 24, tablet: 28, desktop: 32),
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDarkCharcoal,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 24, tablet: 32, desktop: 40)),
                      
                      // Title Field
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                      
                      // Description Field
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 3,
                      ),
                      SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                      
                      // Image Upload Section
                      Container(
                        padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.image,
                                  color: AppTheme.primaryBlue,
                                  size: ResponsiveUtils.getIconSize(context, mobile: 24, tablet: 28, desktop: 32),
                                ),
                                SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                                Expanded(
                                  child: Text(
                                    'Image Upload',
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDarkCharcoal,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                            
                            if (_imageUrl != null) ...[
                              Container(
                                height: ResponsiveUtils.getCardHeight(context) * 0.3,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.primaryBlue.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Stack(
                                    children: [
                                      Image.network(
                                        _imageUrl!,
                                        width: double.infinity,
                                        height: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Center(
                                          child: Icon(
                                            Icons.broken_image,
                                            size: ResponsiveUtils.getIconSize(context, mobile: 48, tablet: 56, desktop: 64),
                                            color: AppTheme.textMediumGray,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _imageUrl = null;
                                              });
                                            },
                                            icon: Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: ResponsiveUtils.getIconSize(context, mobile: 16, tablet: 18, desktop: 20),
                                            ),
                                            constraints: BoxConstraints(
                                              minWidth: ResponsiveUtils.getIconSize(context, mobile: 32, tablet: 36, desktop: 40),
                                              minHeight: ResponsiveUtils.getIconSize(context, mobile: 32, tablet: 36, desktop: 40),
                                            ),
                                            padding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                            ],
                            
                            ElevatedButton.icon(
                              onPressed: _pickImage,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveUtils.getSpacing(context, mobile: 20, tablet: 24, desktop: 28),
                                  vertical: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon(
                                Icons.upload,
                                size: ResponsiveUtils.getIconSize(context, mobile: 18, tablet: 20, desktop: 22),
                              ),
                              label: Text(
                                _imageUrl != null ? 'Change Image' : 'Select Image',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 32, tablet: 40, desktop: 48)),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _isLoading ? null : () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  vertical: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 20, desktop: 24),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: AppTheme.primaryBlue),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                                  color: AppTheme.primaryBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveGalleryItem,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 20, desktop: 24),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: ResponsiveUtils.getIconSize(context, mobile: 20, tablet: 24, desktop: 28),
                                      width: ResponsiveUtils.getIconSize(context, mobile: 20, tablet: 24, desktop: 28),
                                      child: const CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      _isEditing ? 'Update Gallery Item' : 'Create Gallery Item',
                                      style: TextStyle(
                                        fontSize: ResponsiveUtils.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
