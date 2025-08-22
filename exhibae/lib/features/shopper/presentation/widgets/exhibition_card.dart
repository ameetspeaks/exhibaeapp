import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';

class ExhibitionCard extends StatefulWidget {
  final Map<String, dynamic> exhibition;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onAttendingToggle;

  const ExhibitionCard({
    super.key,
    required this.exhibition,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onAttendingToggle,
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
    final isUpcoming = startDate != null && startDate.isAfter(DateTime.now());

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderLightGray),
          boxShadow: [
            BoxShadow(
              color: AppTheme.black.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section with banner functionality
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Stack(
                  children: [
                  // Banner Image Slider
                  if (_bannerImages.isNotEmpty) _buildBannerSlider(context, 200),
                  
                  // Gallery Images Slider (if no banner, show gallery first)
                  if (_galleryImagesUrls.isNotEmpty && _bannerImages.isEmpty) _buildGallerySlider(context, 200),
                  
                  // Fallback to single image or default icon
                  if (_allImages.isEmpty) _buildDefaultImageSection(context, 200),
                  
                  // Loading indicator
                  if (_isLoadingImages) _buildLoadingSection(context, 200),
                    
                    // Status badge (Upcoming/Live)
                    if (isUpcoming)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.accentGold.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Upcoming',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Favorite button overlay
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                      onTap: widget.onFavoriteToggle,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorited ? Icons.favorite : Icons.favorite_border,
                            color: isFavorited ? AppTheme.errorRed : AppTheme.textMediumGray,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                    
                    // Category badge (moved to bottom right)
                  if (widget.exhibition['category'] != null)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryMaroon.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                          widget.exhibition['category'],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
              ),
            ),
            
            // Content section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    widget.exhibition['title'] ?? 'Exhibition Title',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // Date and Location
                        Row(
                          children: [
                            Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppTheme.textMediumGray,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                          _formatDateRange(startDate, endDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMediumGray,
                          ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                  
                        Row(
                          children: [
                            Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppTheme.textMediumGray,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                          widget.exhibition['city'] ?? 'Location',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMediumGray,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        
                        // Stall Availability
                        Row(
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              size: 16,
                              color: AppTheme.textMediumGray,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getStallAvailabilityText(),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _getStallAvailabilityColor(),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 16),
                  
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: widget.onAttendingToggle,
                            style: ElevatedButton.styleFrom(
                            backgroundColor: isAttending ? AppTheme.successGreen : AppTheme.primaryMaroon,
                              foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            elevation: 0,
                          ),
                          child: Text(
                            isAttending ? 'Going' : 'Mark Attending',
                            style: const TextStyle(
                              fontSize: 14,
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
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
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
              return Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
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
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
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
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
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
    final iconSize = height != null ? (height * 0.3) : 48.0;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event,
            size: iconSize,
            color: AppTheme.primaryMaroon,
          ),
          const SizedBox(height: 8),
          Text(
            'Exhibition',
            style: TextStyle(
              color: AppTheme.primaryMaroon,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

  String _getStallAvailabilityText() {
    final availableStalls = widget.exhibition['availableStalls'] ?? 0;
    
    return availableStalls > 0 
      ? '$availableStalls stalls available'
      : 'No stalls available';
  }

  Color _getStallAvailabilityColor() {
    final availableStalls = widget.exhibition['availableStalls'] ?? 0;
    return availableStalls > 0 ? AppTheme.successGreen : AppTheme.errorRed;
  }
}
