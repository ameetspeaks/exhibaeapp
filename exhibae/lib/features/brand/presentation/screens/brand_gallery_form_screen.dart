
import 'package:flutter/material.dart';
import 'package:exhibae/core/theme/app_theme.dart';
import 'package:exhibae/core/utils/responsive_utils.dart';
import 'package:exhibae/core/widgets/responsive_card.dart';
import 'package:exhibae/core/services/supabase_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'dart:convert'; // Added for base64 encoding
import 'dart:io'; // Added for File

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
  String? _fileUrl;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.galleryItem != null;
    if (_isEditing) {
      _titleController.text = widget.galleryItem!['title'] ?? '';
      _descriptionController.text = widget.galleryItem!['description'] ?? '';
      _fileUrl = widget.galleryItem!['image_url'];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        
        setState(() {
          _isLoading = true;
        });

        try {
          // Upload file to Supabase storage
          final supabaseService = SupabaseService.instance;
          final currentUser = supabaseService.currentUser;
          
          if (currentUser == null) {
            throw Exception('User not authenticated');
          }

          // Generate unique filename
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = '${timestamp}_${file.name}';
          final bucketName = 'gallery';
          final filePath = '${currentUser.id}/$fileName';
          
          String? uploadedUrl;
          
          if (file.bytes != null) {
            // Web platform - upload from bytes
            uploadedUrl = await supabaseService.client.storage
                .from(bucketName)
                .uploadBinary(
                  filePath,
                  file.bytes!,
                );
          } else if (file.path != null) {
            // Mobile/Desktop platforms - upload from file path
            final fileData = File(file.path!).readAsBytesSync();
            uploadedUrl = await supabaseService.client.storage
                .from(bucketName)
                .uploadBinary(
                  filePath,
                  fileData,
                );
          }

          if (uploadedUrl != null) {
            // Get public URL
            final publicUrl = supabaseService.client.storage
                .from(bucketName)
                .getPublicUrl(filePath);

            setState(() {
              _fileUrl = publicUrl;
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Image uploaded successfully: ${file.name}'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            throw Exception('Failed to upload file to storage');
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error uploading file: ${e.toString()}'),
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
            content: Text('Error picking file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveGalleryItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_fileUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Save gallery item to database
      final supabaseService = SupabaseService.instance;
      
      final galleryData = {
        'brand_id': widget.brandId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'image_url': _fileUrl,
      };

      Map<String, dynamic>? result;

      if (_isEditing) {
        result = await supabaseService.updateBrandGalleryItem(
          widget.galleryItem!['id'],
          galleryData,
        );
      } else {
        result = await supabaseService.createBrandGalleryItem(galleryData);
      }

      if (result != null) {
        if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(
               content: Text(_isEditing 
                 ? 'Gallery file updated successfully!' 
                 : 'Gallery file created successfully!'
               ),
             ),
           );
          Navigator.pop(context, true);
        }
      } else {
                 throw Exception('Failed to save gallery file - database returned null');
      }
    } catch (e) {
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
        title: Text(_isEditing ? 'Edit Gallery File' : 'Add File to Gallery'),
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
                         _isEditing ? 'Edit Gallery File' : 'Add New File to Gallery',
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
                      
                                             // File Upload Section
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
                                   Icons.upload_file,
                                   color: AppTheme.primaryBlue,
                                   size: ResponsiveUtils.getIconSize(context, mobile: 24, tablet: 28, desktop: 32),
                                 ),
                                 SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                                 Expanded(
                                   child: Column(
                                     crossAxisAlignment: CrossAxisAlignment.start,
                                     children: [
                                       Text(
                                         'File Upload',
                                         style: TextStyle(
                                           fontSize: ResponsiveUtils.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
                                           fontWeight: FontWeight.bold,
                                           color: AppTheme.textDarkCharcoal,
                                         ),
                                       ),
                                       Text(
                                         'Upload any file type (images, videos, documents, etc.)',
                                         style: TextStyle(
                                           fontSize: ResponsiveUtils.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                           color: Colors.grey[600],
                                         ),
                                       ),
                                     ],
                                   ),
                                 ),
                              ],
                            ),
                            SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                            
                            if (_fileUrl != null) ...[
                              Container(
                                padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.primaryBlue.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.file_present,
                                      color: AppTheme.primaryBlue,
                                      size: ResponsiveUtils.getIconSize(context, mobile: 20, tablet: 24, desktop: 28),
                                    ),
                                    SizedBox(width: ResponsiveUtils.getIconSize(context, mobile: 8, tablet: 12, desktop: 16)),
                                    Expanded(
                                      child: Text(
                                        _fileUrl!,
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                          color: Colors.black.withOpacity(0.7),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _fileUrl = null;
                                        });
                                      },
                                      icon: Icon(
                                        Icons.close,
                                        color: Colors.red,
                                        size: ResponsiveUtils.getIconSize(context, mobile: 16, tablet: 18, desktop: 20),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                            ],
                            
                            ElevatedButton.icon(
                              onPressed: _pickFile,
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
                                _fileUrl != null ? 'Change File' : 'Select Any File',
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
                                                                             _isEditing ? 'Update Gallery File' : 'Create Gallery File',
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
