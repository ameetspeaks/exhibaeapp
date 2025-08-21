import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

class ProfilePictureWidget extends StatefulWidget {
  final String userId;
  final String? currentAvatarUrl;
  final double size;
  final bool showEditButton;
  final bool showDeleteButton;
  final Function(String?)? onAvatarChanged;
  final Function()? onAvatarDeleted;

  const ProfilePictureWidget({
    super.key,
    required this.userId,
    this.currentAvatarUrl,
    this.size = 100,
    this.showEditButton = true,
    this.showDeleteButton = true,
    this.onAvatarChanged,
    this.onAvatarDeleted,
  });

  @override
  State<ProfilePictureWidget> createState() => _ProfilePictureWidgetState();
}

class _ProfilePictureWidgetState extends State<ProfilePictureWidget> {
  final _imagePicker = ImagePicker();
  final _supabaseService = SupabaseService.instance;
  
  String? _avatarUrl;
  File? _selectedImageFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _avatarUrl = widget.currentAvatarUrl;
  }

  @override
  void didUpdateWidget(ProfilePictureWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentAvatarUrl != widget.currentAvatarUrl) {
      setState(() {
        _avatarUrl = widget.currentAvatarUrl;
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
        await _uploadProfilePicture();
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

  Future<void> _uploadProfilePicture() async {
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
      
      final uploadedUrl = await _supabaseService.uploadProfilePicture(
        userId: widget.userId,
        filePath: _selectedImageFile!.path,
      );
      
      if (uploadedUrl != null) {
        setState(() {
          _avatarUrl = uploadedUrl;
          _selectedImageFile = null;
        });
        
        // Notify parent widget
        widget.onAvatarChanged?.call(uploadedUrl);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading profile picture: $e'),
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

  Future<void> _deleteProfilePicture() async {
    try {
      await _supabaseService.deleteProfilePicture(widget.userId);
      
      setState(() {
        _avatarUrl = null;
        _selectedImageFile = null;
      });
      
      // Notify parent widget
      widget.onAvatarDeleted?.call();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture deleted successfully!'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting profile picture: $e'),
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
          title: const Text('Select Image Source'),
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
          title: const Text('Delete Profile Picture'),
          content: const Text('Are you sure you want to delete your profile picture?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteProfilePicture();
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
            CircleAvatar(
              radius: widget.size / 2,
              backgroundImage: _selectedImageFile != null
                  ? FileImage(_selectedImageFile!)
                  : (_avatarUrl != null
                      ? NetworkImage(_avatarUrl!)
                      : null),
              child: (_selectedImageFile == null && _avatarUrl == null)
                  ? Icon(
                      Icons.person,
                      size: widget.size * 0.6,
                      color: Colors.grey,
                    )
                  : null,
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
        if (widget.showEditButton || (widget.showDeleteButton && _avatarUrl != null)) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.showEditButton)
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _showImageSourceDialog,
                  icon: const Icon(Icons.camera_alt, size: 16),
                  label: const Text('Change'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMaroon,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              if (widget.showDeleteButton && _avatarUrl != null) ...[
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
