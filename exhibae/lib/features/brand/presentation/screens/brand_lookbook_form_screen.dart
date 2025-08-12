import 'dart:io';
import 'package:flutter/material.dart';
import 'package:exhibae/core/theme/app_theme.dart';
import 'package:exhibae/core/utils/responsive_utils.dart';
import 'package:exhibae/core/widgets/responsive_card.dart';
import 'package:exhibae/core/services/supabase_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class BrandLookbookFormScreen extends StatefulWidget {
  final Map<String, dynamic>? lookbook;
  final String brandId;

  const BrandLookbookFormScreen({
    super.key,
    this.lookbook,
    required this.brandId,
  });

  @override
  State<BrandLookbookFormScreen> createState() => _BrandLookbookFormScreenState();
}

class _BrandLookbookFormScreenState extends State<BrandLookbookFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedFileType = 'pdf';
  String? _fileUrl;
  bool _isLoading = false;
  bool _isEditing = false;

  final List<String> _fileTypes = [
    'pdf',
    'doc',
    'docx',
    'ppt',
    'pptx',
    'xls',
    'xlsx',
    'jpg',
    'jpeg',
    'png',
    'gif',
    'mp4',
    'mov',
    'avi'
  ];

  @override
  void initState() {
    super.initState();
    _isEditing = widget.lookbook != null;
    if (_isEditing) {
      _titleController.text = widget.lookbook!['title'] ?? '';
      _descriptionController.text = widget.lookbook!['description'] ?? '';
      _selectedFileType = widget.lookbook!['file_type'] ?? 'pdf';
      _fileUrl = widget.lookbook!['file_url'];
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
        type: FileType.custom,
        allowedExtensions: _fileTypes,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileExtension = path.extension(file.name).toLowerCase().replaceAll('.', '');
        
        if (!_fileTypes.contains(fileExtension)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invalid file type. Allowed types: ${_fileTypes.join(", ")}'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _isLoading = true;
        });

        try {
          // Upload file to Supabase Storage
          final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
          final filePath = '${widget.brandId}/lookbooks/$fileName';
          
          String? fileUrl;
          if (file.bytes != null) {
            // Web platform
            final uploadResult = await SupabaseService.instance.uploadFile(
              bucket: 'lookbooks',
              path: filePath,
              fileBytes: file.bytes!,
              contentType: 'application/${fileExtension}',
            );
            fileUrl = uploadResult;
          } else if (file.path != null) {
            // Mobile/Desktop platforms
            final uploadResult = await SupabaseService.instance.uploadFile(
              bucket: 'lookbooks',
              path: filePath,
              filePath: file.path!,
              contentType: 'application/${fileExtension}',
            );
            fileUrl = uploadResult;
          }

          if (fileUrl != null) {
            setState(() {
              _fileUrl = fileUrl;
              _selectedFileType = fileExtension;
            });
          } else {
            throw Exception('Failed to upload file');
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

  Future<void> _saveLookbook() async {
    print('Starting to save lookbook...');
    
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }
    
    if (_fileUrl == null) {
      print('No file URL available');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file')),
      );
      return;
    }

    print('File URL: $_fileUrl');
    print('Brand ID: ${widget.brandId}');
    print('Title: ${_titleController.text.trim()}');
    print('Description: ${_descriptionController.text.trim()}');
    print('File Type: $_selectedFileType');

    setState(() {
      _isLoading = true;
    });

    try {
      // Check storage buckets first
      final supabaseService = SupabaseService.instance;
      print('Checking storage buckets...');
      final buckets = await supabaseService.listStorageBuckets();
      print('Available buckets: $buckets');
      
      final lookbookData = {
        'brand_id': widget.brandId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'file_type': _selectedFileType,
        'file_url': _fileUrl,
      };

      print('Lookbook data to save: $lookbookData');

      Map<String, dynamic>? result;

      if (_isEditing) {
        print('Updating existing lookbook...');
        result = await supabaseService.updateBrandLookbook(
          widget.lookbook!['id'],
          lookbookData,
        );
      } else {
        print('Creating new lookbook...');
        result = await supabaseService.createBrandLookbook(lookbookData);
      }

      print('Database operation result: $result');

      if (result != null) {
        print('Lookbook saved successfully!');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing 
                ? 'Lookbook updated successfully!' 
                : 'Lookbook created successfully!'
              ),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        print('Database operation returned null');
        throw Exception('Failed to save lookbook - database returned null');
      }
    } catch (e) {
      print('Error saving lookbook: $e');
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
        title: Text(_isEditing ? 'Edit Lookbook' : 'Add Lookbook'),
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
                        _isEditing ? 'Edit Lookbook' : 'Add New Lookbook',
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
                          labelText: 'Title *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          return null;
                        },
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
                      
                      // File Type Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedFileType,
                        decoration: InputDecoration(
                          labelText: 'File Type *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _fileTypes.map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.toUpperCase()),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFileType = value!;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'File type is required';
                          }
                          return null;
                        },
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
                                  child: Text(
                                    'File Upload',
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
                            
                            if (_fileUrl != null) ...[
                              Container(
                                padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.file_present,
                                      color: AppTheme.primaryBlue,
                                      size: ResponsiveUtils.getIconSize(context, mobile: 20, tablet: 24, desktop: 28),
                                    ),
                                    SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                                    Expanded(
                                      child: Text(
                                        _fileUrl!,
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                          color: AppTheme.textMediumGray,
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
                                _fileUrl != null ? 'Change File' : 'Select File',
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
                              onPressed: _isLoading ? null : _saveLookbook,
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
                                      _isEditing ? 'Update Lookbook' : 'Create Lookbook',
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
