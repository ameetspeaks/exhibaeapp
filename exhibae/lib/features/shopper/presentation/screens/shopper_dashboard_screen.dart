import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import 'shopper_home_screen.dart';
import 'shopper_explore_screen.dart';
import 'shopper_favorites_screen.dart';
import 'shopper_profile_screen.dart';

class ShopperDashboardScreen extends StatefulWidget {
  final int initialTab;
  
  const ShopperDashboardScreen({
    super.key,
    this.initialTab = 0,
  });

  @override
  State<ShopperDashboardScreen> createState() => _ShopperDashboardScreenState();
}

class _ShopperDashboardScreenState extends State<ShopperDashboardScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  late int _currentIndex;
  Map<String, dynamic>? _userProfile;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId != null) {
        final profile = await _supabaseService.getUserProfile(userId);
        setState(() {
          _userProfile = profile;
          _isLoadingProfile = false;
        });
      } else {
        setState(() {
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingProfile = false;
      });
    }
  }

  Widget _buildCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return const ShopperHomeScreen();
      case 1:
        return const ShopperExploreScreen();
      case 2:
        return const ShopperFavoritesScreen();
      case 3:
        return const ShopperProfileScreen();
      default:
        return const ShopperHomeScreen();
    }
  }

  List<BottomNavigationBarItem> _buildBottomNavItems() {
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
          selectedLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            fontFamily: AppTheme.fontFamily,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: AppTheme.fontFamily,
          ),
          items: _buildBottomNavItems(),
        ),
      ),
    );
  }
}
