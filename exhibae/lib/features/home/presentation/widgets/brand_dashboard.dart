import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/responsive_card.dart';
import '../../../../core/widgets/dashboard_loading_widget.dart';
import '../../../../core/services/dashboard_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../brand/presentation/screens/brand_lookbook_form_screen.dart';
import '../../../brand/presentation/screens/brand_gallery_form_screen.dart';

class BrandDashboard extends StatefulWidget {
  const BrandDashboard({super.key});

  @override
  State<BrandDashboard> createState() => _BrandDashboardState();
}

class _BrandDashboardState extends State<BrandDashboard> {
  final DashboardService _dashboardService = DashboardService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;
  String? _errorMessage;
  StreamSubscription? _dashboardSubscription;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _subscribeToUpdates();
  }

  @override
  void dispose() {
    _dashboardSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      print('BrandDashboard: Starting dashboard data load...');
      
      // Check Supabase client status
      print('BrandDashboard: Supabase client status: ${_supabaseService.currentUser != null ? 'Authenticated' : 'Not authenticated'}');
      
      final currentUser = _supabaseService.currentUser;
      print('BrandDashboard: Current user: ${currentUser?.id ?? 'null'}');
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('BrandDashboard: Loading dashboard data for user: ${currentUser.id}');
      
      // Test individual service calls to identify the failing one
      try {
        print('BrandDashboard: Testing getUserProfile...');
        final profile = await _supabaseService.getUserProfile(currentUser.id);
        print('BrandDashboard: getUserProfile success: ${profile != null ? 'Profile loaded' : 'Profile is null'}');
      } catch (e) {
        print('BrandDashboard: getUserProfile failed: $e');
        throw Exception('Failed to load user profile: $e');
      }
      
      try {
        print('BrandDashboard: Testing getHeroSliders...');
        final heroSliders = await _supabaseService.getHeroSliders();
        print('BrandDashboard: getHeroSliders success: ${heroSliders.length} items');
      } catch (e) {
        print('BrandDashboard: getHeroSliders failed: $e');
        // Don't throw here, continue with other data
      }
      
      try {
        print('BrandDashboard: Testing getStallApplications...');
        final applications = await _supabaseService.getStallApplications(brandId: currentUser.id);
        print('BrandDashboard: getStallApplications success: ${applications.length} items');
      } catch (e) {
        print('BrandDashboard: getStallApplications failed: $e');
        // Don't throw here, continue with other data
      }
      
      try {
        print('BrandDashboard: Testing getExhibitions...');
        final exhibitions = await _supabaseService.getExhibitions();
        print('BrandDashboard: getExhibitions success: ${exhibitions.length} items');
      } catch (e) {
        print('BrandDashboard: getExhibitions failed: $e');
        // Don't throw here, continue with other data
      }
      
      try {
        print('BrandDashboard: Testing getExhibitionFavorites...');
        final favorites = await _supabaseService.getExhibitionFavorites(currentUser.id);
        print('BrandDashboard: getExhibitionFavorites success: ${favorites.length} items');
      } catch (e) {
        print('BrandDashboard: getExhibitionFavorites failed: $e');
        // Don't throw here, continue with other data
      }
      
      print('BrandDashboard: All individual service calls completed, now calling getBrandDashboardData...');
      final data = await _dashboardService.getBrandDashboardData(currentUser.id);
      print('BrandDashboard: Dashboard data loaded successfully');
      
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('BrandDashboard: Error loading dashboard data: $e');
      print('BrandDashboard: Stack trace: $stackTrace');
      
      String errorMessage = 'Failed to load dashboard data';
      if (e.toString().contains('User not authenticated')) {
        errorMessage = 'Please log in to view your dashboard';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection and try again.';
      } else if (e.toString().contains('database')) {
        errorMessage = 'Database error. Please try again later.';
      } else if (e.toString().contains('Failed to load user profile')) {
        errorMessage = 'Failed to load user profile. Please try again.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }
      
      setState(() {
        _errorMessage = errorMessage;
        _isLoading = false;
      });
    }
  }

  void _subscribeToUpdates() {
    final currentUser = _supabaseService.currentUser;
    if (currentUser != null) {
      _dashboardSubscription = _dashboardService
          .subscribeToDashboardUpdates(currentUser.id, 'brand')
          .listen((updates) {
        if (mounted && _dashboardData != null) {
          setState(() {
            _dashboardData!.addAll(updates);
          });
        }
      });
    }
  }



  void _navigateToExhibitionDetails(String exhibitionId) {
    // Find the exhibition data from the dashboard data
    final recommendedExhibitions = _dashboardData!['recommendedExhibitions'] as List<dynamic>? ?? [];
    final exhibition = recommendedExhibitions.firstWhere(
      (exhibition) => exhibition['id'] == exhibitionId,
      orElse: () => <String, dynamic>{},
    );
    
    if (exhibition.isNotEmpty) {
      Navigator.pushNamed(
        context,
        '/exhibition-details',
        arguments: {'exhibition': exhibition},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exhibition not found')),
      );
    }
  }

  void _navigateToAllExhibitions() {
    // TODO: Navigate to all exhibitions
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All exhibitions coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const DashboardLoadingWidget(message: 'Loading your dashboard...');
    }

    if (_errorMessage != null) {
      return DashboardErrorWidget(
        message: _errorMessage!,
        onRetry: _loadDashboardData,
      );
    }

    if (_dashboardData == null) {
      return const DashboardErrorWidget(
        message: 'No dashboard data available',
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.dashboard,
                color: AppTheme.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
          'Dashboard',
          style: TextStyle(
                fontSize: 24,
            fontWeight: FontWeight.bold,
                color: AppTheme.white,
          ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: AppTheme.white,
                  size: 20,
                ),
              ),
            onPressed: () {
              // TODO: Navigate to notifications
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications coming soon!')),
                );
            },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome section
            _buildWelcomeSection(context),
              const SizedBox(height: 24),
              
              // Hero Slider
              _buildHeroSlider(context),
              const SizedBox(height: 24),
            
            // Stats cards
            _buildStatsCards(context),
              const SizedBox(height: 24),
            
            // Recommended exhibitions
            _buildRecommendedExhibitions(context),
              const SizedBox(height: 24),
              
              // My Favorites section
              _buildMyFavorites(context),
              const SizedBox(height: 24),
              
              // Brand Look Book section
              _buildBrandLookBook(context),
              const SizedBox(height: 24),
              
              // Brand Gallery section
              _buildBrandGallery(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSlider(BuildContext context) {
    final heroSliders = _dashboardData!['heroSliders'] as List<dynamic>? ?? [];
    
    if (heroSliders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: ResponsiveUtils.getCardHeight(context) * 0.8,
      child: PageView.builder(
        itemCount: heroSliders.length,
        itemBuilder: (context, index) {
          final slider = heroSliders[index];
          final title = slider['title'] ?? '';
          final description = slider['description'] ?? '';
          final imageUrl = slider['image_url'] ?? '';
          final mobileImageUrl = slider['mobile_image_url'];
          final desktopImageUrl = slider['desktop_image_url'];
          final linkUrl = slider['link_url'];
          
          // Use responsive image based on screen size
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 768;
          final isTablet = screenWidth >= 768 && screenWidth < 1024;
          
          String finalImageUrl = imageUrl;
          if (isMobile && mobileImageUrl != null) {
            finalImageUrl = mobileImageUrl;
          } else if (!isMobile && desktopImageUrl != null) {
            finalImageUrl = desktopImageUrl;
          }

          return GestureDetector(
            onTap: linkUrl != null ? () {
              // TODO: Navigate to link URL
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Navigating to: $linkUrl')),
              );
            } : null,
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: ResponsiveUtils.getSpacing(context, mobile: 4, tablet: 8, desktop: 12),
              ),
      decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
        borderRadius: BorderRadius.circular(ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                child: Stack(
                  children: [
                    // Background Image
                    Positioned.fill(
                      child: Image.network(
                        finalImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppTheme.primaryBlue.withOpacity(0.1),
                            child: Icon(
                              Icons.image_not_supported,
                              size: ResponsiveUtils.getIconSize(context, mobile: 48, tablet: 64, desktop: 80),
                              color: AppTheme.primaryBlue,
                            ),
                          );
                        },
                      ),
                    ),
                    // Gradient overlay for text readability
                    Positioned.fill(
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
                        ),
                      ),
                    ),
                    // Content
                    if (title.isNotEmpty || description.isNotEmpty)
                      Positioned(
                        bottom: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 20, desktop: 24),
                        left: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 20, desktop: 24),
                        right: ResponsiveUtils.getSpacing(context, mobile: 16, tablet: 20, desktop: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                            if (title.isNotEmpty)
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getFontSize(context, mobile: 18, tablet: 22, desktop: 26),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 3,
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            if (title.isNotEmpty && description.isNotEmpty)
                              SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 4, tablet: 6, desktop: 8)),
                            if (description.isNotEmpty)
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: ResponsiveUtils.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                                  color: Colors.white.withOpacity(0.9),
                                  shadows: [
                                    Shadow(
                                      offset: const Offset(0, 1),
                                      blurRadius: 3,
                                      color: Colors.black.withOpacity(0.5),
                                    ),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final profile = _dashboardData!['profile'] as Map<String, dynamic>?;
    final fullName = profile?['full_name'] ?? 'Brand';
    final companyName = profile?['company_name'] ?? 'Company';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
            child: Icon(
              Icons.business,
              color: AppTheme.white,
                  size: 30,
            ),
          ),
              const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                      'Welcome back,',
                  style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                    color: AppTheme.white,
                  ),
                ),
                    if (companyName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                Text(
                        companyName,
                  style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                    color: AppTheme.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Your exhibitions are performing well!',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.white,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(BuildContext context) {
    final stats = _dashboardData!['stats'] as Map<String, dynamic>;
    final activeApplications = stats['activeApplications'] ?? 0;
    final upcomingExhibitions = stats['upcomingExhibitions'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          // Mobile: Stack vertically
          return Column(
            children: [
              _buildStatCard(
                title: 'Active Applications',
                value: activeApplications.toString(),
                icon: Icons.assignment,
                color: AppTheme.white,
                context: context,
              ),
              SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
              _buildStatCard(
                title: 'Upcoming Exhibitions',
                value: upcomingExhibitions.toString(),
                icon: Icons.event,
                color: AppTheme.white,
                context: context,
              ),
            ],
          );
        } else {
          // Tablet/Desktop: Side by side
          return Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Active Applications',
                  value: activeApplications.toString(),
                  icon: Icons.assignment,
                  color: AppTheme.white,
                  context: context,
                ),
              ),
              SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
              Expanded(
                child: _buildStatCard(
                  title: 'Upcoming Exhibitions',
                  value: upcomingExhibitions.toString(),
                  icon: Icons.event,
                  color: AppTheme.white,
                  context: context,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required BuildContext context,
  }) {
    return ResponsiveCard(
      padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, mobile: 6, tablet: 8, desktop: 10)),
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(ResponsiveUtils.getSpacing(context, mobile: 6, tablet: 8, desktop: 10)),
                  border: Border.all(
                    color: AppTheme.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.white,
                  size: ResponsiveUtils.getIconSize(context, mobile: 18, tablet: 20, desktop: 22),
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getFontSize(context, mobile: 20, tablet: 24, desktop: 28),
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 6, tablet: 8, desktop: 10)),
          Text(
            title,
            style: TextStyle(
              fontSize: ResponsiveUtils.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
              color: AppTheme.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }





  Widget _buildRecommendedExhibitions(BuildContext context) {
    final recommendedExhibitions = _dashboardData!['recommendedExhibitions'] as List<dynamic>? ?? [];

    if (recommendedExhibitions.isEmpty) {
      return DashboardEmptyWidget(
        title: 'No Recommended Exhibitions',
        message: 'We\'ll show you personalized recommendations based on your interests.',
        icon: Icons.event,
        onAction: _navigateToAllExhibitions,
        actionLabel: 'Browse Exhibitions',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Recommended Exhibitions',
          style: TextStyle(
            fontSize: ResponsiveUtils.getFontSize(context, mobile: 16, tablet: 18, desktop: 20),
            fontWeight: FontWeight.bold,
            color: AppTheme.white,
          ),
        ),
            TextButton(
              onPressed: _navigateToAllExhibitions,
              child: Text(
                'View All',
                style: TextStyle(
                  color: AppTheme.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 600) {
              // Mobile: Vertical list
              return Column(
                children: recommendedExhibitions.map<Widget>((exhibition) => 
                  Padding(
                    padding: EdgeInsets.only(bottom: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                    child: _buildExhibitionCard(exhibition, context, isMobile: true),
                  ),
                ).toList(),
              );
            } else {
              // Tablet/Desktop: Horizontal scroll
              return SizedBox(
                height: ResponsiveUtils.getCardHeight(context),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommendedExhibitions.length,
                  itemBuilder: (context, index) {
                    return _buildExhibitionCard(recommendedExhibitions[index], context, isMobile: false);
                  },
                ),
              );
            }
          },
                  ),
                ],
              );
  }

  Widget _buildMyFavorites(BuildContext context) {
    final favoriteExhibitions = _dashboardData!['favoriteExhibitions'] as List<dynamic>? ?? [];
    
    if (favoriteExhibitions.isEmpty) {
      return DashboardEmptyWidget(
        title: 'No Favorite Exhibitions',
        message: 'You haven\'t added any exhibitions to your favorites yet.',
        icon: Icons.favorite_border,
        onAction: () => _navigateToAllExhibitions(),
        actionLabel: 'Browse Exhibitions',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
                children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'My Favorites',
              style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context, mobile: 20, tablet: 24, desktop: 28),
                fontWeight: FontWeight.bold,
                color: AppTheme.textDarkCharcoal,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToAllExhibitions(),
              child: Text(
                'View All',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                  color: AppTheme.primaryBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: ResponsiveUtils.getCardHeight(context) * 0.6,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: favoriteExhibitions.length,
            itemBuilder: (context, index) {
              final favorite = favoriteExhibitions[index];
              final exhibition = favorite['exhibition'] as Map<String, dynamic>? ?? {};
              
              if (exhibition.isEmpty) return const SizedBox.shrink();
              
              return Container(
                width: ResponsiveUtils.getCardWidth(context) * 0.8,
                margin: EdgeInsets.only(
                  right: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20),
                ),
                child: ResponsiveCard(
                  onTap: () => _navigateToExhibitionDetails(exhibition['id']),
      isInteractive: true,
      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                      // Image section
          Container(
                        height: ResponsiveUtils.getCardHeight(context) * 0.4,
            decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                            topRight: Radius.circular(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                            topRight: Radius.circular(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                          ),
                          child: Builder(
                            builder: (context) {
                              final images = exhibition['images'] as List<dynamic>?;
                              final firstImageUrl = images != null && images.isNotEmpty ? images.first : null;
                              return firstImageUrl != null
                                  ? Image.network(
                                      firstImageUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Center(
            child: Icon(
                                          Icons.event,
                                          size: ResponsiveUtils.getIconSize(context, mobile: 28, tablet: 32, desktop: 40),
                                          color: AppTheme.primaryBlue,
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: Icon(
                                        Icons.event,
                                        size: ResponsiveUtils.getIconSize(context, mobile: 28, tablet: 32, desktop: 40),
                                        color: AppTheme.primaryBlue,
                                      ),
                                    );
                            },
                          ),
                        ),
                      ),
                      // Content section
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
          Text(
                                exhibition['title'] ?? 'Untitled Exhibition',
            style: TextStyle(
                                  fontSize: ResponsiveUtils.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                                  fontWeight: FontWeight.bold,
              color: AppTheme.textDarkCharcoal,
            ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              if (exhibition['start_date'] != null && exhibition['end_date'] != null) ...[
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: ResponsiveUtils.getIconSize(context, mobile: 14, tablet: 16, desktop: 18),
                                      color: AppTheme.textMediumGray,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${exhibition['start_date']} - ${exhibition['end_date']}',
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                          color: AppTheme.textMediumGray,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
          ),
        ],
      ),
                                const SizedBox(height: 4),
                              ],
                              if (exhibition['city'] != null || exhibition['state'] != null) ...[
                                Row(
      children: [
                                    Icon(
                                      Icons.location_on,
                                      size: ResponsiveUtils.getIconSize(context, mobile: 14, tablet: 16, desktop: 18),
                                      color: AppTheme.textMediumGray,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${exhibition['city'] ?? ''}${exhibition['city'] != null && exhibition['state'] != null ? ', ' : ''}${exhibition['state'] ?? ''}',
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                          color: AppTheme.textMediumGray,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
                                  Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: ResponsiveUtils.getIconSize(context, mobile: 16, tablet: 18, desktop: 20),
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _navigateToExhibitionDetails(exhibition['id']),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryBlue,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20),
                                        vertical: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 10, desktop: 12),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 10, desktop: 12)),
                                      ),
                                    ),
                                    child: Text(
                                      'View Details',
              style: TextStyle(
                                        fontSize: ResponsiveUtils.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                        fontWeight: FontWeight.w600,
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
            },
          ),
        ),
      ],
    );
  }

  Widget _buildExhibitionCard(Map<String, dynamic> exhibition, BuildContext context, {required bool isMobile}) {
    final title = exhibition['title'] ?? 'Untitled Exhibition';
    final startDate = exhibition['start_date'] != null 
        ? DateTime.parse(exhibition['start_date']).toString().split(' ')[0]
        : 'TBD';
    final endDate = exhibition['end_date'] != null 
        ? DateTime.parse(exhibition['end_date']).toString().split(' ')[0]
        : 'TBD';
    final city = exhibition['city'] ?? 'Location TBD';
    final state = exhibition['state'] ?? '';
    final location = state.isNotEmpty ? '$city, $state' : city;
    
    // Get the first image from the images array or use null
    final images = exhibition['images'] as List<dynamic>?;
    final firstImageUrl = images != null && images.isNotEmpty ? images.first : null;
    final hasBannerImage = firstImageUrl != null;

    if (isMobile) {
      // Mobile: Full width card
      return ResponsiveCard(
        onTap: () => _navigateToExhibitionDetails(exhibition['id']),
        isInteractive: true,
        child: Row(
          children: [
            Container(
              width: ResponsiveUtils.getCardWidth(context) * 0.3,
              height: ResponsiveUtils.getCardHeight(context) * 0.6,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                child: hasBannerImage
                    ? Image.network(
                        firstImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                Icons.event,
                size: ResponsiveUtils.getIconSize(context, mobile: 24, tablet: 32, desktop: 40),
                color: AppTheme.primaryBlue,
                        ),
                      )
                    : Icon(
                        Icons.event,
                        size: ResponsiveUtils.getIconSize(context, mobile: 24, tablet: 32, desktop: 40),
                        color: AppTheme.primaryBlue,
                      ),
              ),
            ),
            SizedBox(width: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDarkCharcoal,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 2, tablet: 4, desktop: 6)),
                  Text(
                    '$startDate - $endDate',
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                      color: AppTheme.textMediumGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 2, tablet: 4, desktop: 6)),
                  Text(
                    location,
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                      color: AppTheme.textMediumGray,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // Tablet/Desktop: Fixed width card
      return Container(
        width: ResponsiveUtils.getCardWidth(context),
        margin: EdgeInsets.only(right: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
        child: ResponsiveCard(
          onTap: () => _navigateToExhibitionDetails(exhibition['id']),
          isInteractive: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: ResponsiveUtils.getCardHeight(context) * 0.45,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                    topRight: Radius.circular(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                    topRight: Radius.circular(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                  ),
                  child: hasBannerImage
                      ? Image.network(
                          firstImageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                  child: Icon(
                    Icons.event,
                    size: ResponsiveUtils.getIconSize(context, mobile: 28, tablet: 32, desktop: 40),
                    color: AppTheme.primaryBlue,
                            ),
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.event,
                            size: ResponsiveUtils.getIconSize(context, mobile: 28, tablet: 32, desktop: 40),
                            color: AppTheme.primaryBlue,
                          ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: ResponsiveUtils.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDarkCharcoal,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 2, tablet: 4, desktop: 6)),
                      Text(
                        '$startDate - $endDate',
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                          color: AppTheme.textMediumGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: ResponsiveUtils.getSpacing(context, mobile: 2, tablet: 4, desktop: 6)),
                      Text(
                        location,
                        style: TextStyle(
                          fontSize: ResponsiveUtils.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                          color: AppTheme.textMediumGray,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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

  Widget _buildBrandLookBook(BuildContext context) {
    final brandLookbooks = _dashboardData!['brandLookbooks'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Brand Look Book',
              style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context, mobile: 20, tablet: 24, desktop: 28),
                fontWeight: FontWeight.bold,
                color: AppTheme.textDarkCharcoal,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final currentUser = _supabaseService.currentUser;
                if (currentUser != null) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BrandLookbookFormScreen(
                        brandId: currentUser.id,
                      ),
                    ),
                  );
                  if (result == true) {
                    // Refresh dashboard data
                    _loadDashboardData();
                  }
                }
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                'Add Look Book',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20),
                  vertical: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 10, desktop: 12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 10, desktop: 12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (brandLookbooks.isEmpty)
          DashboardEmptyWidget(
            title: 'No Look Books Yet',
            message: 'Start building your brand portfolio by adding your first look book.',
            icon: Icons.book_outlined,
            onAction: () async {
              final currentUser = _supabaseService.currentUser;
              if (currentUser != null) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BrandLookbookFormScreen(
                      brandId: currentUser.id,
                    ),
                  ),
                );
                if (result == true) {
                  // Refresh dashboard data
                  _loadDashboardData();
                }
              }
            },
            actionLabel: 'Add First Look Book',
          )
        else
          SizedBox(
            height: ResponsiveUtils.getCardHeight(context) * 0.5,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: brandLookbooks.length,
              itemBuilder: (context, index) {
                final lookbook = brandLookbooks[index];
                
                return Container(
                  width: ResponsiveUtils.getCardWidth(context) * 0.7,
                  margin: EdgeInsets.only(
                    right: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20),
                  ),
                  child: GestureDetector(
                    onLongPress: () {
                      _showLookbookContextMenu(context, lookbook);
                    },
                    child: ResponsiveCard(
                      onTap: () {
                        // TODO: Navigate to lookbook details or open file
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Opening: ${lookbook['title']}')),
                        );
                      },
                      isInteractive: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // File preview section
                          Container(
                            height: ResponsiveUtils.getCardHeight(context) * 0.35,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                                topRight: Radius.circular(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                                topRight: Radius.circular(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                                      _getFileTypeIcon(lookbook['file_type']),
                                      size: ResponsiveUtils.getIconSize(context, mobile: 32, tablet: 40, desktop: 48),
                                      color: AppTheme.primaryBlue,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      lookbook['file_type']?.toUpperCase() ?? 'FILE',
                              style: TextStyle(
                                fontSize: ResponsiveUtils.getFontSize(context, mobile: 10, tablet: 12, desktop: 14),
                                        color: AppTheme.primaryBlue,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Content section
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lookbook['title'] ?? 'Untitled Look Book',
                                    style: TextStyle(
                                      fontSize: ResponsiveUtils.getFontSize(context, mobile: 14, tablet: 16, desktop: 18),
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textDarkCharcoal,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (lookbook['description'] != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      lookbook['description'],
                                      style: TextStyle(
                                        fontSize: ResponsiveUtils.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                                color: AppTheme.textMediumGray,
                              ),
                                      maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Added ${_formatDate(lookbook['created_at'])}',
                                        style: TextStyle(
                                          fontSize: ResponsiveUtils.getFontSize(context, mobile: 10, tablet: 12, desktop: 14),
                                          color: AppTheme.textMediumGray,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          _showLookbookContextMenu(context, lookbook);
                                        },
                                        icon: Icon(
                                          Icons.more_vert,
                                          size: ResponsiveUtils.getIconSize(context, mobile: 16, tablet: 18, desktop: 20),
                                          color: AppTheme.textMediumGray,
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
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  IconData _getFileTypeIcon(String? fileType) {
    switch (fileType?.toLowerCase()) {
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
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'recently';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'today';
      } else if (difference.inDays == 1) {
        return 'yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '$weeks week${weeks == 1 ? '' : 's'} ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'recently';
    }
  }

  Widget _buildBrandGallery(BuildContext context) {
    final brandGallery = _dashboardData!['brandGallery'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
              'Brand Gallery',
          style: TextStyle(
                fontSize: ResponsiveUtils.getFontSize(context, mobile: 20, tablet: 24, desktop: 28),
            fontWeight: FontWeight.bold,
            color: AppTheme.textDarkCharcoal,
          ),
        ),
            ElevatedButton.icon(
              onPressed: () async {
                final currentUser = _supabaseService.currentUser;
                if (currentUser != null) {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BrandGalleryFormScreen(
                        brandId: currentUser.id,
                      ),
                    ),
                  );
                  if (result == true) {
                    // Refresh dashboard data
                    _loadDashboardData();
                  }
                }
              },
              icon: const Icon(Icons.add_photo_alternate, size: 18),
              label: Text(
                'Add Image',
                style: TextStyle(
                  fontSize: ResponsiveUtils.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20),
                  vertical: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 10, desktop: 12),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 10, desktop: 12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (brandGallery.isEmpty)
          DashboardEmptyWidget(
            title: 'No Gallery Images Yet',
            message: 'Showcase your brand with beautiful images. Start building your visual portfolio.',
            icon: Icons.photo_library_outlined,
            onAction: () async {
              final currentUser = _supabaseService.currentUser;
              if (currentUser != null) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BrandGalleryFormScreen(
                      brandId: currentUser.id,
                    ),
                  ),
                );
                if (result == true) {
                  // Refresh dashboard data
                  _loadDashboardData();
                }
              }
            },
            actionLabel: 'Add First Image',
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                // Mobile: 2 columns
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16),
                    mainAxisSpacing: ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16),
                    childAspectRatio: 1.0,
                  ),
                  itemCount: brandGallery.length,
                  itemBuilder: (context, index) {
                    final galleryItem = brandGallery[index];
                    return _buildGalleryItem(context, galleryItem, isMobile: true);
                  },
                );
              } else {
                // Tablet/Desktop: 3 columns
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20),
                    mainAxisSpacing: ResponsiveUtils.getSpacing(context, mobile: 12, tablet: 16, desktop: 20),
                    childAspectRatio: 1.0,
                  ),
                  itemCount: brandGallery.length,
                  itemBuilder: (context, index) {
                    final galleryItem = brandGallery[index];
                    return _buildGalleryItem(context, galleryItem, isMobile: false);
                  },
                );
              }
            },
          ),
      ],
    );
  }

  Widget _buildGalleryItem(BuildContext context, Map<String, dynamic> galleryItem, {required bool isMobile}) {
    return ResponsiveCard(
      onTap: () {
        // TODO: Navigate to gallery item details or show full screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Viewing: ${galleryItem['title'] ?? 'Image'}')),
        );
      },
      isInteractive: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image section
          Expanded(
            child: Container(
              width: double.infinity,
            decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                  topRight: Radius.circular(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                  topRight: Radius.circular(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
                ),
                child: galleryItem['image_url'] != null
                    ? Image.network(
                        galleryItem['image_url'],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
            child: Icon(
                            Icons.image_not_supported,
                            size: ResponsiveUtils.getIconSize(context, mobile: 24, tablet: 32, desktop: 40),
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.image,
                          size: ResponsiveUtils.getIconSize(context, mobile: 24, tablet: 32, desktop: 40),
                          color: AppTheme.primaryBlue,
                        ),
                      ),
              ),
            ),
          ),
          // Content section
          Padding(
            padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, mobile: 8, tablet: 12, desktop: 16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (galleryItem['title'] != null) ...[
                Text(
                    galleryItem['title'],
              style: TextStyle(
                      fontSize: ResponsiveUtils.getFontSize(context, mobile: 12, tablet: 14, desktop: 16),
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textDarkCharcoal,
                  ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ],
                if (galleryItem['description'] != null) ...[
                Text(
                    galleryItem['description'],
                    style: TextStyle(
                      fontSize: ResponsiveUtils.getFontSize(context, mobile: 10, tablet: 12, desktop: 14),
                    color: AppTheme.textMediumGray,
                  ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDate(galleryItem['created_at']),
                      style: TextStyle(
                        fontSize: ResponsiveUtils.getFontSize(context, mobile: 8, tablet: 10, desktop: 12),
                        color: AppTheme.textMediumGray,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        _showGalleryContextMenu(context, galleryItem);
                      },
                      icon: Icon(
                        Icons.more_vert,
                        size: ResponsiveUtils.getIconSize(context, mobile: 14, tablet: 16, desktop: 18),
                        color: AppTheme.textMediumGray,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLookbookContextMenu(BuildContext context, Map<String, dynamic> lookbook) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: AppTheme.primaryBlue),
                title: const Text('Edit Lookbook'),
                onTap: () async {
                  Navigator.pop(context);
                  final currentUser = _supabaseService.currentUser;
                  if (currentUser != null) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BrandLookbookFormScreen(
                          lookbook: lookbook,
                          brandId: currentUser.id,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadDashboardData();
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Lookbook'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Delete Lookbook'),
                      content: Text('Are you sure you want to delete "${lookbook['title']}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true) {
                    try {
                      final success = await _supabaseService.deleteBrandLookbook(lookbook['id']);
                      if (success) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Lookbook deleted successfully!')),
                          );
                          _loadDashboardData();
                        }
                      } else {
                        throw Exception('Failed to delete lookbook');
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error deleting lookbook: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showGalleryContextMenu(BuildContext context, Map<String, dynamic> galleryItem) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: AppTheme.primaryBlue),
                title: const Text('Edit Gallery Item'),
                onTap: () async {
                  Navigator.pop(context);
                  final currentUser = _supabaseService.currentUser;
                  if (currentUser != null) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BrandGalleryFormScreen(
                          galleryItem: galleryItem,
                          brandId: currentUser.id,
                        ),
                      ),
                    );
                    if (result == true) {
                      _loadDashboardData();
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Gallery Item'),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Delete Gallery Item'),
                      content: Text('Are you sure you want to delete "${galleryItem['title'] ?? 'this image'}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true) {
                    try {
                      final success = await _supabaseService.deleteBrandGalleryItem(galleryItem['id']);
                      if (success) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Gallery item deleted successfully!')),
                          );
                          _loadDashboardData();
                        }
                      } else {
                        throw Exception('Failed to delete gallery item');
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error deleting gallery item: ${e.toString()}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
