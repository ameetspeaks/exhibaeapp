import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';

class BrandProfileScreen extends StatefulWidget {
  const BrandProfileScreen({super.key});

  @override
  State<BrandProfileScreen> createState() => _BrandProfileScreenState();
}

class _BrandProfileScreenState extends State<BrandProfileScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _profile = {};
  final SupabaseService _supabaseService = SupabaseService.instance;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser != null) {
        final profile = await _supabaseService.getUserProfile(currentUser.id);
        if (profile != null) {
          setState(() {
            _profile = profile;
            _isLoading = false;
          });
        } else {
          // Create a default profile if none exists
          await _createDefaultProfile(currentUser.id);
        }
      } else {
        setState(() {
          _profile = {};
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

  Future<void> _createDefaultProfile(String userId) async {
    try {
      final defaultProfile = {
        'id': userId,
        'company_name': 'TechCorp Solutions',
        'contact_person': 'John Doe',
        'email': _supabaseService.currentUser?.email ?? '',
        'phone': '+91 98765 43210',
        'website': 'www.techcorp.com',
        'address': '123 Tech Park, Sector 15, Gurgaon, Haryana 122001',
        'industry': 'Technology',
        'company_size': '50-200 employees',
        'founded_year': '2018',
        'description': 'Leading technology solutions provider specializing in AI, IoT, and digital transformation services.',
        'verified': true,
        'rating': 4.8,
        'reviews': 125,
        'applications_submitted': 15,
        'applications_approved': 8,
        'total_exhibitions': 12,
      };

      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) throw Exception('User not found');
      
      final profile = await _supabaseService.createUserProfile(
        userId: currentUser.id,
        email: currentUser.email ?? '',
        role: 'brand',
        companyName: defaultProfile['company_name']?.toString(),
        phone: defaultProfile['phone']?.toString(),
        description: defaultProfile['description']?.toString(),
        websiteUrl: defaultProfile['website_url']?.toString(),
      );
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating profile: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.person,
                color: AppTheme.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppTheme.white),
            onPressed: () async {
              final result = await Navigator.of(context).pushNamed('/edit-profile');
              if (result == true) {
                // Profile was updated, reload the profile data
                _loadProfile();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile Header
                  _buildProfileHeader(),
                  const SizedBox(height: 24),

                  // Stats Cards
                  _buildStatsCards(),
                  const SizedBox(height: 24),

                  // Profile Information
                  _buildProfileInformation(),
                  const SizedBox(height: 24),

                  // Settings
                  _buildSettings(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 20,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.textMediumGray.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 16,
                width: 150,
                decoration: BoxDecoration(
                  color: AppTheme.textMediumGray.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Profile Picture
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: AppTheme.white.withOpacity(0.1),
                child: _profile['logo_url'] != null
                    ? ClipOval(
                        child: Image.network(
                          _profile['logo_url'],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.business,
                              size: 50,
                              color: AppTheme.white,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.business,
                        size: 50,
                        color: AppTheme.white,
                      ),
              ),
              if (_profile['verified'] == true)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: AppTheme.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Company Name
          Text(
            _profile['company_name'] ?? 'Company Name',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Industry
          Text(
            _profile['industry'] ?? 'Industry',
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.white,
            ),
          ),
          const SizedBox(height: 16),

          // Rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.star,
                color: AppTheme.secondaryGold,
                size: 20,
              ),
              const SizedBox(width: 4),
              Text(
                '${_profile['rating'] ?? 0}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.white,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${_profile['reviews'] ?? 0} reviews)',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Applications',
            value: '${_profile['applications_submitted'] ?? 0}',
            icon: Icons.assignment,
            color: AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Approved',
            value: '${_profile['applications_approved'] ?? 0}',
            icon: Icons.check_circle,
            color: AppTheme.successGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: 'Exhibitions',
            value: '${_profile['total_exhibitions'] ?? 0}',
            icon: Icons.event,
            color: AppTheme.secondaryGold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.white.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProfileInformation() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Company Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
            ),
          ),
          const SizedBox(height: 16),

          _buildInfoItem(
            icon: Icons.person,
            title: 'Contact Person',
            value: _profile['full_name'] ?? 'Not specified',
          ),
          const SizedBox(height: 12),

          _buildInfoItem(
            icon: Icons.email,
            title: 'Email',
            value: _profile['email'] ?? 'Not specified',
          ),
          const SizedBox(height: 12),

          _buildInfoItem(
            icon: Icons.phone,
            title: 'Phone',
            value: _profile['phone'] ?? 'Not specified',
          ),
          const SizedBox(height: 12),

          _buildInfoItem(
            icon: Icons.language,
            title: 'Website',
            value: _profile['website'] ?? 'Not specified',
          ),
          const SizedBox(height: 12),

          _buildInfoItem(
            icon: Icons.location_on,
            title: 'Address',
            value: _profile['address'] ?? 'Not specified',
          ),
          const SizedBox(height: 12),

          _buildInfoItem(
            icon: Icons.business,
            title: 'Company Size',
            value: _profile['company_size'] ?? 'Not specified',
          ),
          const SizedBox(height: 12),

          _buildInfoItem(
            icon: Icons.calendar_today,
            title: 'Founded Year',
            value: _profile['founded_year'] ?? 'Not specified',
          ),
          const SizedBox(height: 16),

          const Text(
            'About',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDarkCharcoal,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _profile['description'] ?? 'No description available',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.white.withOpacity(0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.primaryBlue,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textMediumGray,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textDarkCharcoal,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
            ),
          ),
          const SizedBox(height: 16),

          _buildSettingItem(
            icon: Icons.notifications,
            title: 'Notifications',
            subtitle: 'Manage notification preferences',
            onTap: () {
              // TODO: Navigate to notifications settings
            },
          ),
          const Divider(),
          _buildSettingItem(
            icon: Icons.security,
            title: 'Privacy & Security',
            subtitle: 'Manage privacy settings',
            onTap: () {
              // TODO: Navigate to privacy settings
            },
          ),
          const Divider(),
          _buildSettingItem(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {
              // TODO: Navigate to help and support
            },
          ),
          const Divider(),
          _buildSettingItem(
            icon: Icons.info,
            title: 'About',
            subtitle: 'App version and information',
            onTap: () {
              // TODO: Navigate to about page
            },
          ),
          const Divider(),
          _buildSettingItem(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            onTap: () async {
              try {
                await _supabaseService.signOut();
                if (mounted) {
                  Navigator.of(context).pushReplacementNamed('/auth');
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
            },
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppTheme.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppTheme.errorRed : AppTheme.white,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? AppTheme.errorRed : AppTheme.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.white.withOpacity(0.8),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppTheme.white.withOpacity(0.7),
      ),
      onTap: onTap,
    );
  }
}
