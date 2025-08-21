import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../widgets/featured_exhibition_card.dart';
import '../widgets/upcoming_event_card.dart';
import '../widgets/category_filter.dart';
import '../widgets/dynamic_location_selector.dart';


class ShopperHomeScreen extends StatefulWidget {
  const ShopperHomeScreen({super.key});

  @override
  State<ShopperHomeScreen> createState() => _ShopperHomeScreenState();
}

class _ShopperHomeScreenState extends State<ShopperHomeScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  List<Map<String, dynamic>> _recentExhibitions = [];
  List<Map<String, dynamic>> _upcomingEvents = [];
  List<Map<String, dynamic>> _nearbyEvents = [];
  List<String> _availableCities = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  String _selectedLocation = 'Gautam Buddha Nagar';

  @override
  void initState() {
    super.initState();
    _loadAvailableCities();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // First, let's check what data exists in the exhibitions table
      print('=== DEBUGGING EXHIBITIONS DATA ===');
      
      // Check all exhibitions regardless of status
      final allExhibitions = await _supabaseService.client
          .from('exhibitions')
          .select()
          .limit(10);
      print('All exhibitions (any status): ${allExhibitions.length}');
      if (allExhibitions.isNotEmpty) {
        print('Sample exhibition: ${allExhibitions.first}');
      }

      // Check approved exhibitions
      final approvedExhibitions = await _supabaseService.client
          .from('exhibitions')
          .select()
          .eq('status', 'approved')
          .limit(10);
      print('Approved exhibitions: ${approvedExhibitions.length}');
      if (approvedExhibitions.isNotEmpty) {
        print('Sample approved exhibition: ${approvedExhibitions.first}');
      }

      // Check exhibitions with future dates
      final futureExhibitions = await _supabaseService.client
          .from('exhibitions')
          .select()
          .gte('start_date', DateTime.now().toIso8601String())
          .limit(10);
      print('Future exhibitions: ${futureExhibitions.length}');
      if (futureExhibitions.isNotEmpty) {
        print('Sample future exhibition: ${futureExhibitions.first}');
      }

      // Load recent exhibitions (simplified approach)
      var recentQuery = _supabaseService.client
          .from('exhibitions')
          .select();
      
      // Only filter by status if we have approved exhibitions
      if (approvedExhibitions.isNotEmpty) {
        recentQuery = recentQuery.eq('status', 'approved');
      }
      
      // Apply location filter if not "All Locations"
      if (_selectedLocation != 'All Locations') {
        recentQuery = recentQuery.eq('city', _selectedLocation);
      }
      
      final recentData = await recentQuery
          .order('start_date', ascending: true)
          .limit(10);

      List<Map<String, dynamic>> finalRecentData = List<Map<String, dynamic>>.from(recentData);
      print('Recent exhibitions found: ${finalRecentData.length}');

      // Load upcoming events (simplified approach)
      var upcomingQuery = _supabaseService.client
          .from('exhibitions')
          .select();
      
      // Only filter by status if we have approved exhibitions
      if (approvedExhibitions.isNotEmpty) {
        upcomingQuery = upcomingQuery.eq('status', 'approved');
      }
      
      // Apply location filter if not "All Locations"
      if (_selectedLocation != 'All Locations') {
        upcomingQuery = upcomingQuery.eq('city', _selectedLocation);
      }
      
      final upcomingData = await upcomingQuery
          .order('start_date', ascending: true)
          .limit(15);

      // Load nearby events if location is selected
      if (_selectedLocation != 'All Locations') {
        var nearbyQuery = _supabaseService.client
            .from('exhibitions')
            .select()
            .eq('city', _selectedLocation);
        
        // Only filter by status if we have approved exhibitions
        if (approvedExhibitions.isNotEmpty) {
          nearbyQuery = nearbyQuery.eq('status', 'approved');
        }
        
        final nearbyData = await nearbyQuery
            .order('start_date', ascending: true)
            .limit(5);
        
        _nearbyEvents = List<Map<String, dynamic>>.from(nearbyData);
      } else {
        _nearbyEvents = [];
      }

      // Load user's favorite and attending status for all exhibitions
      await _loadUserStatusForExhibitions(finalRecentData);
      
      // Create upcoming events list and load status
      List<Map<String, dynamic>> finalUpcomingData = List<Map<String, dynamic>>.from(upcomingData);
      await _loadUserStatusForExhibitions(finalUpcomingData);
      
      await _loadUserStatusForExhibitions(_nearbyEvents);

      setState(() {
        _recentExhibitions = finalRecentData;
        _upcomingEvents = finalUpcomingData;
        _isLoading = false;
      });

      // Debug print to check data
      print('Selected Location: $_selectedLocation');
      print('Recent Exhibitions: ${_recentExhibitions.length}');
      print('Upcoming Events: ${_upcomingEvents.length}');
      print('Nearby Events: ${_nearbyEvents.length}');
      
      // Debug: Print first exhibition data if available
      if (_recentExhibitions.isNotEmpty) {
        print('Sample Recent Exhibition Data: ${_recentExhibitions.first}');
      }
      
      // Debug: Print first upcoming event data if available
      if (_upcomingEvents.isNotEmpty) {
        print('Sample Upcoming Event Data: ${_upcomingEvents.first}');
        print('Upcoming Event Favorite Status: ${_upcomingEvents.first['is_favorited']}');
        print('Upcoming Event Attending Status: ${_upcomingEvents.first['is_attending']}');
      }
      
      print('=== END DEBUGGING ===');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _loadUserStatusForExhibitions(List<Map<String, dynamic>> exhibitions) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;

      print('Loading user status for ${exhibitions.length} exhibitions');

      for (int i = 0; i < exhibitions.length; i++) {
        final exhibition = exhibitions[i];
        final exhibitionId = exhibition['id'];

        // Check favorite status
        final isFavorited = await _supabaseService.isExhibitionFavorited(
          currentUser.id, 
          exhibitionId
        );

        // Check attending status
        final isAttending = await _supabaseService.isExhibitionAttending(
          currentUser.id, 
          exhibitionId
        );

        // Update the exhibition data with status
        exhibitions[i] = {
          ...exhibition,
          'is_favorited': isFavorited,
          'is_attending': isAttending,
        };
        
        print('Exhibition ${exhibition['title']}: Favorite=$isFavorited, Attending=$isAttending');
      }
    } catch (e) {
      print('Error loading user status for exhibitions: $e');
    }
  }

  Future<void> _toggleFavorite(String exhibitionId) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;

      await _supabaseService.toggleExhibitionFavorite(
        currentUser.id, 
        exhibitionId
      );

      // Reload data to update UI
      await _loadData();
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

  Future<void> _toggleAttending(String exhibitionId) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;

      await _supabaseService.toggleExhibitionAttending(
        currentUser.id, 
        exhibitionId
      );

      // Reload data to update UI
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating attendance: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _loadAvailableCities() async {
    try {
      print('=== DEBUGGING CITIES ===');
      
      // First check all cities regardless of status
      final allCitiesData = await _supabaseService.client
          .from('exhibitions')
          .select('city')
          .not('city', 'is', null);
      
      final allCities = allCitiesData
          .map((item) => item['city'] as String)
          .where((city) => city.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      
      print('All cities from DB: $allCities');
      
      // Load cities that have approved exhibitions
      final citiesData = await _supabaseService.client
          .from('exhibitions')
          .select('city')
          .eq('status', 'approved')
          .not('city', 'is', null);

      final cities = citiesData
          .map((item) => item['city'] as String)
          .where((city) => city.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      // Remove duplicates and ensure proper order
      final uniqueCities = ['All Locations', 'Gautam Buddha Nagar', ...cities].toSet().toList();
      
      setState(() {
        _availableCities = uniqueCities;
      });

      // Debug print to check cities
      print('Available Cities: $_availableCities');
      print('Approved Cities from DB: $cities');
      print('=== END CITIES DEBUG ===');
    } catch (e) {
      // If loading cities fails, use default list
      setState(() {
        _availableCities = ['All Locations', 'Gautam Buddha Nagar'].toSet().toList();
      });
      print('Error loading cities: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
                ),
              )
            : RefreshIndicator(
                onRefresh: _loadData,
                color: AppTheme.primaryMaroon,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      _buildHeader(),
                      const SizedBox(height: 24),
                      
                                                                    // Recent Exhibitions
                       if (_recentExhibitions.isNotEmpty) ...[
                         _buildSectionTitle('Recent Exhibitions'),
                         const SizedBox(height: 16),
                         SizedBox(
                           height: 280,
                           child: ListView.builder(
                             scrollDirection: Axis.horizontal,
                             itemCount: _recentExhibitions.length,
                             itemBuilder: (context, index) {
                               return Padding(
                                 padding: EdgeInsets.only(
                                   right: index < _recentExhibitions.length - 1 ? 16 : 0,
                                 ),
                                 child: FeaturedExhibitionCard(
                                   exhibition: _recentExhibitions[index],
                                   onTap: () => _navigateToExhibitionDetails(_recentExhibitions[index]),
                                   onFavoriteToggle: () => _toggleFavorite(_recentExhibitions[index]['id']),
                                   onAttendingToggle: () => _toggleAttending(_recentExhibitions[index]['id']),
                                 ),
                               );
                             },
                           ),
                         ),
                         const SizedBox(height: 32),
                       ],
                      
                                             // Location and Category Filters
                       Column(
                         children: [
                           DynamicLocationSelector(
                             selectedLocation: _selectedLocation,
                             availableCities: _availableCities,
                             onLocationChanged: (location) {
                               setState(() {
                                 _selectedLocation = location;
                               });
                               _loadData();
                             },
                             isLoading: _availableCities.length <= 1,
                           ),
                           const SizedBox(height: 16),
                           CategoryFilter(
                             selectedCategory: _selectedCategory,
                             onCategoryChanged: (category) {
                               setState(() {
                                 _selectedCategory = category;
                               });
                             },
                           ),
                         ],
                       ),
                       const SizedBox(height: 24),
                      
                                             // Nearby Events (if location is selected)
                       if (_selectedLocation != 'All Locations' && _nearbyEvents.isNotEmpty) ...[
                         _buildSectionTitle('Nearby Events in $_selectedLocation'),
                         const SizedBox(height: 16),
                         _buildNearbyEventsList(),
                         const SizedBox(height: 32),
                       ],
                       
                       // Upcoming Events
                       _buildSectionTitle('Upcoming Events'),
                       const SizedBox(height: 16),
                       _buildUpcomingEventsList(),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to Exhibae',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppTheme.primaryMaroon,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Discover amazing exhibitions and events',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textMediumGray,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () {
            // TODO: Navigate to notifications
          },
          icon: Stack(
            children: [
              Icon(
                Icons.notifications_outlined,
                color: AppTheme.primaryMaroon,
                size: 28,
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
        color: AppTheme.primaryMaroon,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildNearbyEventsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _nearbyEvents.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: UpcomingEventCard(
            exhibition: _nearbyEvents[index],
            onTap: () => _navigateToExhibitionDetails(_nearbyEvents[index]),
            onFavoriteToggle: () => _toggleFavorite(_nearbyEvents[index]['id']),
            onAttendingToggle: () => _toggleAttending(_nearbyEvents[index]['id']),
          ),
        );
      },
    );
  }

  Widget _buildUpcomingEventsList() {
    if (_upcomingEvents.isEmpty) {
      return Center(
        child: Column(
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: AppTheme.textMediumGray,
            ),
            const SizedBox(height: 16),
            Text(
              'No upcoming events',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textMediumGray,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _upcomingEvents.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: UpcomingEventCard(
            exhibition: _upcomingEvents[index],
            onTap: () => _navigateToExhibitionDetails(_upcomingEvents[index]),
            onFavoriteToggle: () => _toggleFavorite(_upcomingEvents[index]['id']),
            onAttendingToggle: () => _toggleAttending(_upcomingEvents[index]['id']),
          ),
        );
      },
    );
  }

  void _navigateToExhibitionDetails(Map<String, dynamic> exhibition) {
    Navigator.pushNamed(
      context,
      '/shopper-exhibition-details',
      arguments: {'exhibition': exhibition},
    );
  }
}
