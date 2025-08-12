import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_router.dart';

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

  @override
  void initState() {
    super.initState();
    _bannerPageController = PageController();
    _galleryPageController = PageController();
  }

  @override
  void dispose() {
    _bannerPageController.dispose();
    _galleryPageController.dispose();
    super.dispose();
  }

  List<String> get _bannerImages {
    // Check for banner_image first, then fallback to image_url
    final bannerImage = widget.exhibition['banner_image'];
    final imageUrl = widget.exhibition['image_url'];
    
    if (bannerImage != null && bannerImage.isNotEmpty) {
      return [bannerImage];
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      return [imageUrl];
    }
    return [];
  }

  List<String> get _galleryImages {
    final images = widget.exhibition['images'] as List<dynamic>? ?? [];
    if (images.isNotEmpty) {
      // Convert to URLs using SupabaseService if needed
      return images.map((img) {
        if (img is String) {
          // If it's already a URL, return as is
          if (img.startsWith('http')) {
            return img;
          }
          // If it's a file path, construct the URL
          return img;
        }
        return img.toString();
      }).toList();
    }
    return [];
  }

  List<String> get _allImages {
    final allImages = <String>[];
    allImages.addAll(_bannerImages);
    allImages.addAll(_galleryImages);
    return allImages;
  }

  // Get the primary image to display (banner first, then first gallery image, then default)
  String? get _primaryImage {
    if (_bannerImages.isNotEmpty) {
      return _bannerImages.first;
    } else if (_galleryImages.isNotEmpty) {
      return _galleryImages.first;
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
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
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
              if (_galleryImages.isNotEmpty && _bannerImages.isEmpty) _buildGallerySlider(context, 200),
              
              // Fallback to single image or default icon
              if (_allImages.isEmpty) _buildDefaultImageSection(context, 200),
              
              // Favorite Button
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: widget.onFavorite,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      (widget.exhibition['isFavorite'] == true) ? Icons.favorite : Icons.favorite_border,
                      color: (widget.exhibition['isFavorite'] == true) ? AppTheme.errorRed : AppTheme.textMediumGray,
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
                    color: AppTheme.textDarkCharcoal,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Date and Location
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                      Icons.calendar_today,
                      size: 16,
                        color: AppTheme.primaryBlue,
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
                              color: AppTheme.textDarkCharcoal,
                      ),
                    ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                    const Icon(
                      Icons.location_on,
                                size: 14,
                      color: AppTheme.textMediumGray,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                                  widget.exhibition['location'] ?? 'Location not specified',
                        style: const TextStyle(
                                    fontSize: 13,
                          color: AppTheme.textMediumGray,
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
                        color: AppTheme.successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                      Icons.storefront,
                      size: 16,
                        color: AppTheme.successGreen,
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
                        color: availableStalls > 0 ? AppTheme.successGreen : AppTheme.textMediumGray,
                        fontWeight: availableStalls > 0 ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    ),
                    if (priceRange != null && priceRange != 'Contact for pricing')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                        priceRange,
                        style: const TextStyle(
                            fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryBlue,
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
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: AppTheme.white,
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
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
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
                if (_galleryImages.isNotEmpty && _bannerImages.isEmpty) _buildGallerySlider(context, 140),
                
                // Fallback to single image or default icon
                if (_allImages.isEmpty) _buildDefaultImageSection(context, 140),
                
                // Favorite Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: widget.onFavorite,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        (widget.exhibition['isFavorite'] == true) ? Icons.favorite : Icons.favorite_border,
                        color: (widget.exhibition['isFavorite'] == true) ? AppTheme.errorRed : AppTheme.textMediumGray,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                  Text(
                    widget.exhibition['title'] ?? 'Untitled Exhibition',
                        style: const TextStyle(
                      fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDarkCharcoal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  const SizedBox(height: 8),
                    
                  // Date and Location
                    Row(
                      children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: AppTheme.primaryBlue,
                        ),
                        ),
                      const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                          widget.exhibition['date'] ?? 'Date not specified',
                            style: const TextStyle(
                              fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDarkCharcoal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 6),
                    
                    Row(
                      children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.textMediumGray.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.location_on,
                          size: 12,
                          color: AppTheme.textMediumGray,
                        ),
                      ),
                      const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                          widget.exhibition['location'] ?? 'Location not specified',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textMediumGray,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                    
                    // Available Stalls
                    Row(
                      children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.storefront,
                          size: 12,
                          color: AppTheme.successGreen,
                        ),
                        ),
                      const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            availableStalls > 0 
                              ? '$availableStalls stalls'
                              : 'No stalls',
                            style: TextStyle(
                              fontSize: 12,
                              color: availableStalls > 0 ? AppTheme.successGreen : AppTheme.textMediumGray,
                              fontWeight: availableStalls > 0 ? FontWeight.w600 : FontWeight.normal,
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
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / 
                                    loadingProgress.expectedTotalBytes!
                                  : null,
                              color: AppTheme.primaryBlue,
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
                        ? AppTheme.white 
                        : AppTheme.white.withOpacity(0.5),
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
            itemCount: _galleryImages.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showImagePopup(context, _galleryImages[index]),
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
                      _galleryImages[index],
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
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded / 
                                    loadingProgress.expectedTotalBytes!
                                  : null,
                              color: AppTheme.primaryBlue,
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
        if (_galleryImages.length > 1)
          Positioned(
            bottom: 8,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_galleryImages.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentGalleryIndex == index 
                        ? AppTheme.white 
                        : AppTheme.white.withOpacity(0.5),
                  ),
                );
              }),
            ),
          ),
        // Image counter
        if (_galleryImages.length > 1)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentGalleryIndex + 1}/${_galleryImages.length}',
                style: const TextStyle(
                  color: AppTheme.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
        color: AppTheme.primaryBlue.withOpacity(0.1),
      ),
      child: _buildDefaultIcon(height: height),
    );
  }

  Widget _buildDefaultIcon({double? height}) {
    final iconSize = height != null ? (height * 0.3) : 40.0;
    return Center(
      child: Icon(
      Icons.event,
        size: iconSize,
      color: AppTheme.primaryBlue,
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
                      color: AppTheme.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: AppTheme.white,
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
