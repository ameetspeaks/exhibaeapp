import 'package:flutter/material.dart';
import 'package:exhibae/core/theme/app_theme.dart';
import 'package:exhibae/core/services/supabase_service.dart';
import 'package:exhibae/core/widgets/responsive_card.dart';
import 'package:exhibae/core/widgets/dashboard_loading_widget.dart';
import 'package:exhibae/core/widgets/dashboard_error_widget.dart';
import 'package:exhibae/core/widgets/dashboard_empty_widget.dart';
import 'brand_gallery_form_screen.dart';

class BrandGalleryListScreen extends StatefulWidget {
  final String brandId;

  const BrandGalleryListScreen({
    super.key,
    required this.brandId,
  });

  @override
  State<BrandGalleryListScreen> createState() => _BrandGalleryListScreenState();
}

class _BrandGalleryListScreenState extends State<BrandGalleryListScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  List<Map<String, dynamic>> _galleryItems = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadGalleryItems();
  }

  Future<void> _loadGalleryItems() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final items = await _supabaseService.getBrandGallery(widget.brandId);
      
      if (mounted) {
        setState(() {
          _galleryItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _addNewGalleryItem() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrandGalleryFormScreen(
          brandId: widget.brandId,
        ),
      ),
    );
    
    if (result == true) {
      _loadGalleryItems();
    }
  }

  Future<void> _editGalleryItem(Map<String, dynamic> galleryItem) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BrandGalleryFormScreen(
          galleryItem: galleryItem,
          brandId: widget.brandId,
        ),
      ),
    );
    
    if (result == true) {
      _loadGalleryItems();
    }
  }

  Future<void> _deleteGalleryItem(Map<String, dynamic> galleryItem) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Gallery Item'),
        content: Text('Are you sure you want to delete "${galleryItem['title'] ?? 'this image'}"? This action cannot be undone.'),
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
        await _supabaseService.deleteBrandGalleryItem(galleryItem['id']);
        _loadGalleryItems();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gallery item deleted successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete gallery item: ${e.toString()}')),
          );
        }
      }
    }
  }

  void _viewGalleryItem(Map<String, dynamic> galleryItem) {
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
                      const Icon(
                        Icons.image,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          galleryItem['title'] ?? 'Gallery Image',
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
                        if (galleryItem['description'] != null && galleryItem['description'].isNotEmpty) ...[
                          Text(
                            galleryItem['description'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // Image preview
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: galleryItem['image_url'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      galleryItem['image_url'],
                                      fit: BoxFit.contain,
                                      width: double.infinity,
                                      height: double.infinity,
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
                                          Icons.image_not_supported,
                                          size: 64,
                                          color: AppTheme.primaryMaroon,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No Image Available',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.primaryMaroon,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'This gallery item has no image',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
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
                              'Added ${_formatDate(galleryItem['created_at'])}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'IMAGE',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Gallery'),
        backgroundColor: AppTheme.backgroundPeach,
        foregroundColor: AppTheme.primaryMaroon,
        elevation: 0,
      ),
      body: _isLoading
          ? const DashboardLoadingWidget(message: 'Loading gallery items...')
          : _errorMessage != null
              ? DashboardErrorWidget(
                  message: 'Error loading gallery items: $_errorMessage',
                  onRetry: _loadGalleryItems,
                )
              : _buildGalleryContent(),
    );
  }

  Widget _buildGalleryContent() {
    if (_galleryItems.isEmpty) {
      return DashboardEmptyWidget(
        icon: Icons.photo_library_outlined,
        title: 'No Gallery Items Yet',
        message: 'Start building your brand portfolio by adding your first image.',
        onAction: _addNewGalleryItem,
        actionLabel: 'Add First Image',
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
                  'My Gallery (${_galleryItems.length})',
                  style: const TextStyle(
                    fontSize: 20, // Reduced from 24
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8), // Reduced from 12
              ElevatedButton.icon(
                onPressed: _addNewGalleryItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMaroon,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Reduced padding
                ),
                icon: const Icon(Icons.add_photo_alternate, size: 18), // Smaller icon
                label: const Text('Add New', style: TextStyle(fontSize: 12)), // Smaller text
              ),
            ],
          ),
          const SizedBox(height: 16), // Reduced from 24

          // Gallery Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
              childAspectRatio: MediaQuery.of(context).size.width > 600 ? 1.0 : 1.1,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _galleryItems.length,
            itemBuilder: (context, index) {
              return _buildGalleryCard(_galleryItems[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGalleryCard(Map<String, dynamic> galleryItem) {
    return ResponsiveCard(
      child: InkWell(
        onTap: () => _viewGalleryItem(galleryItem),
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Image section - 95% of the card
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.primaryMaroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: galleryItem['image_url'] != null
                      ? Image.network(
                          galleryItem['image_url'],
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
                                    Icons.image_not_supported,
                                    size: 32,
                                    color: AppTheme.primaryMaroon,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Image not available',
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
                                  Icons.image,
                                  size: 32,
                                  color: AppTheme.primaryMaroon,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'No Image',
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
                    // Title and date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (galleryItem['title'] != null) ...[
                            Text(
                              galleryItem['title'],
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          Text(
                            _formatDate(galleryItem['created_at']),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                            _viewGalleryItem(galleryItem);
                            break;
                          case 'edit':
                            _editGalleryItem(galleryItem);
                            break;
                          case 'delete':
                            _deleteGalleryItem(galleryItem);
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

  String _formatDate(dynamic date) {
    if (date == null) return 'recently';
    
    try {
      final DateTime dateTime = DateTime.parse(date.toString());
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes} min ago';
        }
        return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
      } else if (difference.inDays == 1) {
        return 'yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks week${weeks == 1 ? '' : 's'} ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'recently';
    }
  }
}
