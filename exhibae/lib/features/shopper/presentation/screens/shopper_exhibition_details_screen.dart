import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../widgets/brand_card.dart';

class ShopperExhibitionDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> exhibition;

  const ShopperExhibitionDetailsScreen({
    super.key,
    required this.exhibition,
  });

  @override
  State<ShopperExhibitionDetailsScreen> createState() => _ShopperExhibitionDetailsScreenState();
}

class _ShopperExhibitionDetailsScreenState extends State<ShopperExhibitionDetailsScreen> {
  bool _isFavorite = false;
  bool _isAttending = false;
  bool _isLoading = false;
  int _currentImageIndex = 0;
  List<String> _images = [];
  List<Map<String, dynamic>> _galleryImages = [];
  List<Map<String, dynamic>> _participatingBrands = [];
  final SupabaseService _supabaseService = SupabaseService.instance;

  @override
  void initState() {
    super.initState();
    _loadExhibitionDetails();
    _checkFavoriteStatus();
    _checkAttendingStatus();
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

  Future<void> _checkAttendingStatus() async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser != null) {
        final isAttending = await _supabaseService.isExhibitionAttending(
          currentUser.id, 
          widget.exhibition['id']
        );
        if (mounted) {
          setState(() {
            _isAttending = isAttending;
          });
        }
      }
    } catch (e) {
      print('Error checking attending status: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleAttending() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final currentUser = _supabaseService.currentUser;
      if (currentUser != null) {
        await _supabaseService.toggleExhibitionAttending(
          currentUser.id, 
          widget.exhibition['id']
        );
        await _checkAttendingStatus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating attendance: $e'),
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

  Future<void> _loadExhibitionDetails() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load gallery images from gallery_images table
      final galleryImages = await _supabaseService.getGalleryImages(widget.exhibition['id']);
      
      // Extract image URLs from gallery images
      List<String> imageUrls = galleryImages
          .map((img) => img['image_url'] as String)
          .toList();

      // Load participating brands
      final brandsData = await _supabaseService.client
          .from('profiles')
          .select()
          .eq('role', 'brand')
          .inFilter('id', _getParticipatingBrandIds());

      if (mounted) {
        setState(() {
          _images = imageUrls;
          _galleryImages = galleryImages;
          _participatingBrands = List<Map<String, dynamic>>.from(brandsData);
          _isLoading = false;
        });
      }

    } catch (e) {
      print('Error loading exhibition details: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<String> _getParticipatingBrandIds() {
    // This would typically come from a join table
    // For now, return empty list
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final startDate = DateTime.tryParse(widget.exhibition['start_date'] ?? '');
    final endDate = DateTime.tryParse(widget.exhibition['end_date'] ?? '');
    final isUpcoming = startDate != null && startDate.isAfter(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppTheme.primaryMaroon,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Exhibition Image
                  _buildExhibitionImage(),
                  
                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  
                  // Status badge
                  if (isUpcoming)
                    Positioned(
                      top: 60,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Upcoming Event',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back,
                  color: AppTheme.primaryMaroon,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? AppTheme.errorRed : AppTheme.primaryMaroon,
                    size: 20,
                  ),
                ),
                onPressed: _isLoading ? null : _toggleFavorite,
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Category
                  Text(
                    widget.exhibition['title'] ?? 'Exhibition Title',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primaryMaroon,
                      fontWeight: FontWeight.w700,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  if (widget.exhibition['category'] != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryMaroon.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3)),
                      ),
                      child: Text(
                        widget.exhibition['category'],
                        style: TextStyle(
                          color: AppTheme.primaryMaroon,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Action Buttons (Prominent for Shoppers)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Attend Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _toggleAttending,
                            icon: Icon(
                              _isAttending ? Icons.check_circle : Icons.event_available,
                              size: 24,
                            ),
                            label: Text(
                              _isAttending ? 'Attending' : 'Mark as Attending',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isAttending 
                                  ? AppTheme.successGreen 
                                  : AppTheme.primaryMaroon,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Favorite Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _toggleFavorite,
                            icon: Icon(
                              _isFavorite ? Icons.favorite : Icons.favorite_border,
                              size: 24,
                              color: _isFavorite ? AppTheme.errorRed : AppTheme.primaryMaroon,
                            ),
                            label: Text(
                              _isFavorite ? 'Favorited' : 'Add to Favorites',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _isFavorite ? AppTheme.errorRed : AppTheme.primaryMaroon,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: _isFavorite ? AppTheme.errorRed : AppTheme.primaryMaroon,
                                width: 2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  if (widget.exhibition['description'] != null) ...[
                    _buildSectionTitle('About This Exhibition'),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        widget.exhibition['description'],
                                                 style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                           color: AppTheme.textDarkCharcoal,
                           height: 1.6,
                           fontSize: 16,
                         ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Event Details
                  _buildSectionTitle('Event Details'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          icon: Icons.location_on_outlined,
                          label: 'Location',
                          value: widget.exhibition['city'] ?? 'TBD',
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Date',
                          value: _formatDateRange(startDate, endDate),
                        ),
                        const SizedBox(height: 16),
                        _buildDetailRow(
                          icon: Icons.access_time_outlined,
                          label: 'Time',
                          value: '${widget.exhibition['start_time'] ?? '11:00'} - ${widget.exhibition['end_time'] ?? '17:00'}',
                        ),
                        if (widget.exhibition['address'] != null) ...[
                          const SizedBox(height: 16),
                          _buildDetailRow(
                            icon: Icons.map_outlined,
                            label: 'Address',
                            value: widget.exhibition['address'],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Gallery (Enhanced for Shoppers)
                  if (_galleryImages.isNotEmpty) ...[
                    _buildSectionTitle('Gallery'),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _galleryImages.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: 280,
                            margin: EdgeInsets.only(right: index < _galleryImages.length - 1 ? 16 : 0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _galleryImages[index]['image_url'] ?? '',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppTheme.secondaryWarm,
                                    child: Icon(
                                      Icons.image,
                                      size: 48,
                                      color: AppTheme.primaryMaroon,
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Participating Brands (Enhanced for Shoppers)
                  if (_participatingBrands.isNotEmpty) ...[
                    _buildSectionTitle('Participating Brands'),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _participatingBrands.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: BrandCard(
                              brand: _participatingBrands[index],
                              onTap: () {
                                // Navigate to brand details
                              },
                              onFavoriteToggle: () {
                                // Toggle brand favorite
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExhibitionImage() {
    if (_images.isNotEmpty) {
      return PageView.builder(
        itemCount: _images.length,
        onPageChanged: (index) {
          setState(() {
            _currentImageIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return Image.network(
            _images[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppTheme.secondaryWarm,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event,
                      size: 64,
                      color: AppTheme.primaryMaroon,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Exhibition',
                      style: TextStyle(
                        color: AppTheme.primaryMaroon,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } else {
      return Container(
        color: AppTheme.secondaryWarm,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event,
              size: 64,
              color: AppTheme.primaryMaroon,
            ),
            const SizedBox(height: 16),
            Text(
              'Exhibition',
              style: TextStyle(
                color: AppTheme.primaryMaroon,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: AppTheme.primaryMaroon,
        fontWeight: FontWeight.w700,
        fontSize: 22,
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryMaroon.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppTheme.primaryMaroon,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.textMediumGray,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                                 style: TextStyle(
                   color: AppTheme.textDarkCharcoal,
                   fontSize: 16,
                   fontWeight: FontWeight.w600,
                 ),
              ),
            ],
          ),
        ),
      ],
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
