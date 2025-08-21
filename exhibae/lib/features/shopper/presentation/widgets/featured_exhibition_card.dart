import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';

class FeaturedExhibitionCard extends StatefulWidget {
  final Map<String, dynamic> exhibition;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onAttendingToggle;

  const FeaturedExhibitionCard({
    super.key,
    required this.exhibition,
    required this.onTap,
    this.onFavoriteToggle,
    this.onAttendingToggle,
  });

  @override
  State<FeaturedExhibitionCard> createState() => _FeaturedExhibitionCardState();
}

class _FeaturedExhibitionCardState extends State<FeaturedExhibitionCard> {
  int _currentBannerIndex = 0;
  int _currentGalleryIndex = 0;
  late PageController _bannerPageController;
  late PageController _galleryPageController;
  List<Map<String, dynamic>> _galleryImages = [];
  bool _isLoadingImages = true;

  @override
  void initState() {
    super.initState();
    _bannerPageController = PageController();
    _galleryPageController = PageController();
    _loadGalleryImages();
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

  @override
  Widget build(BuildContext context) {
    final startDate = DateTime.tryParse(widget.exhibition['start_date'] ?? '');
    final endDate = DateTime.tryParse(widget.exhibition['end_date'] ?? '');
    final isAttending = widget.exhibition['is_attending'] ?? false;
    final isFavorited = widget.exhibition['is_favorited'] ?? false;

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: 280,
        height: 320, // Fixed height to prevent overflow
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLightGray),
          boxShadow: [
            BoxShadow(
              color: AppTheme.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section with banner functionality
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
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
                      onTap: widget.onFavoriteToggle ?? () {},
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
                        child: Icon(
                          isFavorited ? Icons.favorite : Icons.favorite_border,
                          color: isFavorited ? AppTheme.errorRed : Colors.black.withOpacity(0.6),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12), // Reduced padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.exhibition['title'] ?? 'Exhibition Title',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryMaroon,
                        fontWeight: FontWeight.w600,
                        fontSize: 16, // Reduced font size
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6), // Reduced spacing
                    
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: AppTheme.textMediumGray,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.exhibition['city'] ?? 'Location',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMediumGray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Date
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: AppTheme.textMediumGray,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            _formatDateRange(startDate, endDate),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textMediumGray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: widget.onAttendingToggle ?? () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isAttending ? AppTheme.successGreen : AppTheme.primaryMaroon,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isAttending ? 'Going' : 'Attend',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
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
              return Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
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
                  width: 6,
                  height: 6,
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
              return Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
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
                  width: 6,
                  height: 6,
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
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
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
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
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

  String _formatDateRange(DateTime? startDate, DateTime? endDate) {
    if (startDate == null) return 'Date TBD';
    
    final startFormatted = '${startDate.day}/${startDate.month}/${startDate.year}';
    
    if (endDate == null || startDate.isAtSameMomentAs(endDate)) {
      return startFormatted;
    }
    
    final endFormatted = '${endDate.day}/${endDate.month}/${endDate.year}';
    return '$startFormatted - $endFormatted';
  }
}
