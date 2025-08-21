import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';

class UpcomingEventCard extends StatefulWidget {
  final Map<String, dynamic> exhibition;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onAttendingToggle;

  const UpcomingEventCard({
    super.key,
    required this.exhibition,
    required this.onTap,
    this.onFavoriteToggle,
    this.onAttendingToggle,
  });

  @override
  State<UpcomingEventCard> createState() => _UpcomingEventCardState();
}

class _UpcomingEventCardState extends State<UpcomingEventCard> {
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
        decoration: BoxDecoration(
          color: AppTheme.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderLightGray),
          boxShadow: [
            BoxShadow(
              color: AppTheme.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image section with banner functionality
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    // Banner Image Slider
                    if (_bannerImages.isNotEmpty) _buildBannerSlider(context, 80),
                    
                    // Gallery Images Slider (if no banner, show gallery first)
                    if (_galleryImagesUrls.isNotEmpty && _bannerImages.isEmpty) _buildGallerySlider(context, 80),
                    
                    // Fallback to single image or default icon
                    if (_allImages.isEmpty) _buildDefaultImageSection(context, 80),
                    
                    // Loading indicator
                    if (_isLoadingImages) _buildLoadingSection(context, 80),
                    
                    // Favorite Button
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: widget.onFavoriteToggle ?? () {},
                child: Container(
                          padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                            color: AppTheme.backgroundPeach,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.borderLightGray,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.black.withOpacity(0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            isFavorited ? Icons.favorite : Icons.favorite_border,
                            color: isFavorited ? AppTheme.errorRed : Colors.black.withOpacity(0.6),
                            size: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              
              // Content section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      widget.exhibition['title'] ?? 'Event Title',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryMaroon,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    
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
                  ],
                ),
              ),
              
              // Action buttons
              Column(
                children: [
                  IconButton(
                    onPressed: widget.onFavoriteToggle ?? () {},
                    icon: Icon(
                      isFavorited ? Icons.favorite : Icons.favorite_border,
                      color: isFavorited ? AppTheme.errorRed : AppTheme.textMediumGray,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(height: 4),
                                     GestureDetector(
                    onTap: widget.onAttendingToggle ?? () {},
                     child: Container(
                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                       decoration: BoxDecoration(
                         color: isAttending ? AppTheme.successGreen : AppTheme.primaryMaroon,
                         borderRadius: BorderRadius.circular(12),
                       ),
                       child: Text(
                         isAttending ? 'Going' : 'Attend',
                         style: const TextStyle(
                           color: Colors.white,
                           fontSize: 10,
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
    );
  }

  Widget _buildBannerSlider(BuildContext context, double height) {
    return Stack(
      children: [
        Container(
          height: height,
          width: 80,
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
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _bannerImages[index],
                    fit: BoxFit.cover,
                    width: 80,
                    height: height,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultIcon(height: height);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: height,
                        width: 80,
                        color: AppTheme.primaryMaroon.withOpacity(0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                  loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppTheme.primaryMaroon,
                            strokeWidth: 2,
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
            bottom: 4,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_bannerImages.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  width: 4,
                  height: 4,
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
          width: 80,
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
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _galleryImagesUrls[index],
                    fit: BoxFit.cover,
                    width: 80,
                    height: height,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildDefaultIcon(height: height);
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: height,
                        width: 80,
                        color: AppTheme.primaryMaroon.withOpacity(0.1),
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / 
                                  loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppTheme.primaryMaroon,
                            strokeWidth: 2,
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
            bottom: 4,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_galleryImagesUrls.length, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  width: 4,
                  height: 4,
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
      width: 80,
      decoration: BoxDecoration(
        color: AppTheme.secondaryWarm,
        borderRadius: BorderRadius.circular(8),
      ),
      child: _buildDefaultIcon(height: height),
    );
  }

  Widget _buildLoadingSection(BuildContext context, double height) {
    return Container(
      height: height,
      width: 80,
      decoration: BoxDecoration(
        color: AppTheme.primaryMaroon.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryMaroon,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildDefaultIcon({double? height}) {
    final iconSize = height != null ? (height * 0.4) : 32.0;
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
