import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/supabase_service.dart';

class ExhibitionCard extends StatefulWidget {
  final Map<String, dynamic> exhibition;
  final bool isListView;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  const ExhibitionCard({
    super.key,
    required this.exhibition,
    required this.isListView,
    required this.onTap,
    required this.onFavorite,
  });

  @override
  State<ExhibitionCard> createState() => _ExhibitionCardState();
}

class _ExhibitionCardState extends State<ExhibitionCard> {
  int _currentBannerIndex = 0;
  int _currentGalleryIndex = 0;
  late PageController _bannerPageController;
  late PageController _galleryPageController;
  List<Map<String, dynamic>> _galleryImages = [];
  bool _isLoadingImages = true;
  bool _isFavorite = false;
  bool _isLoadingFavorite = true;

  @override
  void initState() {
    super.initState();
    _bannerPageController = PageController();
    _galleryPageController = PageController();
    _loadGalleryImages();
    _checkFavoriteStatus();
  }

  @override
  void dispose() {
    _bannerPageController.dispose();
    _galleryPageController.dispose();
    super.dispose();
  }

  Future<void> _loadGalleryImages() async {
    try {
      final supabaseService = SupabaseService.instance;
      final images = await supabaseService.getGalleryImages(widget.exhibition['id']);
      
      if (mounted) {
        setState(() {
          _galleryImages = images;
          _isLoadingImages = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingImages = false;
        });
      }
    }
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final supabaseService = SupabaseService.instance;
      final currentUser = supabaseService.currentUser;
      
      if (currentUser != null) {
        final isFavorited = await supabaseService.isExhibitionFavorited(
          currentUser.id,
          widget.exhibition['id'],
        );
        
        if (mounted) {
          setState(() {
            _isFavorite = isFavorited;
            _isLoadingFavorite = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _isLoadingFavorite = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingFavorite = false;
        });
      }
    }
  }

  Future<void> _handleFavoriteToggle() async {
    try {
      final supabaseService = SupabaseService.instance;
      final currentUser = supabaseService.currentUser;
      
      if (currentUser == null) {
        // Show login required message
        return;
      }
      
      // Optimistically update UI
      setState(() {
        _isFavorite = !_isFavorite;
      });
      
      // Call the original onFavorite callback if provided
      if (widget.onFavorite != null) {
        widget.onFavorite();
      }
      
      // Toggle in database
      await supabaseService.toggleExhibitionFavorite(
        currentUser.id,
        widget.exhibition['id'],
      );
      
      // Verify the status after toggle
      await _checkFavoriteStatus();
      
    } catch (e) {
      // Revert optimistic update on error
      setState(() {
        _isFavorite = !_isFavorite;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating favorite: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  List<String> get _bannerImages {
    // Get banner images from gallery (image_type = 'banner')
    final bannerImages = _galleryImages
        .where((img) => img['image_type'] == 'banner')
        .map((img) => img['image_url'] as String)
        .toList();
    
    return bannerImages;
  }

  List<String> get _galleryImagesUrls {
    // Get all gallery images (excluding banners)
    final galleryImages = _galleryImages
        .where((img) => img['image_type'] != 'banner')
        .map((img) => img['image_url'] as String)
        .toList();
    
    return galleryImages;
  }

  List<String> get _allImages {
    final allImages = <String>[];
    allImages.addAll(_bannerImages);
    allImages.addAll(_galleryImagesUrls);
    return allImages;
  }

  // Get the primary image to display (banner first, then first gallery image, then default)
  String? get _primaryImage {
    if (_bannerImages.isNotEmpty) {
      return _bannerImages.first;
    } else if (_galleryImagesUrls.isNotEmpty) {
      return _galleryImagesUrls.first;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isListView) {
      return _buildListCard(context);
    } else {
      return _buildGridCard(context);
    }
  }

  Widget _buildListCard(BuildContext context) {
    final availableStalls = widget.exhibition['availableStalls'] ?? 0;
    final priceRange = widget.exhibition['priceRange'];
    final hasImages = _allImages.isNotEmpty;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPeach,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.borderLightGray,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section with Favorite Button
          Stack(
            children: [
              // Banner Image Slider
              if (_bannerImages.isNotEmpty) _buildBannerSlider(context, 200),
              
              // Gallery Images Slider (if no banner, show gallery first)
              if (_galleryImagesUrls.isNotEmpty && _bannerImages.isEmpty) _buildGallerySlider(context, 200),
              
              // Fallback to single image or default icon
              if (_allImages.isEmpty) _buildDefaultImageSection(context, 200),
              
              // Loading indicator
              if (_isLoadingImages) _buildLoadingSection(context, 200),
              
              // Favorite Button
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: _handleFavoriteToggle,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundPeach,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppTheme.borderLightGray,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isLoadingFavorite
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
                          ),
                        )
                      : Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? AppTheme.errorRed : Colors.black.withOpacity(0.6),
                          size: 20,
                        ),
                  ),
                ),
              ),
            ],
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  widget.exhibition['title'] ?? 'Untitled Exhibition',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Date and Location
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryMaroon.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                      Icons.calendar_today,
                      size: 16,
                        color: AppTheme.primaryMaroon,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.exhibition['date'] ?? 'Date not specified',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.black.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  widget.exhibition['location'] ?? 'Location not specified',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Available Stalls and Price
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryMaroon.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                      Icons.storefront,
                      size: 16,
                        color: AppTheme.primaryMaroon,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                      availableStalls > 0 
                        ? '$availableStalls stalls available'
                        : 'No stalls available',
                      style: TextStyle(
                        fontSize: 14,
                        color: availableStalls > 0 ? Colors.black : Colors.black.withOpacity(0.6),
                        fontWeight: availableStalls > 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    ),
                    if (priceRange != null && priceRange != 'Contact for pricing')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryMaroon.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                        priceRange,
                        style: const TextStyle(
                            fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryMaroon,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _navigateToExhibitionDetails(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryMaroon,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'View Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridCard(BuildContext context) {
    final availableStalls = widget.exhibition['availableStalls'] ?? 0;
    final priceRange = widget.exhibition['priceRange'];
    final hasImages = _allImages.isNotEmpty;
    
    return GestureDetector(
      onTap: () => _navigateToExhibitionDetails(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundPeach,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.borderLightGray,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section with Favorite Button
            Stack(
              children: [
                // Banner Image Slider
                if (_bannerImages.isNotEmpty) _buildBannerSlider(context, 140),
                
                // Gallery Images Slider (if no banner, show gallery first)
                if (_galleryImagesUrls.isNotEmpty && _bannerImages.isEmpty) _buildGallerySlider(context, 140),
                
                // Fallback to single image or default icon
                if (_allImages.isEmpty) _buildDefaultImageSection(context, 140),
                
                // Loading indicator
                if (_isLoadingImages) _buildLoadingSection(context, 140),
                
                // Favorite Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: _handleFavoriteToggle,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundPeach,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.borderLightGray,
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: _isLoadingFavorite
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
                            ),
                          )
                        : Icon(
                            _isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: _isFavorite ? AppTheme.errorRed : Colors.black.withOpacity(0.6),
                            size: 18,
                          ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Content
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      widget.exhibition['title'] ?? 'Untitled Exhibition',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    
                    // Date
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 8,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            widget.exhibition['date'] ?? 'Date not specified',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryMaroon,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 1),
                    
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 8,
                          color: AppTheme.primaryBlue,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            widget.exhibition['location'] ?? 'Location not specified',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.primaryMaroon,
                            ),
                            overflow: TextOverflow.ellipsis,
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

  Widget _buildBannerSlider(BuildContext context, double height) {
    return Stack(
      children: [
        Container(
          height: height,
          width: double.infinity,
          child: PageView.builder(
            controller: _bannerPageController,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index;
              });
            },
            itemCount: _bannerImages.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showImagePopup(context, _bannerImages[index]),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Image.network(
                      _bannerImages[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: height,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultIcon(height: height);
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: height,
                          color: AppTheme.primaryMaroon.withOpacity(0.1),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / 
                                    loadingProgress.expectedTotalBytes!
                                  : null,
                              color: AppTheme.primaryMaroon,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Page indicator
        if (_bannerImages.length > 1)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_bannerImages.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentBannerIndex == index 
                        ? AppTheme.primaryMaroon 
                        : AppTheme.primaryMaroon.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildGallerySlider(BuildContext context, double height) {
    return Stack(
      children: [
        Container(
          height: height,
          width: double.infinity,
          child: PageView.builder(
            controller: _galleryPageController,
            onPageChanged: (index) {
              setState(() {
                _currentGalleryIndex = index;
              });
            },
            itemCount: _galleryImagesUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showImagePopup(context, _galleryImagesUrls[index]),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Image.network(
                      _galleryImagesUrls[index],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: height,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultIcon(height: height);
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: height,
                          color: AppTheme.primaryMaroon.withOpacity(0.1),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / 
                                    loadingProgress.expectedTotalBytes!
                                  : null,
                              color: AppTheme.primaryMaroon,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Page indicator
        if (_galleryImagesUrls.length > 1)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_galleryImagesUrls.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentGalleryIndex == index 
                        ? AppTheme.primaryMaroon 
                        : AppTheme.primaryMaroon.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }

  Widget _buildDefaultImageSection(BuildContext context, double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.secondaryWarm,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: _buildDefaultIcon(height: height),
    );
  }

  Widget _buildLoadingSection(BuildContext context, double height) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.primaryMaroon.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryMaroon,
        ),
      ),
    );
  }

  Widget _buildDefaultIcon({double? height}) {
    final iconSize = height != null ? (height * 0.3) : 40.0;
    return Center(
      child: Icon(
      Icons.event,
        size: iconSize,
      color: AppTheme.primaryMaroon,
      ),
    );
  }

  void _navigateToExhibitionDetails(BuildContext context) {
    Navigator.pushNamed(
      context,
      '/exhibition-details',
      arguments: {'exhibition': widget.exhibition},
    );
  }

  static void _showImagePopup(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // Full screen image
              Center(
                child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                        width: 300,
                        height: 300,
                      color: AppTheme.backgroundLightGray,
                        child: const Center(
                          child: Icon(
                        Icons.error,
                            size: 50,
                        color: AppTheme.errorRed,
                          ),
                      ),
                    );
                  },
                ),
              ),
              ),
              // Close button
              Positioned(
                top: 40,
                right: 20,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
