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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  int _currentIndex = 0;
  String? _cachedUserRole;
  bool _isLoadingRole = true;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      // First try to get role from metadata
      final metadataRole = _supabaseService.currentUser?.userMetadata?['role'] as String?;
      
      if (metadataRole != null) {
        setState(() {
          _cachedUserRole = metadataRole;
          _isLoadingRole = false;
        });
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
        return;
      }
    } catch (e) {
      print('Error fetching user role: $e');
    }

    // Default fallback
    setState(() {
      _cachedUserRole = 'brand';
      _isLoadingRole = false;
    });
  }

  String get _userRole => _cachedUserRole ?? 'brand';

  Widget _buildCurrentScreen() {
    if (_isLoadingRole) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
        ),
      );
    }

    switch (_currentIndex) {
      case 0:
        return _userRole == 'organizer' ? const OrganizerDashboard() : const BrandDashboard();
      case 1:
        return _buildExploreScreen();
      case 2:
        return _buildThirdTab();
      case 3:
        return _buildProfileScreen();
      default:
        return _userRole == 'organizer' ? const OrganizerDashboard() : const BrandDashboard();
    }
  }

  Widget _buildExploreScreen() {
    if (_isLoadingRole) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
        ),
      );
    }
    
    return _userRole == 'organizer' ? const OrganizerExhibitionsScreen() : const BrandExhibitionsScreen();
  }

  Widget _buildThirdTab() {
    if (_isLoadingRole) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
        ),
      );
    }
    
    return _userRole == 'organizer' ? const ApplicationListScreen() : const BrandStallsScreen();
  }

  Widget _buildProfileScreen() {
    if (_isLoadingRole) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
        ),
      );
    }
    
    return _userRole == 'organizer' ? const OrganizerProfileScreen() : const BrandProfileScreen();
  }

  List<BottomNavigationBarItem> _buildBottomNavItems() {
    if (_userRole == 'organizer') {
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
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.gradientBlack,
              AppTheme.gradientPink,
            ],
          ),
        ),
        child: SafeArea(
          child: _buildCurrentScreen(),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.white,
          border: Border(
            top: BorderSide(
              color: AppTheme.gradientBlack.withOpacity(0.1),
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
          selectedItemColor: AppTheme.gradientBlack,
          unselectedItemColor: AppTheme.gradientBlack.withOpacity(0.6),
          elevation: 0,
          items: _buildBottomNavItems(),
        ),
      ),
    );
  }
}