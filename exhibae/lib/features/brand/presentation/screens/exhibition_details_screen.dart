import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/profile_picture_display.dart';
import '../widgets/stall_card.dart';

class ExhibitionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> exhibition;

  const ExhibitionDetailsScreen({
    super.key,
    required this.exhibition,
  });

  @override
  State<ExhibitionDetailsScreen> createState() => _ExhibitionDetailsScreenState();
}

class _ExhibitionDetailsScreenState extends State<ExhibitionDetailsScreen> {
  bool _isFavorite = false;
  bool _isLoading = false;
  int _currentImageIndex = 0;
  List<String> _images = [];
  List<Map<String, dynamic>> _stalls = [];
  List<Map<String, dynamic>> _galleryImages = [];
  List<Map<String, dynamic>> _participatingBrands = []; // Added for participating brands
  Set<int> _selectedStalls = {}; // Track selected stalls
  Set<String> _selectedVariants = {}; // Track selected stall variants
  final SupabaseService _supabaseService = SupabaseService.instance;

  @override
  void initState() {
    super.initState();
    _loadExhibitionDetails();
    _checkFavoriteStatus();
    
    // Check if we have selected variants from navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForSelectedVariants();
    });
  }

  void _checkForSelectedVariants() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args.containsKey('selectedVariants')) {
      final selectedVariants = args['selectedVariants'] as Set<String>;
      setState(() {
        _selectedVariants = selectedVariants;
      });
    }
  }

  void _selectStallVariant(String variant) {
    setState(() {
      if (_selectedVariants.contains(variant)) {
        _selectedVariants.remove(variant);
      } else {
        _selectedVariants.add(variant);
      }
    });
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser != null) {
        final isFavorited = await _supabaseService.isExhibitionFavorited(
          currentUser.id, 
          widget.exhibition['id']
        );
        if (mounted) {
          setState(() {
            _isFavorite = isFavorited;
          });
        }
      }
    } catch (e) {
      print('Error checking favorite status: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser != null) {
        await _supabaseService.toggleExhibitionFavorite(
          currentUser.id, 
          widget.exhibition['id']
        );
        await _checkFavoriteStatus();
      }
    } catch (e) {
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

  Future<void> _loadExhibitionDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load gallery images from gallery_images table
      final galleryImages = await _supabaseService.getGalleryImages(widget.exhibition['id']);
      
      // Extract image URLs from gallery images
      List<String> imageUrls = galleryImages
          .map((img) => img['image_url'] as String)
          .toList();

      // Load stalls
      final stalls = await _supabaseService.getStallsByExhibition(widget.exhibition['id']);

      // Load participating brands (brands who have booked stalls)
      final applications = await _supabaseService.getStallApplicationsByExhibition(widget.exhibition['id']);
      final participatingBrands = applications
          .where((app) => app['status'] == 'approved' || app['status'] == 'booked')
          .map((app) => app['brand'] as Map<String, dynamic>)
          .where((brand) => brand != null)
          .toList();

      if (mounted) {
        setState(() {
          _images = imageUrls;
          _stalls = stalls;
          _galleryImages = galleryImages;
          _participatingBrands = participatingBrands;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading exhibition details: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLightGray,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image Carousel
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Image Carousel
                  _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
                        ),
                      )
                    : PageView.builder(
                        onPageChanged: (index) {
                          setState(() {
                            _currentImageIndex = index;
                          });
                        },
                        itemCount: _images.isEmpty ? 1 : _images.length,
                        itemBuilder: (context, index) {
                          return Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primaryMaroon.withOpacity(0.1),
                            ),
                            child: ClipRect(
                              child: _images.isEmpty
                                ? Container(
                                    color: AppTheme.primaryMaroon.withOpacity(0.1),
                                    child: const Icon(
                                      Icons.event,
                                      size: 64,
                                      color: AppTheme.primaryMaroon,
                                    ),
                                  )
                                : Image.network(
                                    _images[index],
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: AppTheme.primaryMaroon.withOpacity(0.1),
                                        child: const Icon(
                                          Icons.event,
                                          size: 64,
                                          color: AppTheme.primaryMaroon,
                                        ),
                                      );
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                            : null,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
                                        ),
                                      );
                                    },
                                  ),
                            ),
                          );
                        },
                      ),
                  
                  // Favorite Button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () {
                        _toggleFavorite();
                      },
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
                              color: AppTheme.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? AppTheme.errorRed : Colors.black.withOpacity(0.6),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  
                  // Page Dots
                  if (!_isLoading && _images.isNotEmpty)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _images.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentImageIndex == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index
                                  ? AppTheme.primaryMaroon
                                  : AppTheme.primaryMaroon.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Information Card
                  _buildBasicInformationCard(),
                  const SizedBox(height: 16),
                  
                  // Organizer Profile Card
                  _buildOrganizerCard(),
                  const SizedBox(height: 16),
                  
                  // Description Section
                  _buildDescriptionSection(),
                  const SizedBox(height: 16),
                  
                  // Gallery Images Section
                  if (_galleryImages.isNotEmpty) ...[
                    _buildGallerySection(),
                    const SizedBox(height: 16),
                  ],
                  
                  // Available Stalls Section
                  _buildAvailableStallsSection(),
                  
                  // Selected Stall Variants
                  if (_hasSelectedStalls()) ...[
                    const SizedBox(height: 16),
                    _buildSelectedVariants(),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Participating Brands - only show if we have any
                  if (_hasParticipatingBrands()) ...[
                    _buildParticipatingBrands(),
                    const SizedBox(height: 16),
                  ],
                  
                  // Venue Information - only show if we have any
                  if (_hasVenueInformation()) ...[
                    _buildVenueInformation(),
                    const SizedBox(height: 16),
                  ],
                  
                  const SizedBox(height: 100), // Space for bottom action bar
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Bottom Action Bar
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppTheme.backgroundPeach,
          boxShadow: [
            BoxShadow(
              color: AppTheme.black,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _hasSelectedStalls() ? () {
                  Navigator.pushNamed(
                    context,
                    AppRouter.stallSelection,
                    arguments: {'exhibition': widget.exhibition, 'selectedVariants': _selectedVariants},
                  );
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _hasSelectedStalls() ? AppTheme.primaryMaroon : AppTheme.textMediumGray,
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _hasSelectedStalls() ? 'View Layout & Apply' : 'Select Stalls First',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () {
                // TODO: Share exhibition
              },
              icon: const Icon(Icons.share),
              color: AppTheme.primaryMaroon,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInformationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPeach,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderLightGray,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.exhibition['title'] ?? 'Untitled Exhibition',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          
          // Date Information
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryMaroon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryMaroon.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event,
                  color: AppTheme.primaryMaroon,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getExhibitionDateRange(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryMaroon,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          
          // Location
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.black.withOpacity(0.7),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getCompleteAddress(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Category Tags
          if (widget.exhibition['category'] != null)
            Wrap(
              spacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMaroon.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.exhibition['category'] is Map<String, dynamic>
                        ? (widget.exhibition['category']['name'] ?? 'Uncategorized')
                        : (widget.exhibition['category']?.toString() ?? 'Uncategorized'),
                    style: const TextStyle(
                      color: AppTheme.primaryMaroon,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildOrganizerCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPeach,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderLightGray,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Organizer Profile Picture and Company Logo
          Row(
            children: [
              ProfilePictureDisplay(
                avatarUrl: _getOrganizerAvatarUrl(),
                size: 48,
                backgroundColor: AppTheme.primaryMaroon.withOpacity(0.1),
                iconColor: AppTheme.primaryMaroon,
              ),
              const SizedBox(width: 8),
              // Company Logo (if available)
              if (_getOrganizerCompanyLogoUrl() != null)
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.secondaryWarm.withOpacity(0.1),
                  child: ClipOval(
                    child: Image.network(
                      _getOrganizerCompanyLogoUrl()!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.business,
                          size: 24,
                          color: Colors.black,
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        _getOrganizerName(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.verified,
                      color: AppTheme.primaryMaroon,
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Organizer',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.backgroundPeach,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.borderLightGray,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.exhibition['description'] ?? 'No description available for this exhibition.',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            
            // Highlights section removed as requested
            
          ],
        ),
      ),
    );
  }

  // Helper method to show image popup
  void _showImagePopup(int initialIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Stack(
            children: [
              // Full screen image viewer
              PageView.builder(
                itemCount: _galleryImages.length,
                controller: PageController(initialPage: initialIndex),
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 3.0,
                    child: Image.network(
                      _galleryImages[index]['image_url'],
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppTheme.backgroundLightGray,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.image_not_supported,
                                size: 64,
                                color: AppTheme.textMediumGray,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load image',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: AppTheme.textMediumGray,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              // Close button
              Positioned(
                top: 40,
                right: 20,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppTheme.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: AppTheme.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              // Image counter
              Positioned(
                top: 40,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${initialIndex + 1} / ${_galleryImages.length}',
                    style: const TextStyle(
                      color: AppTheme.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
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

  Widget _buildGallerySection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final isMediumScreen = constraints.maxWidth < 900;
        
        return Container(
          padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: AppTheme.backgroundPeach,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.borderLightGray,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gallery',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : (isMediumScreen ? 17 : 18),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              _galleryImages.isEmpty
                ? Center(
                                      child: Text(
                    'No gallery images available for this exhibition.',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                                         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                       crossAxisCount: isSmallScreen ? 2 : 3,
                       childAspectRatio: isSmallScreen ? 1.0 : 1.3,
                       crossAxisSpacing: isSmallScreen ? 6.0 : 8.0,
                       mainAxisSpacing: isSmallScreen ? 6.0 : 8.0,
                     ),
                    itemCount: _galleryImages.length,
                    itemBuilder: (context, index) {
                      return _GalleryImageItem(
                        imageUrl: _galleryImages[index]['image_url'],
                        onTap: () => _showImagePopup(index),
                      );
                    },
                  ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvailableStallsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final isMediumScreen = constraints.maxWidth < 900;
        
        return Container(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
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
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallScreen ? 6 : 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryMaroon.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.grid_on,
                      color: AppTheme.primaryMaroon,
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Stalls',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 18 : (isMediumScreen ? 20 : 22),
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 2 : 4),
                        Text(
                          'Choose from ${_stalls.length} different stall types',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 14,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: isSmallScreen ? 16 : 24),
              _isLoading
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 24 : 40),
                      child: CircularProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
                        strokeWidth: isSmallScreen ? 2 : 3,
                      ),
                    ),
                  )
                : _stalls.isEmpty
                  ? Container(
                      padding: EdgeInsets.all(isSmallScreen ? 24 : 40),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryWarm.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.borderLightGray,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.grid_off,
                            size: isSmallScreen ? 48 : 64,
                            color: Colors.black.withOpacity(0.6),
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          Text(
                            'No stalls available yet',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 6 : 8),
                          Text(
                            'Stalls will be added soon. Check back later!',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: Colors.black.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, gridConstraints) {
                                                 final crossAxisCount = gridConstraints.maxWidth > 600 ? 3 : 2;
                         final childAspectRatio = gridConstraints.maxWidth > 600 ? 0.85 : 0.8;
                         final spacing = isSmallScreen ? 12.0 : 16.0;
                         
                                                  return GridView.builder(
                           shrinkWrap: true,
                           physics: const NeverScrollableScrollPhysics(),
                           gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                             crossAxisCount: crossAxisCount,
                             childAspectRatio: 0.65, // Reduced from 0.75 to prevent overflow
                             crossAxisSpacing: spacing,
                             mainAxisSpacing: spacing,
                           ),
                           itemCount: _stalls.length,
                           itemBuilder: (context, index) {
                             return StallCard(
                               stall: _stalls[index],
                               isSelected: _selectedVariants.contains(_getStallVariant(_stalls[index])),
                               onSelect: () {
                                 // No longer needed - removed checkbox
                               },
                               onShowLayout: () async {
                                 final result = await Navigator.pushNamed(
                                   context,
                                   AppRouter.stallSelection,
                                   arguments: {'exhibition': widget.exhibition, 'stall': _stalls[index]},
                                 );
                                 
                                 if (result != null && result is Map<String, dynamic>) {
                                   if (result['action'] == 'apply') {
                                     // Navigate to application form
                                     Navigator.pushNamed(
                                       context,
                                       AppRouter.applicationForm,
                                       arguments: {
                                         'exhibition': widget.exhibition,
                                         'selectedStall': result['selectedStall'],
                                       },
                                     );
                                   }
                                 }
                               },
                             );
                           },
                         );
                      },
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectedVariants() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPeach,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderLightGray,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Selected Stall Variants',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                '${_selectedVariants.length} variants selected',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _selectedVariants.isEmpty
            ? Center(
                child: Text(
                  'No stall variants selected yet.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _selectedVariants.length,
                itemBuilder: (context, index) {
                  final variant = _selectedVariants.elementAt(index);
                  final stalls = _getStallInstancesForVariant(variant);
                  final firstStall = stalls.first;
                  final availableCount = _getAvailableInstanceCount(variant);
                  final totalCount = _getTotalInstanceCount(variant);
                  
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: AppTheme.backgroundLightGray,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppTheme.primaryMaroon.withOpacity(0.1),
                          child: Text(
                            'V${index + 1}',
                            style: const TextStyle(
                              color: AppTheme.primaryMaroon,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${firstStall['length']} × ${firstStall['width']} ${_getUnitSymbol(firstStall)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${firstStall['price']} - ${availableCount}/${totalCount} available',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                              ),
                              if (_getStallAmenities(firstStall).isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  _getStallAmenities(firstStall).take(3).join(', '),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.black.withOpacity(0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _selectStallVariant(variant);
                          },
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: AppTheme.errorRed,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
        ],
      ),
    );
  }

  Widget _buildParticipatingBrands() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPeach,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderLightGray,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Participating Brands',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              Text(
                '${_participatingBrands.length} brands',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
            ],
          ),
                     const SizedBox(height: 12),
           _participatingBrands.isEmpty
             ? Container(
                 height: 80,
                 child: Center(
                   child: Text(
                     'No participating brands yet',
                     style: TextStyle(
                       fontSize: 14,
                       color: Colors.black.withOpacity(0.7),
                     ),
                   ),
                 ),
               )
             : Container(
                 height: 120, // Increased height to accommodate both images and brand names
                 child: ListView.builder(
                   scrollDirection: Axis.horizontal,
                   itemCount: _participatingBrands.length,
                   itemBuilder: (context, index) {
                     final brand = _participatingBrands[index];
                     final brandName = brand['company_name'] ?? brand['full_name'] ?? 'Brand ${index + 1}';
                     final brandLogo = brand['company_logo_url'] ?? brand['logo_url'];
                     final brandAvatar = brand['avatar_url'];
                     
                     return Container(
                       margin: const EdgeInsets.only(right: 16),
                       child: Column(
                         mainAxisSize: MainAxisSize.min,
                         children: [
                           // Profile Picture and Company Logo Stack
                           Stack(
                             children: [
                               // Profile Picture (background)
                               ProfilePictureDisplay(
                                 avatarUrl: brandAvatar,
                                 size: 50,
                                 backgroundColor: AppTheme.primaryMaroon.withOpacity(0.1),
                                 iconColor: AppTheme.primaryMaroon,
                               ),
                               // Company Logo (overlay, if available)
                               if (brandLogo != null)
                                 Positioned(
                                   bottom: 0,
                                   right: 0,
                                   child: Container(
                                     width: 25,
                                     height: 25,
                                     decoration: BoxDecoration(
                                       color: AppTheme.white,
                                       borderRadius: BorderRadius.circular(12.5),
                                       border: Border.all(
                                         color: AppTheme.white,
                                         width: 2,
                                       ),
                                     ),
                                     child: ClipRRect(
                                       borderRadius: BorderRadius.circular(12.5),
                                       child: Image.network(
                                         brandLogo,
                                         width: 25,
                                         height: 25,
                                         fit: BoxFit.cover,
                                         errorBuilder: (context, error, stackTrace) {
                                           return const Icon(
                                             Icons.business,
                                             size: 15,
                                             color: Colors.black,
                                           );
                                         },
                                       ),
                                     ),
                                   ),
                                 ),
                             ],
                           ),
                           const SizedBox(height: 8),
                           SizedBox(
                             width: 70,
                             child: Text(
                               brandName,
                               style: const TextStyle(
                                 fontSize: 10,
                                 color: Colors.black,
                                 fontWeight: FontWeight.w500,
                               ),
                               textAlign: TextAlign.center,
                               overflow: TextOverflow.ellipsis,
                               maxLines: 2,
                             ),
                           ),
                         ],
                       ),
                     );
                   },
                 ),
               ),
        ],
      ),
    );
  }

  Widget _buildVenueInformation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPeach,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderLightGray,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Venue Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          
          // Floor Plan - only show if available
          if (widget.exhibition['floor_plan'] != null) ...[
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.secondaryWarm.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.borderLightGray,
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map,
                      size: 32,
                      color: AppTheme.primaryMaroon,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Floor Plan',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ] else ...[
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.secondaryWarm.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.borderLightGray,
                  width: 1,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map_outlined,
                      size: 32,
                      color: AppTheme.primaryMaroon,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No Floor Plan Available',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Amenities - only show if we have any
          if (_getVenueAmenities().isNotEmpty) ...[
            const Text(
              'Amenities',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDarkCharcoal,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              children: _getVenueAmenities().map((amenity) => _buildAmenityItem(amenity['icon'], amenity['name'])).toList(),
            ),
          ] else ...[
            const Text(
              'Amenities',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No amenities information available',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAmenityItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: AppTheme.primaryMaroon,
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black,
          ),
        ),
      ],
    );
  }

  String _getOrganizerName() {
    final organiser = widget.exhibition['organiser'];
    if (organiser is Map<String, dynamic>) {
      return organiser['company_name'] ?? organiser['full_name'] ?? 'Organiser';
    }
    return 'Organiser';
  }

  String? _getOrganizerAvatarUrl() {
    final organiser = widget.exhibition['organiser'];
    if (organiser is Map<String, dynamic>) {
      return organiser['avatar_url'];
    }
    return null;
  }

  String? _getOrganizerCompanyLogoUrl() {
    final organiser = widget.exhibition['organiser'];
    if (organiser is Map<String, dynamic>) {
      return organiser['company_logo_url'];
    }
    return null;
  }

  String _getExhibitionAddress() {
    // Try to get the best available address information
    final venueName = widget.exhibition['venue_name'];
    final venueAddress = widget.exhibition['venue_address'];
    final location = widget.exhibition['location'];
    
    // If we have both venue name and address, combine them
    if (venueName != null && venueAddress != null) {
      return '$venueName, $venueAddress';
    }
    
    // If we have venue name only
    if (venueName != null) {
      return venueName.toString();
    }
    
    // If we have venue address only
    if (venueAddress != null) {
      return venueAddress.toString();
    }
    
    // If we have location field
    if (location != null) {
      return location.toString();
    }
    
    // Fallback
    return 'Location not specified';
  }

  String _getExhibitionDateRange() {
    // Try to get start and end dates
    final startDate = widget.exhibition['start_date'];
    final endDate = widget.exhibition['end_date'];
    final date = widget.exhibition['date'];
    
    // If we have both start and end dates
    if (startDate != null && endDate != null) {
      return 'From: ${_formatDate(startDate)} - To: ${_formatDate(endDate)}';
    }
    
    // If we have start date only
    if (startDate != null) {
      return 'From: ${_formatDate(startDate)}';
    }
    
    // If we have end date only
    if (endDate != null) {
      return 'To: ${_formatDate(endDate)}';
    }
    
    // If we have single date field
    if (date != null) {
      return _formatDate(date);
    }
    
    // Fallback
    return 'Date not specified';
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'Date not specified';
    
    try {
      // Handle different date formats
      if (dateValue is String) {
        // Try to parse ISO date string
        final date = DateTime.tryParse(dateValue);
        if (date != null) {
          return '${date.day}/${date.month}/${date.year}';
        }
        // If it's already formatted, return as is
        return dateValue;
      } else if (dateValue is DateTime) {
        return '${dateValue.day}/${dateValue.month}/${dateValue.year}';
      }
    } catch (e) {
      print('Error formatting date: $e');
    }
    
    return dateValue.toString();
  }

  String _getCompleteAddress() {
    // Try to get all available address information
    final venueName = widget.exhibition['venue_name'];
    final venueAddress = widget.exhibition['venue_address'];
    final location = widget.exhibition['location'];
    final city = widget.exhibition['city'];
    final state = widget.exhibition['state'];
    final country = widget.exhibition['country'];
    final postalCode = widget.exhibition['postal_code'];
    
    List<String> addressParts = [];
    
    // Add venue name if available
    if (venueName != null && venueName.toString().isNotEmpty) {
      addressParts.add(venueName.toString());
    }
    
    // Add venue address if available
    if (venueAddress != null && venueAddress.toString().isNotEmpty) {
      addressParts.add(venueAddress.toString());
    }
    
    // Add location if available
    if (location != null && location.toString().isNotEmpty) {
      addressParts.add(location.toString());
    }
    
    // Add city if available
    if (city != null && city.toString().isNotEmpty) {
      addressParts.add(city.toString());
    }
    
    // Add state if available
    if (state != null && state.toString().isNotEmpty) {
      addressParts.add(state.toString());
    }
    
    // Add postal code if available
    if (postalCode != null && postalCode.toString().isNotEmpty) {
      addressParts.add(postalCode.toString());
    }
    
    // Add country if available
    if (country != null && country.toString().isNotEmpty) {
      addressParts.add(country.toString());
    }
    
    // Combine all parts
    if (addressParts.isNotEmpty) {
      return addressParts.join(', ');
    }
    
    // Fallback to basic address
    return _getExhibitionAddress();
  }

  bool _hasParticipatingBrands() {
    // Check if we have any participating brands who have booked stalls
    return _participatingBrands.isNotEmpty;
  }

  bool _hasVenueInformation() {
    // Check if we have floor plan, amenities, or venue details
    return widget.exhibition['floor_plan'] != null || 
           _getVenueAmenities().isNotEmpty ||
           widget.exhibition['venue_address'] != null ||
           widget.exhibition['venue_name'] != null;
  }

  List<Map<String, dynamic>> _getVenueAmenities() {
    final amenities = widget.exhibition['amenities'];
    if (amenities is List) {
      return List<Map<String, dynamic>>.from(amenities.where((item) => item != null && item is Map<String, dynamic>));
    }
    return [];
  }

  // Helper method to get stall variant key
  String _getStallVariant(Map<String, dynamic> stall) {
    final length = stall['length']?.toString() ?? '0';
    final width = stall['width']?.toString() ?? '0';
    final basePrice = stall['price']?.toString() ?? '0';
    final amenities = _getStallAmenities(stall).join(',');
    return '${length}x${width}_${basePrice}_$amenities';
  }

  // Helper method to get stall instances for a variant
  List<Map<String, dynamic>> _getStallInstancesForVariant(String variant) {
    return _stalls.where((stall) => _getStallVariant(stall) == variant).toList();
  }

  // Helper method to get available instance count for a variant
  int _getAvailableInstanceCount(String variant) {
    int totalCount = 0;
    int availableCount = 0;
    
    for (final stall in _stalls) {
      if (_getStallVariant(stall) == variant) {
        final instances = stall['instances'] as List<dynamic>?;
        if (instances != null) {
          totalCount += instances.length;
          availableCount += instances.where((instance) => 
            instance['status'] == 'available'
          ).length;
        }
      }
    }
    
    return availableCount;
  }

  // Helper method to get total instance count for a variant
  int _getTotalInstanceCount(String variant) {
    int totalCount = 0;
    
    for (final stall in _stalls) {
      if (_getStallVariant(stall) == variant) {
        final instances = stall['instances'] as List<dynamic>?;
        if (instances != null) {
          totalCount += instances.length;
        }
      }
    }
    
    return totalCount;
  }

  // Helper method to get stall amenities

  List<String> _getStallAmenities(Map<String, dynamic> stall) {
    final amenities = stall['amenities'];
    if (amenities is List) {
      return amenities.where((item) {
        if (item is Map<String, dynamic>) {
          final amenity = item['amenity'];
          return amenity is Map<String, dynamic> && amenity['name'] != null;
        }
        return false;
      }).map((item) {
        final amenity = item['amenity'] as Map<String, dynamic>;
        return amenity['name']?.toString() ?? '';
      }).where((name) => name.isNotEmpty).toList();
    }
    return [];
  }

  // Helper method to check if stalls are selected
  bool _hasSelectedStalls() {
    return _selectedVariants.isNotEmpty;
  }

  // Helper method to get selected stall count
  int _getSelectedStallCount() {
    return _stalls.where((stall) => _selectedVariants.contains(_getStallVariant(stall))).length;
  }

  String _getUnitSymbol(Map<String, dynamic> stall) {
    final unit = stall['unit'];
    if (unit is Map<String, dynamic>) {
      return unit['symbol'] ?? 'm';
    }
    return 'm';
  }

  Widget _buildBannerFallback() {
    return Container(
      width: double.infinity,
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryMaroon.withOpacity(0.1),
            AppTheme.primaryMaroon.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryMaroon.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(
            Icons.event,
            color: AppTheme.primaryMaroon,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getExhibitionDateRange(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryMaroon,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

// Gallery Image Item with hover effects
class _GalleryImageItem extends StatefulWidget {
  final String imageUrl;
  final VoidCallback onTap;

  const _GalleryImageItem({
    required this.imageUrl,
    required this.onTap,
  });

  @override
  State<_GalleryImageItem> createState() => _GalleryImageItemState();
}

class _GalleryImageItemState extends State<_GalleryImageItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppTheme.black.withOpacity(_isHovered ? 0.2 : 0.1),
                blurRadius: _isHovered ? 8 : 4,
                offset: Offset(0, _isHovered ? 4 : 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Transform.scale(
              scale: _isHovered ? 1.05 : 1.0,
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppTheme.primaryMaroon.withOpacity(0.1),
                    child: Icon(
                      Icons.image_not_supported,
                      size: 40,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
