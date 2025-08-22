import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  static DashboardService get instance => _instance;
  
  DashboardService._internal();

  final SupabaseService _supabaseService = SupabaseService.instance;

  // Helper to format date
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Get dashboard data for brands
  Future<Map<String, dynamic>> getBrandDashboardData(String userId) async {
    try {
      // Initialize with empty data
      Map<String, dynamic> dashboardData = {
        'profile': null,
        'heroSliders': [],
        'activeApplications': [],
        'upcomingExhibitions': [],
        'recommendedExhibitions': [],
        'cities': [],
        'selectedCity': 'Delhi',
        'exhibitionsByCity': [],
        'brandLookbooks': [],
        'brandGallery': [],
        'stats': {
          'activeApplications': 0,
          'upcomingExhibitions': 0,
        }
      };
      
      // Get user profile
      try {
        final profile = await _supabaseService.getUserProfile(userId);
        dashboardData['profile'] = profile;
      } catch (e) {
        // Continue without profile
      }
      
      // Get hero sliders
      try {
        final heroSliders = await _supabaseService.getHeroSliders();
        dashboardData['heroSliders'] = heroSliders;
      } catch (e) {
        // Continue without hero sliders
      }
      
      // Get stall applications
      try {
        final applications = await _supabaseService.getStallApplications(brandId: userId);
        final activeApplications = applications.where((app) => app['status'] == 'pending' || app['status'] == 'approved').toList();
        dashboardData['activeApplications'] = activeApplications;
        dashboardData['stats']['activeApplications'] = activeApplications.length;
      } catch (e) {
        // Continue without applications
      }
      
      // Get exhibitions
      try {
        final exhibitions = await _supabaseService.getExhibitions();
        
        // Process exhibitions to add favorite status and stall availability
        final processedExhibitions = await Future.wait(exhibitions.map((exhibition) async {
          // Check if this exhibition is favorited by the current user
          bool isFavorite = false;
          try {
            isFavorite = await _supabaseService.isExhibitionFavorited(userId, exhibition['id']);
          } catch (e) {
            // Continue without favorite status
          }
          
          // Fetch actual stall count for this exhibition
          int availableStalls = 0;
          try {
            // Query stall_instances directly for available instances
            availableStalls = await _supabaseService.getAvailableStallInstancesCount(exhibition['id']);
          } catch (e) {
            print('Error fetching stall instances for exhibition ${exhibition['id']}: $e');
          }
          
          // Format date
          final startDate = exhibition['start_date'] != null 
            ? DateTime.parse(exhibition['start_date'])
            : DateTime.now();
          final endDate = exhibition['end_date'] != null 
            ? DateTime.parse(exhibition['end_date'])
            : DateTime.now();
          final formattedDate = '${_formatDate(startDate)} - ${_formatDate(endDate)}';
          
          // Get image URL
          final images = List<String>.from(exhibition['images'] ?? []);
          final imageUrl = images.isNotEmpty 
            ? _supabaseService.getPublicUrl('exhibition-images', images.first)
            : null;
          
          return {
            ...exhibition,
            'isFavorite': isFavorite,
            'availableStalls': availableStalls,
            'date': formattedDate,
            'image_url': imageUrl,
            'priceRange': exhibition['price_range'] ?? null,
            'location': exhibition['city'] ?? 'Location not specified',
          };
        }).toList());
        
        final upcomingExhibitions = processedExhibitions.where((exhibition) {
          final startDate = exhibition['start_date'];
          if (startDate == null) return false;
          final start = DateTime.tryParse(startDate);
          return start != null && start.isAfter(DateTime.now());
        }).toList();
        dashboardData['upcomingExhibitions'] = upcomingExhibitions;
        dashboardData['stats']['upcomingExhibitions'] = upcomingExhibitions.length;
        
        // Get recommended exhibitions (for now, just take first few)
        final recommendedExhibitions = processedExhibitions.take(3).toList();
        dashboardData['recommendedExhibitions'] = recommendedExhibitions;
        
        // Store all processed exhibitions for city filtering
        dashboardData['allExhibitions'] = processedExhibitions;
      } catch (e) {
        // Continue without exhibitions
      }
      
      // Get cities and exhibitions by city
      try {
        final allExhibitions = dashboardData['allExhibitions'] as List<dynamic>? ?? [];
        
        // Extract unique cities from exhibitions
        final cities = <String>{};
        for (final exhibition in allExhibitions) {
          if (exhibition['city'] != null && exhibition['city'].toString().isNotEmpty) {
            cities.add(exhibition['city'].toString());
          }
        }
        
        // Sort cities alphabetically
        final sortedCities = cities.toList()..sort();
        dashboardData['cities'] = sortedCities;
        
        // Set default city to Delhi if available, otherwise first city
        String selectedCity = 'Delhi';
        if (sortedCities.contains('Delhi')) {
          selectedCity = 'Delhi';
        } else if (sortedCities.isNotEmpty) {
          selectedCity = sortedCities.first;
        }
        dashboardData['selectedCity'] = selectedCity;
        
        // Get exhibitions for the selected city
        if (selectedCity.isNotEmpty) {
          final cityExhibitions = allExhibitions.where((exhibition) => 
            exhibition['city']?.toString() == selectedCity
          ).toList();
          dashboardData['exhibitionsByCity'] = cityExhibitions;
        }
      } catch (e) {
        // Continue without city data
      }
      
      // Get brand lookbooks
      try {
        final lookbooks = await _supabaseService.getBrandLookbooks(userId);
        dashboardData['brandLookbooks'] = lookbooks;
      } catch (e) {
        // Continue without lookbooks
      }

      // Get brand gallery
      try {
        final gallery = await _supabaseService.getBrandGallery(userId);
        dashboardData['brandGallery'] = gallery;
      } catch (e) {
        // Continue without gallery
      }
      return dashboardData;
    } catch (e, stackTrace) {
      // Return minimal data structure even on critical failure
      return {
        'profile': null,
        'heroSliders': [],
        'activeApplications': [],
        'upcomingExhibitions': [],
        'recommendedExhibitions': [],
        'cities': ['Delhi'], // Default fallback
        'selectedCity': 'Delhi',
        'exhibitionsByCity': [],
        'brandLookbooks': [],
        'brandGallery': [],
        'stats': {
          'activeApplications': 0,
          'upcomingExhibitions': 0,
        }
      };
    }
  }

  // Get dashboard data for shoppers
  Future<Map<String, dynamic>> getShopperDashboardData(String userId) async {
    try {
      // Get user profile
      final profile = await _supabaseService.getUserProfile(userId);
      
      // Get upcoming exhibitions
      final exhibitions = await _supabaseService.getExhibitions();
      final upcomingExhibitions = exhibitions.take(5).toList();
      
      // Get trending categories
      final categories = await _supabaseService.getExhibitionCategories();
      
      // Get recently viewed brands (placeholder - would need to implement tracking)
      final recentlyViewedBrands = <Map<String, dynamic>>[];
      
      // Get user's RSVPs (placeholder - would need to implement RSVP system)
      final userRSVPs = <Map<String, dynamic>>[];
      
      return {
        'profile': profile,
        'upcomingExhibitions': upcomingExhibitions,
        'trendingCategories': categories,
        'recentlyViewedBrands': recentlyViewedBrands,
        'userRSVPs': userRSVPs,
      };
    } catch (e) {
      throw Exception('Failed to load shopper dashboard data: $e');
    }
  }

  // Get dashboard data for organizers
  Future<Map<String, dynamic>> getOrganizerDashboardData(String userId) async {
    try {
      // Get user profile
      final profile = await _supabaseService.getUserProfile(userId);
      
      // Get organizer's exhibitions (all exhibitions created by this organizer)
      final organizerExhibitions = await _supabaseService.getOrganizerExhibitions(userId);
      
      // Get all applications for organizer's exhibitions
      final allApplications = await _supabaseService.getStallApplications();
      final organizerApplications = allApplications.where((app) {
        final exhibition = app['exhibition'];
        return exhibition != null && 
               organizerExhibitions.any((ex) => ex['id'] == exhibition['id']);
      }).toList();
      
      // Get pending applications
      final pendingApplications = organizerApplications.where((app) => 
        app['status'] == 'pending'
      ).toList();
      
      return {
        'profile': profile,
        'organizerExhibitions': organizerExhibitions,
        'pendingApplications': pendingApplications,
        'stats': {
          'activeExhibitions': organizerExhibitions.where((ex) => 
            ex['status'] == 'published' || ex['status'] == 'live'
          ).length,
          'totalApplications': organizerApplications.length,
        }
      };
    } catch (e) {
      throw Exception('Failed to load organizer dashboard data: $e');
    }
  }

  // Get real-time updates for dashboard
  Stream<Map<String, dynamic>> subscribeToDashboardUpdates(String userId, String userRole) {
    switch (userRole) {
      case 'brand':
        return _supabaseService.subscribeToStallApplications(brandId: userId)
            .map((applications) => {
              'activeApplications': applications.where((app) => 
                app['status'] == 'pending' || app['status'] == 'approved'
              ).toList(),
              'stats': {
                'activeApplications': applications.where((app) => 
                  app['status'] == 'pending' || app['status'] == 'approved'
                ).length,
              }
            });
      case 'organizer':
        return _supabaseService.subscribeToStallApplications()
            .map((applications) => {
              'pendingApplications': applications.where((app) => 
                app['status'] == 'pending'
              ).toList(),
            });
      default:
        return Stream.value({});
    }
  }
}
