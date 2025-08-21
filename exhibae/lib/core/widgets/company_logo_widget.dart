import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class CompanyLogoWidget extends StatefulWidget {
  final String userId;
  final String? currentLogoUrl;
  final double size;
  final bool showEditButton;
  final bool showDeleteButton;
  final Function(String?)? onLogoChanged;
  final Function()? onLogoDeleted;

  const CompanyLogoWidget({
    super.key,
    required this.userId,
    this.currentLogoUrl,
    this.size = 100,
    this.showEditButton = true,
    this.showDeleteButton = true,
    this.onLogoChanged,
    this.onLogoDeleted,
  });

  @override
  State<CompanyLogoWidget> createState() => _CompanyLogoWidgetState();
}

class _CompanyLogoWidgetState extends State<CompanyLogoWidget> {
  final _imagePicker = ImagePicker();
  final _supabaseService = SupabaseService.instance;
  
  String? _logoUrl;
  File? _selectedImageFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _logoUrl = widget.currentLogoUrl;
  }

  @override
  void didUpdateWidget(CompanyLogoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLogoUrl != widget.currentLogoUrl) {
      setState(() {
        _logoUrl = widget.currentLogoUrl;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
        
        // Auto-upload the selected image
        await _uploadCompanyLogo();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _uploadCompanyLogo() async {
    if (_selectedImageFile == null) return;
    
    setState(() {
      _isUploading = true;
    });
    
    try {
      // First, try to ensure the bucket exists with enhanced error handling
      final bucketExists = await _supabaseService.ensureProfileAvatarsBucket();
      
              if (!bucketExists) {
          // If bucket creation failed, show helpful error message
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Storage bucket not available. Please ensure the profile-avatars bucket is created in Supabase Dashboard.'),
                backgroundColor: AppTheme.errorRed,
                duration: Duration(seconds: 5),
              ),
            );
          }
          return;
        }
      
      final uploadedUrl = await _supabaseService.uploadCompanyLogo(
        userId: widget.userId,
        filePath: _selectedImageFile!.path,
      );
      
      if (uploadedUrl != null) {
        setState(() {
          _logoUrl = uploadedUrl;
          _selectedImageFile = null;
        });
        
        // Notify parent widget
        widget.onLogoChanged?.call(uploadedUrl);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Company logo updated successfully!'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading company logo: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _deleteCompanyLogo() async {
    try {
      await _supabaseService.deleteCompanyLogo(widget.userId);
      
      setState(() {
        _logoUrl = null;
        _selectedImageFile = null;
      });
      
      // Notify parent widget
      widget.onLogoDeleted?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Company logo deleted successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting company logo: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Logo Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Company Logo'),
          content: const Text('Are you sure you want to delete your company logo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteCompanyLogo();
              },
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.errorRed,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: ClipOval(
                child: _selectedImageFile != null
                    ? Image.file(
                        _selectedImageFile!,
                        fit: BoxFit.cover,
                        width: widget.size,
                        height: widget.size,
                      )
                    : (_logoUrl != null
                        ? Image.network(
                            _logoUrl!,
                            fit: BoxFit.cover,
                            width: widget.size,
                            height: widget.size,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: widget.size,
                                height: widget.size,
                                color: Colors.grey.shade200,
                                child: Icon(
                                  Icons.business,
                                  size: widget.size * 0.4,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
                        : Container(
                            width: widget.size,
                            height: widget.size,
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.business,
                              size: widget.size * 0.4,
                              color: Colors.grey,
                            ),
                          )),
              ),
            ),
            if (_isUploading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
        if (widget.showEditButton || (widget.showDeleteButton && _logoUrl != null)) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.showEditButton)
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _showImageSourceDialog,
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('Change Logo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMaroon,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              if (widget.showDeleteButton && _logoUrl != null) ...[
                if (widget.showEditButton) const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _showDeleteConfirmation,
                  icon: const Icon(Icons.delete, size: 16),
                  label: const Text('Remove'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}
