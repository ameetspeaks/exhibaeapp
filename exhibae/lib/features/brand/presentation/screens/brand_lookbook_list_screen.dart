import 'package:flutter/material.dart';
import 'package:exhibae/core/theme/app_theme.dart';
import 'package:exhibae/core/services/supabase_service.dart';
import 'package:exhibae/core/widgets/responsive_card.dart';
import 'package:exhibae/core/widgets/dashboard_loading_widget.dart';
import 'package:exhibae/core/widgets/dashboard_error_widget.dart';
import 'package:exhibae/core/widgets/dashboard_empty_widget.dart';
import 'brand_lookbook_form_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class BrandLookbookListScreen extends StatefulWidget {
  final String brandId;

  const BrandLookbookListScreen({
    super.key,
    required this.brandId,
  });

  @override
  State<BrandLookbookListScreen> createState() => _BrandLookbookListScreenState();
}

class _BrandLookbookListScreenState extends State<BrandLookbookListScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  List<Map<String, dynamic>> _lookbooks = [];
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadLookbooks();
  }

  Future<void> _loadLookbooks() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final lookbooks = await _supabaseService.getBrandLookbooks(widget.brandId);
      setState(() {
        _lookbooks = lookbooks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _addNewLookbook() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrandLookbookFormScreen(
          brandId: widget.brandId,
        ),
      ),
    );

    if (result == true) {
      _loadLookbooks();
    }
  }

  Future<void> _editLookbook(Map<String, dynamic> lookbook) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrandLookbookFormScreen(
          lookbook: lookbook,
          brandId: widget.brandId,
        ),
      ),
    );

    if (result == true) {
      _loadLookbooks();
    }
  }

  Future<void> _deleteLookbook(Map<String, dynamic> lookbook) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lookbook'),
        content: Text('Are you sure you want to delete "${lookbook['file_name']}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _supabaseService.deleteBrandLookbook(lookbook['id']);
        _loadLookbooks();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lookbook deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete lookbook: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _viewLookbook(Map<String, dynamic> lookbook) {
    final fileName = lookbook['file_name'] ?? 'Untitled File';
    final fileType = _getFileTypeFromName(fileName);
    final isImage = _isImageFile(fileType);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMaroon,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getFileTypeIcon(fileType),
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // File preview
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: isImage && lookbook['file_url'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      lookbook['file_url'],
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stackTrace) => Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.image_not_supported,
                                              size: 48,
                                              color: Colors.grey[400],
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              'Image not available',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _getFileTypeIcon(fileType),
                                          size: 64,
                                          color: AppTheme.primaryMaroon,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          fileType?.toUpperCase() ?? 'FILE',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryMaroon,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Preview not available',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        ElevatedButton.icon(
                                          onPressed: () {
                                            // Open file in external viewer
                                            if (lookbook['file_url'] != null) {
                                              launchUrl(Uri.parse(lookbook['file_url']));
                                            }
                                          },
                                          icon: const Icon(Icons.open_in_new),
                                          label: const Text('Open File'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppTheme.primaryMaroon,
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Footer info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Added ${_formatDate(lookbook['created_at'])}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              fileType?.toUpperCase() ?? 'FILE',
                              style: TextStyle(
                                color: AppTheme.primaryMaroon,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _getFileTypeIcon(String? fileType) {
    if (fileType == null) return Icons.insert_drive_file;
    
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

  String _formatFileSize(int? bytes) {
    if (bytes == null) return 'Unknown size';
    
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '${weeks}w ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _getFileTypeFromName(String fileName) {
    final lowerCaseName = fileName.toLowerCase();
    if (lowerCaseName.endsWith('.pdf')) return 'pdf';
    if (lowerCaseName.endsWith('.doc') || lowerCaseName.endsWith('.docx')) return 'doc';
    if (lowerCaseName.endsWith('.ppt') || lowerCaseName.endsWith('.pptx')) return 'ppt';
    if (lowerCaseName.endsWith('.xls') || lowerCaseName.endsWith('.xlsx')) return 'xls';
    if (lowerCaseName.endsWith('.jpg') || lowerCaseName.endsWith('.jpeg') || lowerCaseName.endsWith('.png') || lowerCaseName.endsWith('.gif')) return 'image';
    if (lowerCaseName.endsWith('.mp4') || lowerCaseName.endsWith('.mov') || lowerCaseName.endsWith('.avi')) return 'video';
    return 'unknown';
  }

  bool _isImageFile(String fileType) {
    return fileType == 'image';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      appBar: AppBar(
        title: const Text('My Look Book'),
        backgroundColor: AppTheme.primaryMaroon,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _addNewLookbook,
            icon: const Icon(Icons.add),
            tooltip: 'Add New Lookbook',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadLookbooks,
        color: AppTheme.primaryMaroon,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const DashboardLoadingWidget();
    }

    if (_hasError) {
      return DashboardErrorWidget(
        message: _errorMessage,
        onRetry: _loadLookbooks,
      );
    }

    if (_lookbooks.isEmpty) {
      return DashboardEmptyWidget(
        icon: Icons.book,
        title: 'No Lookbooks Yet',
        message: 'Start building your brand portfolio by adding your first lookbook.',
        onAction: _addNewLookbook,
        actionLabel: 'Add First Lookbook',
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12), // Reduced from 16
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'My Lookbooks (${_lookbooks.length})',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8), // Reduced from 12
              ElevatedButton.icon(
                onPressed: _addNewLookbook,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMaroon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add New', style: TextStyle(fontSize: 12)), // Reduced from 14
              ),
            ],
          ),
          const SizedBox(height: 16), // Reduced from 24
          
          // Lookbooks Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
              childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.0 : 1.1,
              crossAxisSpacing: 12, // Reduced from 16
              mainAxisSpacing: 12, // Reduced from 16
            ),
            itemCount: _lookbooks.length,
            itemBuilder: (context, index) => _buildLookbookCard(_lookbooks[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildLookbookCard(Map<String, dynamic> lookbook) {
    final fileName = lookbook['file_name'] ?? 'Untitled File';
    final fileSize = lookbook['file_size'];
    final fileType = _getFileTypeFromName(fileName);
    final isImage = _isImageFile(fileType);
    
    return ResponsiveCard(
      child: InkWell(
        onTap: () => _viewLookbook(lookbook),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Image/File section - 95% of the card
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryMaroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: isImage && lookbook['file_url'] != null
                      ? Image.network(
                          lookbook['file_url'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: double.infinity,
                            height: double.infinity,
                            color: Colors.grey[200],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _getFileTypeIcon(fileType),
                                    size: 32,
                                    color: AppTheme.primaryMaroon,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'File not available',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.primaryMaroon,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.grey[200],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / 
                                        loadingProgress.expectedTotalBytes!
                                      : null,
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
                                ),
                              ),
                            );
                          },
                        )
                      : Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: Colors.grey[200],
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _getFileTypeIcon(fileType),
                                  size: 32,
                                  color: AppTheme.primaryMaroon,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  fileType?.toUpperCase() ?? 'FILE',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryMaroon,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
            // Overlay content - 5% area at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // File name and info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            fileName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Text(
                                fileType?.toUpperCase() ?? 'FILE',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white70,
                                ),
                              ),
                              if (fileSize != null) ...[
                                const Text(' • ', style: TextStyle(color: Colors.white70, fontSize: 10)),
                                Text(
                                  _formatFileSize(fileSize),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Menu button
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white, size: 16),
                      onSelected: (value) {
                        switch (value) {
                          case 'view':
                            _viewLookbook(lookbook);
                            break;
                          case 'edit':
                            _editLookbook(lookbook);
                            break;
                          case 'delete':
                            _deleteLookbook(lookbook);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility),
                              SizedBox(width: 8),
                              Text('View'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
