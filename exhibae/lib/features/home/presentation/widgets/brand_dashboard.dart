import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/utils/responsive_utils.dart';
import '../../../../core/widgets/responsive_card.dart';
import '../../../../core/widgets/dashboard_loading_widget.dart';
import '../../../../core/widgets/dashboard_error_widget.dart';
import '../../../../core/widgets/dashboard_empty_widget.dart';
import '../../../../core/services/dashboard_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../brand/presentation/screens/brand_lookbook_form_screen.dart';
import '../../../brand/presentation/screens/brand_lookbook_list_screen.dart';
import '../../../brand/presentation/screens/brand_gallery_form_screen.dart';
import '../../../brand/presentation/screens/brand_gallery_list_screen.dart';
import '../../../brand/presentation/widgets/exhibition_card.dart';
import '../screens/home_screen.dart';

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

      final currentUser = _supabaseService.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final data = await _dashboardService.getBrandDashboardData(currentUser.id);
      
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
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
    // Navigate to home screen with explore tab (index 1)
    Navigator.pushNamedAndRemoveUntil(
      context, 
      '/home', 
      (route) => false,
      arguments: {'initialTab': 1},
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const DashboardLoadingWidget();
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
                color: AppTheme.primaryMaroon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.borderLightGray,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.dashboard,
                color: AppTheme.primaryMaroon,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryMaroon,
              ),
            ),
          ],
        ),
        actions: [
          // Favorite exhibitions button
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMaroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.borderLightGray,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.favorite,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/favorite-exhibitions');
              },
            ),
          ),
          // Notifications button
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMaroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.borderLightGray,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: AppTheme.primaryMaroon,
                  size: 20,
                ),
              ),
              onPressed: () {
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
        color: AppTheme.primaryMaroon,
        backgroundColor: AppTheme.backgroundPeach,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(context),
              const SizedBox(height: 20),
              _buildHeroSlider(context),
              const SizedBox(height: 20),
              _buildStatsCards(context),
              const SizedBox(height: 20),
              _buildRecommendedExhibitions(context),
              const SizedBox(height: 20),
              _buildCityBasedExhibitions(context),
              const SizedBox(height: 20),
              _buildBrandLookBook(context),
              const SizedBox(height: 20),
              _buildBrandGallery(context),
              const SizedBox(height: 20), // Bottom padding
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(BuildContext context) {
    final profile = _dashboardData!['profile'] as Map<String, dynamic>?;
    final fullName = profile?['full_name'] ?? 'Brand';
    final companyName = profile?['company_name'] ?? 'Company';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPeach.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.borderLightGray,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryMaroon.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryMaroon.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.business,
                  color: AppTheme.primaryMaroon,
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
                        color: AppTheme.primaryMaroon.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fullName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    if (companyName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        companyName,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.primaryMaroon.withOpacity(0.9),
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
              color: AppTheme.primaryMaroon.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.borderLightGray,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  color: AppTheme.primaryMaroon,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Welcome to your brand dashboard!',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryMaroon,
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

  Widget _buildHeroSlider(BuildContext context) {
    final heroSliders = _dashboardData!['heroSliders'] as List<dynamic>? ?? [];
    
    if (heroSliders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 150,
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
                          mainAxisSize: MainAxisSize.min,
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

  Widget _buildStatsCards(BuildContext context) {
    final stats = _dashboardData!['stats'] as Map<String, dynamic>;
    final activeApplications = stats['activeApplications'] ?? 0;
    final upcomingExhibitions = stats['upcomingExhibitions'] ?? 0;

    return Container(
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Active Applications',
              value: activeApplications.toString(),
              icon: Icons.assignment,
              color: AppTheme.primaryMaroon,
              context: context,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: 'Upcoming Exhibitions',
              value: upcomingExhibitions.toString(),
              icon: Icons.event,
              color: AppTheme.primaryBlue,
              context: context,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required BuildContext context,
  }) {
    return Container(
      height: 100,
      child: ResponsiveCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 18,
                  ),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textMediumGray,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendedExhibitions(BuildContext context) {
    final recommendedExhibitions = _dashboardData!['recommendedExhibitions'] as List<dynamic>? ?? [];

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recommended Exhibitions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryMaroon,
                ),
              ),
              TextButton(
                onPressed: _navigateToAllExhibitions,
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.primaryMaroon,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recommendedExhibitions.isEmpty)
            ResponsiveCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.recommend_outlined,
                    size: 48,
                    color: AppTheme.primaryMaroon.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Recommended Exhibitions',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'We\'ll show you personalized exhibition recommendations here.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _navigateToAllExhibitions,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryMaroon,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.search),
                    label: const Text('Browse Exhibitions'),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  // Mobile: Vertical list
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: recommendedExhibitions.take(2).map<Widget>((exhibition) => 
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildExhibitionCard(exhibition, context, isMobile: true),
                      ),
                    ).toList(),
                  );
                } else {
                  // Tablet/Desktop: Horizontal scroll
                  return SizedBox(
                    height: 180,
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
      ),
    );
  }

  Widget _buildCityBasedExhibitions(BuildContext context) {
    final cities = _dashboardData!['cities'] as List<dynamic>? ?? [];
    final selectedCity = _dashboardData!['selectedCity'] as String? ?? 'Delhi';
    final exhibitions = _dashboardData!['exhibitionsByCity'] as List<dynamic>? ?? [];

    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Exhibitions in $selectedCity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryMaroon,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _onCityChanged(selectedCity),
                    icon: Icon(
                      Icons.refresh,
                      color: AppTheme.primaryMaroon,
                      size: 20,
                    ),
                    tooltip: 'Refresh exhibitions',
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: selectedCity,
                    icon: Icon(Icons.arrow_drop_down, color: AppTheme.primaryMaroon),
                    iconSize: 20,
                    elevation: 16,
                    style: TextStyle(
                      color: AppTheme.primaryMaroon,
                      fontSize: 14,
                    ),
                    underline: Container(
                      height: 2,
                      color: AppTheme.primaryMaroon,
                    ),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        _onCityChanged(newValue);
                      }
                    },
                    items: cities.map<DropdownMenuItem<String>>((dynamic city) {
                      return DropdownMenuItem<String>(
                        value: city.toString(),
                        child: Text(
                          city.toString(),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildExhibitionsByCity(context, selectedCity),
        ],
      ),
    );
  }

  Future<void> _onCityChanged(String newCity) async {
    try {
      setState(() {
        _dashboardData!['selectedCity'] = newCity;
        _dashboardData!['exhibitionsByCity'] = []; // Clear previous exhibitions
      });

      // Use the processed exhibitions data from dashboard service instead of fetching again
      final allExhibitions = _dashboardData!['allExhibitions'] as List<dynamic>? ?? [];
      final cityExhibitions = allExhibitions.where((exhibition) => 
        exhibition['city']?.toString() == newCity
      ).toList();

      setState(() {
        _dashboardData!['exhibitionsByCity'] = cityExhibitions;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Found ${cityExhibitions.length} exhibition${cityExhibitions.length == 1 ? '' : 's'} in $newCity'),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading exhibitions for $newCity: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Widget _buildExhibitionsByCity(BuildContext context, String city) {
    final exhibitions = _dashboardData!['exhibitionsByCity'] as List<dynamic>? ?? [];

    if (exhibitions.isEmpty) {
      return ResponsiveCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.event_outlined,
              size: 48,
              color: AppTheme.primaryMaroon.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No Exhibitions in $city',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No exhibitions have been scheduled in $city yet. Check back later for new exhibitions.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (exhibitions.isNotEmpty) ...[
          Text(
            'Found ${exhibitions.length} exhibition${exhibitions.length == 1 ? '' : 's'} in $city',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMediumGray,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                // Mobile: Vertical list
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: exhibitions.take(2).map<Widget>((exhibition) => 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildExhibitionCard(exhibition, context, isMobile: true),
                    ),
                  ).toList(),
                );
              } else {
                // Tablet/Desktop: Horizontal scroll
                return SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: exhibitions.length,
                    itemBuilder: (context, index) {
                      return _buildExhibitionCard(exhibitions[index], context, isMobile: false);
                    },
                  ),
                );
              }
            },
          ),
        ],
      ],
    );
  }

  Widget _buildBrandLookBook(BuildContext context) {
    final brandLookbooks = _dashboardData!['brandLookbooks'] as List<dynamic>? ?? [];
    
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'My Look Book',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryMaroon,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
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
                          _loadDashboardData();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryMaroon,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final currentUser = _supabaseService.currentUser;
                      if (currentUser != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BrandLookbookListScreen(
                              brandId: currentUser.id,
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.visibility, size: 14, color: Colors.black87),
                    label: const Text('View All', style: TextStyle(color: Colors.black87)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (brandLookbooks.isEmpty)
            ResponsiveCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 48,
                    color: AppTheme.primaryMaroon.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Look Books Yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start building your brand portfolio by adding your first look book.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
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
                          _loadDashboardData();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryMaroon,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Lookbook'),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: brandLookbooks.length,
                itemBuilder: (context, index) {
                  final lookbook = brandLookbooks[index];
                  
                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    child: ResponsiveCard(
                      onTap: () {
                        _showLookbookPreview(context, lookbook);
                      },
                      isInteractive: true,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            height: 70,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryMaroon.withOpacity(0.1),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                            child: lookbook['file_url'] != null && _isImageFile(_getFileTypeFromName(lookbook['file_name']))
                                ? _buildImageWidget(lookbook['file_url'])
                                : Center(
                                    child: Icon(
                                      _getFileTypeIcon(_getFileTypeFromName(lookbook['file_name'])),
                                      size: 20,
                                      color: AppTheme.primaryMaroon,
                                    ),
                                  ),
                          ),
                          Flexible(
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(
                                    child: Text(
                                      lookbook['file_name'] ?? 'Untitled Look Book',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(lookbook['created_at']),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: AppTheme.textMediumGray,
                                    ),
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
      ),
    );
  }

  Widget _buildBrandGallery(BuildContext context) {
    final brandGallery = _dashboardData!['brandGallery'] as List<dynamic>? ?? [];
    
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'My Gallery',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryMaroon,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
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
                          _loadDashboardData();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryMaroon,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Icon(Icons.add, size: 16, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final currentUser = _supabaseService.currentUser;
                      if (currentUser != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BrandGalleryListScreen(
                              brandId: currentUser.id,
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.visibility, size: 14, color: Colors.black87),
                    label: const Text('View All', style: TextStyle(color: Colors.black87)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (brandGallery.isEmpty)
            ResponsiveCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 48,
                    color: AppTheme.primaryMaroon.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Gallery Images Yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Showcase your brand with beautiful images. Start building your visual portfolio.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
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
                          _loadDashboardData();
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryMaroon,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Image'),
                  ),
                ],
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 600) {
                  return SizedBox(
                    height: 160,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: brandGallery.length,
                      itemBuilder: (context, index) {
                        final galleryItem = brandGallery[index];
                        return Container(
                          width: 180,
                          margin: const EdgeInsets.only(right: 16),
                          child: _buildGalleryItem(context, galleryItem, isMobile: true),
                        );
                      },
                    ),
                  );
                } else {
                  return SizedBox(
                    height: 180,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: brandGallery.length,
                      itemBuilder: (context, index) {
                        final galleryItem = brandGallery[index];
                        return Container(
                          width: 220,
                          margin: const EdgeInsets.only(right: 20),
                          child: _buildGalleryItem(context, galleryItem, isMobile: false),
                        );
                      },
                    ),
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGalleryItem(BuildContext context, Map<String, dynamic> galleryItem, {required bool isMobile}) {
    return ResponsiveCard(
      onTap: () {
        _showGalleryPreview(context, galleryItem);
      },
      isInteractive: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Image preview - larger and more adaptive
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                child: _getGalleryImageUrl(galleryItem) != null
                    ? _buildResponsiveImageWidget(_getGalleryImageUrl(galleryItem)!, isMobile)
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.image,
                              size: isMobile ? 32 : 40,
                              color: AppTheme.primaryBlue,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'No Image',
                              style: TextStyle(
                                fontSize: isMobile ? 10 : 12,
                                color: AppTheme.textMediumGray,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
          // Text content - more spacious and readable
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 8 : 12,
                vertical: isMobile ? 8 : 10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  if (galleryItem['title'] != null)
                    Expanded(
                      flex: 2,
                      child: Text(
                        galleryItem['title'],
                        style: TextStyle(
                          fontSize: isMobile ? 12 : 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textDarkCharcoal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  // Date and menu
                  Expanded(
                    flex: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _formatDate(galleryItem['created_at']),
                            style: TextStyle(
                              fontSize: isMobile ? 10 : 11,
                              color: AppTheme.textMediumGray,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            _showGalleryContextMenu(context, galleryItem);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.more_vert,
                              size: isMobile ? 16 : 18,
                              color: AppTheme.textMediumGray,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget(String imageUrl) {
    // Handle empty or null URLs
    if (imageUrl.isEmpty) {
      return Center(
        child: Icon(
          Icons.image_not_supported,
          size: ResponsiveUtils.getIconSize(context, mobile: 24, tablet: 32, desktop: 40),
          color: AppTheme.primaryBlue,
        ),
      );
    }

    // Handle base64 encoded images (legacy support)
    if (imageUrl.startsWith('data:image')) {
      try {
      return Image.memory(
        base64Decode(imageUrl.substring(imageUrl.indexOf(',') + 1)),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Center(
          child: Icon(
            Icons.image_not_supported,
            size: ResponsiveUtils.getIconSize(context, mobile: 24, tablet: 32, desktop: 40),
            color: AppTheme.primaryBlue,
          ),
            );
          },
        );
      } catch (e) {
        return Center(
          child: Icon(
            Icons.image_not_supported,
            size: ResponsiveUtils.getIconSize(context, mobile: 24, tablet: 32, desktop: 40),
            color: AppTheme.primaryBlue,
          ),
        );
      }
    } 
    // Handle network images
    else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
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
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: ResponsiveUtils.getIconSize(context, mobile: 24, tablet: 32, desktop: 40),
                color: AppTheme.primaryBlue,
              ),
            ],
          ),
        ),
      );
    }
    // Handle local file paths or other formats
    else {
      return Center(
        child: Icon(
          Icons.image_not_supported,
          size: ResponsiveUtils.getIconSize(context, mobile: 24, tablet: 32, desktop: 40),
          color: AppTheme.primaryBlue,
        ),
      );
    }
  }

  Widget _buildResponsiveImageWidget(String imageUrl, bool isMobile) {
    // Handle empty or null URLs
    if (imageUrl.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: isMobile ? 28 : 36,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(height: 6),
            Text(
              'No Image',
              style: TextStyle(
                fontSize: isMobile ? 9 : 11,
                color: AppTheme.textMediumGray,
              ),
            ),
          ],
        ),
      );
    }

    // Handle base64 encoded images
    if (imageUrl.startsWith('data:image')) {
      try {
        return Image.memory(
          base64Decode(imageUrl.substring(imageUrl.indexOf(',') + 1)),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_not_supported,
                  size: isMobile ? 28 : 36,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(height: 6),
                Text(
                  'Image not available',
                  style: TextStyle(
                    fontSize: isMobile ? 9 : 11,
                    color: AppTheme.textMediumGray,
                  ),
                ),
              ],
            ),
          ),
        );
      } catch (e) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: isMobile ? 28 : 36,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 6),
              Text(
                'Invalid Image',
                style: TextStyle(
                  fontSize: isMobile ? 9 : 11,
                  color: AppTheme.textMediumGray,
                ),
              ),
            ],
          ),
        );
      }
    } 
    // Handle network images
    else if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
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
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: isMobile ? 28 : 36,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 6),
              Text(
                'Image not available',
                style: TextStyle(
                  fontSize: isMobile ? 9 : 11,
                  color: AppTheme.textMediumGray,
                ),
              ),
            ],
          ),
        ),
      );
    }
    // Handle local file paths or other formats
    else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported,
              size: isMobile ? 28 : 36,
              color: AppTheme.primaryBlue,
            ),
            const SizedBox(height: 6),
            Text(
              'Unsupported format',
              style: TextStyle(
                fontSize: isMobile ? 9 : 11,
                color: AppTheme.textMediumGray,
              ),
            ),
          ],
        ),
      );
    }
  }

  bool _isImageFile(String? fileType) {
    if (fileType == null) return false;
    final imageTypes = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return imageTypes.contains(fileType.toLowerCase());
  }

  String? _getFileTypeFromName(String? fileName) {
    if (fileName == null) return null;
    final extension = fileName.split('.').last.toLowerCase();
    return extension;
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
                leading: const Icon(Icons.edit, color: AppTheme.primaryMaroon),
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
                leading: const Icon(Icons.edit, color: AppTheme.primaryMaroon),
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

  Widget _buildExhibitionCard(Map<String, dynamic> exhibition, BuildContext context, {required bool isMobile}) {
    return Container(
      width: isMobile ? double.infinity : 280,
      margin: EdgeInsets.only(
        right: isMobile ? 0 : 12,
        bottom: isMobile ? 12 : 0,
      ),
      child: ExhibitionCard(
        exhibition: exhibition,
        isListView: isMobile,
        onTap: () => _navigateToExhibitionDetails(exhibition['id']),
        onFavorite: () async {
          try {
            final currentUser = _supabaseService.currentUser;
            if (currentUser != null) {
              await _supabaseService.toggleExhibitionFavorite(
                currentUser.id,
                exhibition['id'],
              );
              
              // Update the local state immediately for better UX
              setState(() {
                // Update favorite status in recommended exhibitions
                final recommendedIndex = _dashboardData!['recommendedExhibitions'].indexWhere(
                  (e) => e['id'] == exhibition['id']
                );
                if (recommendedIndex != -1) {
                  _dashboardData!['recommendedExhibitions'][recommendedIndex]['isFavorite'] = 
                    !(_dashboardData!['recommendedExhibitions'][recommendedIndex]['isFavorite'] ?? false);
                }
                
                // Update favorite status in city exhibitions
                final cityIndex = _dashboardData!['exhibitionsByCity'].indexWhere(
                  (e) => e['id'] == exhibition['id']
                );
                if (cityIndex != -1) {
                  _dashboardData!['exhibitionsByCity'][cityIndex]['isFavorite'] = 
                    !(_dashboardData!['exhibitionsByCity'][cityIndex]['isFavorite'] ?? false);
                }
              });
              
              // Show success message
              final isNowFavorite = !(exhibition['isFavorite'] ?? false);
              final message = isNowFavorite ? 'Added to favorites' : 'Removed from favorites';
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(message),
                    backgroundColor: AppTheme.successGreen,
                  ),
                );
              }
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
        },
      ),
    );
  }

  String _formatExhibitionDate(String? startDate, String? endDate) {
    if (startDate == null) return 'Date TBD';
    
    try {
      final start = DateTime.parse(startDate);
      final end = endDate != null ? DateTime.parse(endDate) : null;
      
      if (end != null && start.year == end.year && start.month == end.month && start.day == end.day) {
        // Same day
        return '${start.day} ${_getMonthName(start.month)} ${start.year}';
      } else if (end != null && start.year == end.year && start.month == end.month) {
        // Same month
        return '${start.day}-${end.day} ${_getMonthName(start.month)} ${start.year}';
      } else if (end != null && start.year == end.year) {
        // Same year
        return '${start.day} ${_getMonthName(start.month)} - ${end.day} ${_getMonthName(end.month)} ${start.year}';
      } else if (end != null) {
        // Different years
        return '${start.day} ${_getMonthName(start.month)} ${start.year} - ${end.day} ${_getMonthName(end.month)} ${end.year}';
      } else {
        // Only start date
        return '${start.day} ${_getMonthName(start.month)} ${start.year}';
      }
    } catch (e) {
      return 'Date TBD';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  String? _getGalleryImageUrl(Map<String, dynamic> galleryItem) {
    // Try different possible image URL fields
    final possibleFields = ['image_url', 'file_url', 'url', 'image', 'file'];
    
    for (final field in possibleFields) {
      final value = galleryItem[field];
      if (value != null && value.toString().isNotEmpty) {
        return value.toString();
      }
    }
    
    return null;
  }

  void _showLookbookPreview(BuildContext context, Map<String, dynamic> lookbook) {
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
                        _getFileTypeIcon(_getFileTypeFromName(lookbook['file_name'])),
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          lookbook['file_name'] ?? 'Untitled Look Book',
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
                        if (lookbook['description'] != null) ...[
                          Text(
                            lookbook['description'],
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        // File preview
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: lookbook['file_url'] != null && _isImageFile(_getFileTypeFromName(lookbook['file_name']))
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
                                          _getFileTypeIcon(_getFileTypeFromName(lookbook['file_name'])),
                                          size: 64,
                                          color: AppTheme.primaryMaroon,
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          _getFileTypeFromName(lookbook['file_name'])?.toUpperCase() ?? 'FILE',
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
                                            // TODO: Open file in external viewer
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Opening: ${lookbook['file_name']}')),
                                            );
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
                              _getFileTypeFromName(lookbook['file_name'])?.toUpperCase() ?? 'FILE',
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

  void _showGalleryPreview(BuildContext context, Map<String, dynamic> galleryItem) {
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
                    color: AppTheme.primaryBlue,
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
                        if (galleryItem['description'] != null) ...[
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
                            child: _getGalleryImageUrl(galleryItem) != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: _buildImageWidget(_getGalleryImageUrl(galleryItem)!),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image_not_supported,
                                          size: 64,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'No image available',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 16,
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
                                color: AppTheme.primaryBlue,
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
}
