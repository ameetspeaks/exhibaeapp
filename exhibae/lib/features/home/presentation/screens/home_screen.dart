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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  int _currentIndex = 0;

  Future<String> _getUserRole() async {
    // First try to get role from metadata
    final metadataRole = _supabaseService.currentUser?.userMetadata?['role'] as String?;
    print('Metadata role: $metadataRole');
    
    if (metadataRole != null) {
      print('Using metadata role: $metadataRole');
      return metadataRole;
    }

    // If metadata role is not available, fetch from profiles table
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId != null) {
        final profile = await _supabaseService.getUserProfile(userId);
        final profileRole = profile?['role'] as String? ?? 'brand';
        print('Profile role: $profileRole');
        return profileRole;
      }
    } catch (e) {
      print('Error fetching user role: $e');
    }

    print('Using default role: brand');
    return 'brand'; // Default fallback
  }

  Widget _buildCurrentScreen() {
    return FutureBuilder<String>(
      future: _getUserRole(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
            ),
          );
        }

        final userRole = snapshot.data ?? 'brand';
        
        switch (_currentIndex) {
          case 0:
            return userRole == 'organizer' ? const OrganizerDashboard() : const BrandDashboard();
          case 1:
            return _buildExploreScreen();
          case 2:
            return _buildStallsScreen();
          case 3:
            return _buildProfileScreen();
          default:
            return userRole == 'organizer' ? const OrganizerDashboard() : const BrandDashboard();
        }
      },
    );
  }

  Widget _buildExploreScreen() {
    return FutureBuilder<String>(
      future: _getUserRole(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
            ),
          );
        }

        final userRole = snapshot.data ?? 'brand';
        return userRole == 'organizer' ? const OrganizerExhibitionsScreen() : const BrandExhibitionsScreen();
      },
    );
  }

  Widget _buildStallsScreen() {
    return const BrandStallsScreen();
  }

  Widget _buildProfileScreen() {
    return FutureBuilder<String>(
      future: _getUserRole(),
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
            ),
          );
        }

        final userRole = snapshot.data ?? 'brand';
        return userRole == 'organizer' ? const OrganizerProfileScreen() : const BrandProfileScreen();
      },
    );
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
          items: const [
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
          ],
        ),
      ),
    );
  }
}