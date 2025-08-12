import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  static DashboardService get instance => _instance;
  
  DashboardService._internal();

  final SupabaseService _supabaseService = SupabaseService.instance;

  // Get dashboard data for brands
  Future<Map<String, dynamic>> getBrandDashboardData(String userId) async {
    try {
      print('DashboardService: Starting to load brand dashboard data for user: $userId');
      
      // Initialize with empty data
      Map<String, dynamic> dashboardData = {
        'profile': null,
        'heroSliders': [],
        'activeApplications': [],
        'upcomingExhibitions': [],
        'recommendedExhibitions': [],
        'favoriteExhibitions': [],
        'brandLookbooks': [],
        'brandGallery': [],
        'stats': {
          'activeApplications': 0,
          'upcomingExhibitions': 0,
        }
      };
      
      // Get user profile
      try {
        print('DashboardService: Fetching user profile...');
        final profile = await _supabaseService.getUserProfile(userId);
        print('DashboardService: User profile loaded: ${profile != null ? 'success' : 'null'}');
        dashboardData['profile'] = profile;
      } catch (e) {
        print('DashboardService: Failed to load user profile: $e');
        // Continue without profile
      }
      
      // Get hero sliders
      try {
        print('DashboardService: Fetching hero sliders...');
        final heroSliders = await _supabaseService.getHeroSliders();
        print('DashboardService: Hero sliders loaded: ${heroSliders.length} items');
        dashboardData['heroSliders'] = heroSliders;
      } catch (e) {
        print('DashboardService: Failed to load hero sliders: $e');
        // Continue without hero sliders
      }
      
      // Get stall applications
      try {
        print('DashboardService: Fetching stall applications...');
        final applications = await _supabaseService.getStallApplications(brandId: userId);
        final activeApplications = applications.where((app) => app['status'] == 'pending' || app['status'] == 'approved').toList();
        print('DashboardService: Stall applications loaded: ${applications.length} total, ${activeApplications.length} active');
        dashboardData['activeApplications'] = activeApplications;
        dashboardData['stats']['activeApplications'] = activeApplications.length;
      } catch (e) {
        print('DashboardService: Failed to load stall applications: $e');
        // Continue without applications
      }
      
      // Get exhibitions
      try {
        print('DashboardService: Fetching exhibitions...');
        final exhibitions = await _supabaseService.getExhibitions();
        final upcomingExhibitions = exhibitions.where((exhibition) {
          final startDate = exhibition['start_date'];
          if (startDate == null) return false;
          final start = DateTime.tryParse(startDate);
          return start != null && start.isAfter(DateTime.now());
        }).toList();
        print('DashboardService: Exhibitions loaded: ${exhibitions.length} total, ${upcomingExhibitions.length} upcoming');
        dashboardData['upcomingExhibitions'] = upcomingExhibitions;
        dashboardData['stats']['upcomingExhibitions'] = upcomingExhibitions.length;
        
        // Get recommended exhibitions (for now, just take first few)
        final recommendedExhibitions = exhibitions.take(3).toList();
        print('DashboardService: Recommended exhibitions: ${recommendedExhibitions.length} items');
        dashboardData['recommendedExhibitions'] = recommendedExhibitions;
      } catch (e) {
        print('DashboardService: Failed to load exhibitions: $e');
        // Continue without exhibitions
      }
      
      // Get favorite exhibitions
      try {
        print('DashboardService: Fetching favorite exhibitions...');
        final favorites = await _supabaseService.getExhibitionFavorites(userId);
        print('DashboardService: Favorite exhibitions loaded: ${favorites.length} items');
        dashboardData['favoriteExhibitions'] = favorites;
      } catch (e) {
        print('DashboardService: Failed to load favorite exhibitions: $e');
        // Continue without favorites
      }

      // Get brand lookbooks
      try {
        print('DashboardService: Fetching brand lookbooks...');
        final lookbooks = await _supabaseService.getBrandLookbooks(userId);
        print('DashboardService: Brand lookbooks loaded: ${lookbooks.length} items');
        dashboardData['brandLookbooks'] = lookbooks;
      } catch (e) {
        print('DashboardService: Failed to load brand lookbooks: $e');
        // Continue without lookbooks
      }

      // Get brand gallery
      try {
        print('DashboardService: Fetching brand gallery...');
        final gallery = await _supabaseService.getBrandGallery(userId);
        print('DashboardService: Brand gallery loaded: ${gallery.length} items');
        dashboardData['brandGallery'] = gallery;
      } catch (e) {
        print('DashboardService: Failed to load brand gallery: $e');
        // Continue without gallery
      }
      
      print('DashboardService: Dashboard data successfully compiled');
      return dashboardData;
    } catch (e, stackTrace) {
      print('DashboardService: Critical error loading brand dashboard data: $e');
      print('DashboardService: Stack trace: $stackTrace');
      
      // Return minimal data structure even on critical failure
      return {
        'profile': null,
        'heroSliders': [],
        'activeApplications': [],
        'upcomingExhibitions': [],
        'recommendedExhibitions': [],
        'favoriteExhibitions': [],
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
      
      // Get organizer's exhibitions
      final exhibitions = await _supabaseService.getExhibitions();
      final organizerExhibitions = exhibitions.where((exhibition) => 
        exhibition['organiser']?['id'] == userId
      ).toList();
      
      // Get pending applications for organizer's exhibitions
      final allApplications = await _supabaseService.getStallApplications();
      final pendingApplications = allApplications.where((app) {
        final exhibition = app['exhibition'];
        return exhibition != null && 
               organizerExhibitions.any((ex) => ex['id'] == exhibition['id']) &&
               app['status'] == 'pending';
      }).toList();
      
      return {
        'profile': profile,
        'organizerExhibitions': organizerExhibitions,
        'pendingApplications': pendingApplications,
        'stats': {
          'activeExhibitions': organizerExhibitions.where((ex) => 
            ex['status'] == 'published' || ex['status'] == 'live'
          ).length,
          'totalApplications': allApplications.where((app) {
            final exhibition = app['exhibition'];
            return exhibition != null && 
                   organizerExhibitions.any((ex) => ex['id'] == exhibition['id']);
          }).length,
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
