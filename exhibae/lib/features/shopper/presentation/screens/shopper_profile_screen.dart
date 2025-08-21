import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/profile_picture_display.dart';
import '../../../../core/routes/app_router.dart';
import '../widgets/dynamic_location_selector.dart';

class ShopperProfileScreen extends StatefulWidget {
  const ShopperProfileScreen({super.key});

  @override
  State<ShopperProfileScreen> createState() => _ShopperProfileScreenState();
}

class _ShopperProfileScreenState extends State<ShopperProfileScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  String _preferredLocation = 'Gautam Buddha Nagar';
  List<String> _availableCities = ['All Locations', 'Gautam Buddha Nagar'];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadAvailableCities();
  }

  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userId = _supabaseService.currentUser?.id;
      if (userId != null) {
        final profile = await _supabaseService.getUserProfile(userId);
        setState(() {
          _userProfile = profile;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await _supabaseService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/auth',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
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
                onRefresh: _loadUserProfile,
                color: AppTheme.primaryMaroon,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),
                      _buildProfileSection(),
                      const SizedBox(height: 24),
                      _buildSettingsSection(),
                      const SizedBox(height: 24),
                      _buildSupportSection(),
                      const SizedBox(height: 24),
                      _buildSignOutSection(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.white,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Profile',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.primaryMaroon,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.shopperEditProfile).then((result) async {
                if (result == true) {
                  await _loadUserProfile();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully'),
                        backgroundColor: AppTheme.primaryMaroon,
                      ),
                    );
                  }
                }
              });
            },
            icon: Icon(
              Icons.edit,
              color: AppTheme.primaryMaroon,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLightGray),
      ),
      child: Column(
        children: [
          // Profile Picture
          ProfilePictureDisplay(
            avatarUrl: _userProfile?['avatar_url'],
            size: 100,
            backgroundColor: AppTheme.secondaryWarm,
            iconColor: AppTheme.primaryMaroon,
          ),
          const SizedBox(height: 16),
          
          // User Name
          Text(
            _userProfile?['full_name'] ?? 'User Name',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.primaryMaroon,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          
          // Email
          Text(
            _userProfile?['email'] ?? 'user@example.com',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textMediumGray,
            ),
          ),
          const SizedBox(height: 16),
          
          // Role Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accentGold,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Shopper',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLightGray),
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Manage your notification preferences',
            onTap: () {
              Navigator.pushNamed(context, '/notification-settings');
            },
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy',
            subtitle: 'Control your privacy settings',
            onTap: () {
              Navigator.pushNamed(context, '/privacy-settings');
            },
          ),
          _buildDivider(),
                     _buildSettingsItem(
             icon: Icons.language_outlined,
             title: 'Language',
             subtitle: 'Change app language',
             onTap: () {
               // TODO: Implement language settings
             },
           ),
           _buildDivider(),
           _buildSettingsItem(
             icon: Icons.location_on_outlined,
             title: 'Preferred Location',
             subtitle: _preferredLocation,
             onTap: () {
               _showLocationDialog();
             },
           ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.dark_mode_outlined,
            title: 'Dark Mode',
            subtitle: 'Toggle dark/light theme',
            trailing: Switch(
              value: false, // TODO: Implement theme toggle
              onChanged: (value) {
                // TODO: Implement theme toggle
              },
              activeColor: AppTheme.primaryMaroon,
            ),
            onTap: null,
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLightGray),
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            icon: Icons.help_outline,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {
              Navigator.pushNamed(context, '/support');
            },
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.info_outline,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () {
              _showAboutDialog();
            },
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.description_outlined,
            title: 'Terms of Service',
            subtitle: 'Read our terms and conditions',
            onTap: () {
              // TODO: Navigate to terms of service
            },
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: Icons.security_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our privacy policy',
            onTap: () {
              // TODO: Navigate to privacy policy
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSignOutSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton(
        onPressed: _showSignOutDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.errorRed,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppTheme.primaryMaroon,
        size: 24,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: AppTheme.primaryMaroon,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.textMediumGray,
        ),
      ),
      trailing: trailing ?? Icon(
        Icons.chevron_right,
        color: AppTheme.textMediumGray,
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      color: AppTheme.borderLightGray,
      indent: 56,
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

     void _showLocationDialog() {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Set Preferred Location'),
                   content: SizedBox(
            width: double.maxFinite,
            child: DynamicLocationSelector(
              selectedLocation: _preferredLocation,
              availableCities: _availableCities,
              onLocationChanged: (location) {
                setState(() {
                  _preferredLocation = location;
                });
              },
              isLoading: _availableCities.length <= 1,
            ),
          ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: const Text('Cancel'),
           ),
           ElevatedButton(
             onPressed: () {
               Navigator.pop(context);
               // TODO: Save preferred location to user profile
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                   content: Text('Preferred location set to $_preferredLocation'),
                   backgroundColor: AppTheme.successGreen,
                 ),
               );
             },
             style: ElevatedButton.styleFrom(
               backgroundColor: AppTheme.primaryMaroon,
               foregroundColor: Colors.white,
             ),
             child: const Text('Save'),
           ),
         ],
       ),
     );
   }

   void _showAboutDialog() {
     showDialog(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('About Exhibae'),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text('Version: 1.0.0'),
             const SizedBox(height: 8),
             Text('Build: 1'),
             const SizedBox(height: 16),
             Text(
               'Exhibae is your premier platform for discovering and attending amazing exhibitions and events.',
               style: Theme.of(context).textTheme.bodyMedium,
             ),
           ],
         ),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context),
             child: const Text('Close'),
           ),
         ],
       ),
     );
   }

  Future<void> _loadAvailableCities() async {
    try {
      // Load cities that have exhibitions from exhibitions table
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

      setState(() {
        _availableCities = ['All Locations', 'Gautam Buddha Nagar', ...cities];
      });
    } catch (e) {
      // If loading cities fails, use default list
      setState(() {
        _availableCities = ['All Locations', 'Gautam Buddha Nagar'];
      });
    }
  }
}
