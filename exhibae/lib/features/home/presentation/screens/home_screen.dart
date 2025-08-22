import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../widgets/brand_dashboard.dart';
import '../widgets/organizer_dashboard.dart';
import '../../../brand/presentation/screens/brand_exhibitions_screen.dart';
import '../../../brand/presentation/screens/brand_stalls_screen.dart';
import '../../../brand/presentation/screens/brand_profile_screen.dart';
import '../../../organizer/presentation/screens/organizer_exhibitions_screen.dart';
import '../../../organizer/presentation/screens/organizer_profile_screen.dart';
import '../../../organizer/presentation/screens/application_list_screen.dart';
import '../../../shopper/presentation/screens/shopper_home_screen.dart';
import '../../../shopper/presentation/screens/shopper_explore_screen.dart';
import '../../../shopper/presentation/screens/shopper_favorites_screen.dart';
import '../../../shopper/presentation/screens/shopper_profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final int initialTab;
  
  const HomeScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  late int _currentIndex;
  String? _cachedUserRole;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    // Set initial tab - will be overridden by _loadUserRole() based on actual user role
    _currentIndex = widget.initialTab;
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      // Debug authentication state
      _supabaseService.debugAuthState();
      
      // First try to get role from metadata
      final metadataRole = _supabaseService.currentUser?.userMetadata?['role'] as String?;
      
      if (metadataRole != null) {
        // Normalize the role to handle both spellings
        final normalizedRole = _normalizeRole(metadataRole);
        setState(() {
          _cachedUserRole = normalizedRole;
          _isLoadingRole = false;
        });
        // Set default tab based on role
        _setDefaultTabForRole(normalizedRole);
        return;
      }

      // If metadata role is not available, fetch from profiles table
      final userId = _supabaseService.currentUser?.id;
      if (userId != null) {
        final profile = await _supabaseService.getUserProfile(userId);
        final profileRole = profile?['role'] as String? ?? 'brand';
        
        setState(() {
          _cachedUserRole = profileRole;
          _isLoadingRole = false;
        });
        // Set default tab based on role
        _setDefaultTabForRole(profileRole);
        return;
      }
    } catch (e) {
      // Handle error appropriately
    }

    // Default fallback
    setState(() {
      _cachedUserRole = 'brand';
      _isLoadingRole = false;
    });
    // Set default tab for brand users
    _setDefaultTabForRole('brand');
  }

  String _normalizeRole(String role) {
    // Normalize role to handle both spellings
    if (role == 'organizer' || role == 'organiser') {
      return 'organiser'; // Use the database enum value
    }
    return role;
  }

  void _setDefaultTabForRole(String role) {
    // Set default tab based on user role
    print('Setting default tab for role: $role'); // Debug print
    setState(() {
      if (role == 'organizer' || role == 'organiser') {
        _currentIndex = 0; // Dashboard for organizers
      } else if (role == 'shopper') {
        _currentIndex = 0; // Home for shoppers
      } else {
        _currentIndex = 1; // Explore for brands
      }
    });
    print('Current index set to: $_currentIndex'); // Debug print
  }

  String get _userRole {
    final role = _cachedUserRole ?? 'brand';
    // Normalize role to handle both spellings
    if (role == 'organizer' || role == 'organiser') {
      return 'organiser'; // Use the database enum value
    }
    return role;
  }

  Widget _buildCurrentScreen() {
    if (_isLoadingRole) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
        ),
      );
    }

    print('Building screen for role: $_userRole, index: $_currentIndex'); // Debug print

    switch (_currentIndex) {
      case 0:
        if (_userRole == 'organizer' || _userRole == 'organiser') {
          return const OrganizerDashboard();
        } else if (_userRole == 'shopper') {
          return const ShopperHomeScreen();
        } else {
          return const BrandDashboard();
        }
      case 1:
        return _buildExploreScreen();
      case 2:
        return _buildThirdTab();
      case 3:
        return _buildProfileScreen();
      default:
        if (_userRole == 'organizer' || _userRole == 'organiser') {
          return const OrganizerDashboard();
        } else if (_userRole == 'shopper') {
          return const ShopperHomeScreen();
        } else {
          return const BrandDashboard();
        }
    }
  }

  Widget _buildExploreScreen() {
    if (_isLoadingRole) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
        ),
      );
    }
    
    if (_userRole == 'organizer' || _userRole == 'organiser') {
      return const OrganizerExhibitionsScreen();
    } else if (_userRole == 'shopper') {
      return const ShopperExploreScreen();
    } else {
      return const BrandExhibitionsScreen();
    }
  }

  Widget _buildThirdTab() {
    if (_isLoadingRole) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
        ),
      );
    }
    
    if (_userRole == 'organizer' || _userRole == 'organiser') {
      return const ApplicationListScreen();
    } else if (_userRole == 'shopper') {
      return const ShopperFavoritesScreen();
    } else {
      return const BrandStallsScreen();
    }
  }

  Widget _buildProfileScreen() {
    if (_isLoadingRole) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
        ),
      );
    }
    
    if (_userRole == 'organizer' || _userRole == 'organiser') {
      return const OrganizerProfileScreen();
    } else if (_userRole == 'shopper') {
      return const ShopperProfileScreen();
    } else {
      return const BrandProfileScreen();
    }
  }

  List<BottomNavigationBarItem> _buildBottomNavItems() {
    if (_userRole == 'organizer' || _userRole == 'organiser') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: 'My Exhibitions',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Applications',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else if (_userRole == 'shopper') {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore_outlined),
          activeIcon: Icon(Icons.explore),
          label: 'Explore',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite_outline),
          activeIcon: Icon(Icons.favorite),
          label: 'Favorites',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else {
      return const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.explore),
          label: 'Explore',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.store),
          label: 'My Stalls',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppTheme.backgroundPeach,
        child: SafeArea(
          child: _buildCurrentScreen(),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          border: Border(
            top: BorderSide(
              color: AppTheme.borderLightGray,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppTheme.white,
          selectedItemColor: AppTheme.primaryMaroon,
          unselectedItemColor: AppTheme.primaryMaroon.withOpacity(0.6),
          elevation: 0,
          items: _buildBottomNavItems(),
        ),
      ),
    );
  }
}