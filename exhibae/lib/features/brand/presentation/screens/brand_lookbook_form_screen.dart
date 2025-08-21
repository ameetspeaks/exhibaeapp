
import 'package:flutter/material.dart';
import 'package:exhibae/core/theme/app_theme.dart';
import 'package:exhibae/core/utils/responsive_utils.dart';
import 'package:exhibae/core/widgets/responsive_card.dart';
import 'package:exhibae/core/services/supabase_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data'; // Added for Uint8List

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
  String? _fileUrl;
  String? _fileName;
  int? _fileSize;
  bool _isLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.lookbook != null;
    if (_isEditing) {
      _fileUrl = widget.lookbook!['file_url'];
      _fileName = widget.lookbook!['file_name'] ?? 'Current File';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileExtension = path.extension(file.name).toLowerCase().replaceAll('.', '');

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

          // Validate that the user is uploading to their own brand folder
          final userBrandId = supabaseService.getCurrentUserBrandId();
          if (userBrandId != widget.brandId) {
            print('Warning: User brand ID ($userBrandId) does not match widget brand ID (${widget.brandId})'); // Debug log
            // You might want to add additional validation here
          }

          // Use shared lookbooks bucket
          final bucketName = 'lookbooks';
          print('Using shared lookbooks bucket: $bucketName'); // Debug log
          print('Uploading for brand ID: ${widget.brandId}'); // Debug log
          
          // Generate unique filename
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final fileName = '${timestamp}_${file.name}';
          
          // Create path: {brand_id}/{filename}
          final path = '${widget.brandId}/$fileName';
          print('Upload path: $path'); // Debug log
          
          String? uploadedUrl;
          
          try {
            // Upload file directly to lookbooks bucket (same pattern as organizer gallery)
            if (file.bytes != null) {
              // Web platform - upload from bytes
              await supabaseService.client.storage
                  .from(bucketName)
                  .uploadBinary(path, file.bytes!);
              uploadedUrl = supabaseService.getPublicUrl(bucketName, path);
            } else if (file.path != null) {
              // Mobile/Desktop platforms - upload from file path
              await supabaseService.client.storage
                  .from(bucketName)
                  .upload(path, File(file.path!));
              uploadedUrl = supabaseService.getPublicUrl(bucketName, path);
            } else {
              throw Exception('No file data available (bytes or path)');
            }
            
            print('File uploaded successfully: $uploadedUrl'); // Debug log
          } catch (uploadError) {
            print('Upload error: $uploadError'); // Debug log
            throw Exception('Failed to upload file: $uploadError');
          }

          print('Upload result URL: $uploadedUrl'); // Debug log

          if (uploadedUrl != null) {
            setState(() {
              _fileUrl = uploadedUrl;
              _fileName = file.name;
              _fileSize = file.size;
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('File uploaded successfully: ${file.name}'),
                  backgroundColor: AppTheme.successGreen,
                ),
              );
            }
          } else {
            throw Exception('Failed to upload file to storage - upload returned null URL');
          }
        } catch (e) {
          print('Upload error details: $e'); // Debug logging
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error uploading file: ${e.toString()}'),
                backgroundColor: AppTheme.errorRed,
              ),
            );
          }
        }
        
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('File picker error: $e'); // Debug logging
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _previewFile() async {
    if (_fileUrl == null) return;
    
    try {
      final uri = Uri.parse(_fileUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'ppt':
        return 'application/vnd.ms-powerpoint';
      case 'pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'avi':
        return 'video/x-msvideo';
      default:
        return 'application/octet-stream';
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null) return 'Unknown size';
    
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  IconData _getFileTypeIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _saveLookbook() async {
    if (_fileUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file'),
          backgroundColor: AppTheme.warningOrange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabaseService = SupabaseService.instance;
      
      final lookbookData = {
        'brand_id': widget.brandId,
        'file_url': _fileUrl,
        'file_name': _fileName,
        'file_size': _fileSize,
      };

      Map<String, dynamic>? result;

      if (_isEditing) {
        result = await supabaseService.updateBrandLookbook(
          widget.lookbook!['id'],
          lookbookData,
        );
      } else {
        result = await supabaseService.createBrandLookbook(lookbookData);
      }

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_isEditing 
                ? 'Lookbook updated successfully!' 
                : 'Lookbook created successfully!'
              ),
              backgroundColor: AppTheme.successGreen,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to save lookbook - database returned null');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
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

  Future<void> _debugStorage() async {
    try {
      final supabaseService = SupabaseService.instance;
      final bucketName = 'lookbooks'; // Shared bucket
      
      // Check storage permissions
      final hasPermissions = await supabaseService.checkStoragePermissions();
      
      // Check network connectivity
      final hasNetwork = await supabaseService.checkNetworkConnectivity();
      
      // Check shared lookbooks bucket
      final bucketExists = await supabaseService.checkStorageBucketExists(bucketName);
      final allBuckets = await supabaseService.listStorageBuckets();
      
      // Get bucket details if it exists
      Map<String, dynamic>? bucketDetails;
      if (bucketExists) {
        try {
          final bucket = await supabaseService.client.storage.getBucket(bucketName);
          bucketDetails = {
            'name': bucket.name,
            'public': bucket.public,
            'file_size_limit': bucket.fileSizeLimit,
            'allowed_mime_types': bucket.allowedMimeTypes,
          };
        } catch (e) {
          bucketDetails = {'error': e.toString()};
        }
      }
      
      // List files in brand folder
      final brandFiles = await supabaseService.listBrandLookbookFiles(widget.brandId);
      
      // Get current user info
      final currentUser = supabaseService.currentUser;
      final userBrandId = supabaseService.getCurrentUserBrandId();
      
      final debugInfo = {
        'brand_id': widget.brandId,
        'bucket_name': bucketName,
        'bucket_exists': bucketExists,
        'has_permissions': hasPermissions,
        'has_network': hasNetwork,
        'current_user': currentUser?.id ?? 'No user',
        'user_brand_id': userBrandId,
        'all_buckets': allBuckets,
        'bucket_details': bucketDetails,
        'brand_files': brandFiles,
        'brand_folder_path': 'lookbooks/${widget.brandId}/',
        'error': null,
      };
      
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Lookbooks Storage Debug Info'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Brand ID: ${debugInfo['brand_id']}'),
                  const SizedBox(height: 8),
                  Text('User Brand ID: ${debugInfo['user_brand_id']}'),
                  const SizedBox(height: 8),
                  Text('Bucket Name: ${debugInfo['bucket_name']}'),
                  const SizedBox(height: 8),
                  Text('Bucket Exists: ${debugInfo['bucket_exists']}'),
                  const SizedBox(height: 8),
                  Text('Has Permissions: ${debugInfo['has_permissions']}'),
                  const SizedBox(height: 8),
                  Text('Has Network: ${debugInfo['has_network']}'),
                  const SizedBox(height: 8),
                  Text('Current User: ${debugInfo['current_user']}'),
                  const SizedBox(height: 8),
                  Text('Brand Folder Path: ${debugInfo['brand_folder_path']}'),
                  const SizedBox(height: 8),
                  Text('Brand Files (${brandFiles.length}): ${brandFiles.join(', ')}'),
                  const SizedBox(height: 8),
                  Text('All Buckets: ${debugInfo['all_buckets']}'),
                  if (debugInfo['bucket_details'] != null) ...[
                    const SizedBox(height: 8),
                    Text('Bucket Details: ${debugInfo['bucket_details']}'),
                  ],
                  if (debugInfo['error'] != null) ...[
                    const SizedBox(height: 8),
                    Text('Error: ${debugInfo['error']}', style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 16),
                  if (debugInfo['bucket_exists'] == false) ...[
                    const Text(
                      'Lookbooks bucket does not exist. You can create it manually:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (debugInfo['has_permissions'] == false) ...[
                    const Text(
                      'No storage permissions. Check your authentication.',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            actions: [
              if (debugInfo['bucket_exists'] == false) ...[
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _createBucketManually();
                  },
                  child: const Text('Create Lookbooks Bucket'),
                ),
              ],
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Debug error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _createBucketManually() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final supabaseService = SupabaseService.instance;
      final success = await supabaseService.createStorageBucket('lookbooks', isPublic: true);
      
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lookbooks bucket created successfully!'),
              backgroundColor: AppTheme.successGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to create lookbooks bucket. Check your Supabase configuration.'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating bucket: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
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
      backgroundColor: AppTheme.backgroundPeach,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Lookbook' : 'Add Lookbook'),
        backgroundColor: AppTheme.primaryMaroon,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditing ? 'Edit Lookbook' : 'Add New Lookbook',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getFontSize(context, mobile: 24, tablet: 28, desktop: 32),
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 24, tablet: 32, desktop: 40)),
                      
                      // File Upload Section
                      Container(
                        padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 20, desktop: 24)),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryMaroon.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                                                      border: Border.all(
                              color: AppTheme.primaryMaroon.withOpacity(0.3),
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
                                   color: AppTheme.primaryMaroon,
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
                                           color: Colors.black,
                                         ),
                                       ),
                                       Text(
                                         'Upload any file type (PDF, images, videos, documents, etc.)',
                                         style: TextStyle(
                                           fontSize: ResponsiveUtils.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                           color: Colors.grey[600],
                                         ),
                                       ),
                                     ],
                                   ),
                                 ),
                              // Debug button (temporary)
                              IconButton(
                                onPressed: _debugStorage,
                                icon: Icon(
                                  Icons.bug_report,
                                  color: AppTheme.warningOrange,
                                  size: ResponsiveUtils.getIconSize(context, mobile: 20, tablet: 24, desktop: 28),
                                ),
                                tooltip: 'Debug Storage',
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
                                  color: AppTheme.primaryMaroon.withOpacity(0.2),
                                  width: 1,
                                ),
                                ),
                                child: Row(
                                  children: [
                                  Container(
                                    padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 10, desktop: 12)),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryMaroon.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      _getFileTypeIcon(_fileName?.split('.').last ?? ''),
                                      color: AppTheme.primaryMaroon,
                                      size: ResponsiveUtils.getIconSize(context, mobile: 20, tablet: 24, desktop: 28),
                                    ),
                                  ),
                                  SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                                    Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _fileName!,
                                        style: TextStyle(
                                            fontSize: ResponsiveUtils.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                        Text(
                                          _formatFileSize(_fileSize),
                                          style: TextStyle(
                                            fontSize: ResponsiveUtils.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _previewFile,
                                    icon: Icon(
                                      Icons.open_in_new,
                                      color: AppTheme.primaryMaroon,
                                      size: ResponsiveUtils.getIconSize(context, mobile: 20, tablet: 24, desktop: 28),
                                    ),
                                    tooltip: 'Preview File',
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _fileUrl = null;
                                        _fileName = null;
                                        _fileSize = null;
                                        });
                                      },
                                      icon: Icon(
                                        Icons.close,
                                      color: AppTheme.errorRed,
                                      size: ResponsiveUtils.getIconSize(context, mobile: 20, tablet: 24, desktop: 28),
                                      ),
                                    tooltip: 'Remove File',
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                            ],
                            
                            ElevatedButton.icon(
                            onPressed: _isLoading ? null : _pickFile,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryMaroon,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: ResponsiveUtils.getSpacing(context, mobile: 20, tablet: 24, desktop: 28),
                                  vertical: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            icon: _isLoading
                                ? SizedBox(
                                    height: ResponsiveUtils.getIconSize(context, mobile: 18, tablet: 20, desktop: 22),
                                    width: ResponsiveUtils.getIconSize(context, mobile: 18, tablet: 20, desktop: 22),
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : Icon(
                                Icons.upload,
                                size: ResponsiveUtils.getIconSize(context, mobile: 18, tablet: 20, desktop: 22),
                              ),
                                                             label: Text(
                              _isLoading ? 'Uploading...' : (_fileUrl != null ? 'Change File' : 'Select Any File'),
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
                                side: BorderSide(color: AppTheme.primaryMaroon),
                              ),
                              child: Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                                  color: AppTheme.primaryMaroon,
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
                                backgroundColor: AppTheme.primaryMaroon,
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
    );
  }
}
