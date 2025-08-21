import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/profile_picture_display.dart';

class BrandProfileScreen extends StatefulWidget {
  const BrandProfileScreen({super.key});

  @override
  State<BrandProfileScreen> createState() => _BrandProfileScreenState();
}

class _BrandProfileScreenState extends State<BrandProfileScreen> {
  bool _isLoading = false;
  Map<String, dynamic> _profile = {};
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  // Followers data
  List<Map<String, dynamic>> _followers = [];
  int _followersCount = 0;
  bool _isLoadingFollowers = false;
  bool _hasMoreFollowers = true;
  int _currentPage = 0;

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
          // Load followers after profile is loaded
          _loadFollowers(currentUser.id);
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

  Future<void> _loadFollowers(String brandId) async {
    try {
      setState(() {
        _isLoadingFollowers = true;
      });

      // Get followers count
      final count = await _supabaseService.getBrandFollowersCount(brandId);
      
      // Get first page of followers
      final followersData = await _supabaseService.getBrandFollowers(brandId, page: 0, limit: 10);
      
      setState(() {
        _followersCount = count;
        // Fix type casting issue by properly converting List<dynamic> to List<Map<String, dynamic>>
        final followersList = followersData['followers'] as List<dynamic>? ?? [];
        _followers = followersList.map((follower) => Map<String, dynamic>.from(follower)).toList();
        _hasMoreFollowers = followersData['has_more'] ?? false;
        _currentPage = 0;
        _isLoadingFollowers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFollowers = false;
      });
      print('Error loading followers: $e');
    }
  }

  Future<void> _loadMoreFollowers() async {
    if (_isLoadingFollowers || !_hasMoreFollowers) return;

    try {
      setState(() {
        _isLoadingFollowers = true;
      });

      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;

      final nextPage = _currentPage + 1;
      final followersData = await _supabaseService.getBrandFollowers(
        currentUser.id, 
        page: nextPage, 
        limit: 10
      );

      setState(() {
        // Fix type casting issue by properly converting List<dynamic> to List<Map<String, dynamic>>
        final followersList = followersData['followers'] as List<dynamic>? ?? [];
        final newFollowers = followersList.map((follower) => Map<String, dynamic>.from(follower)).toList();
        _followers.addAll(newFollowers);
        _hasMoreFollowers = followersData['has_more'] ?? false;
        _currentPage = nextPage;
        _isLoadingFollowers = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingFollowers = false;
      });
      print('Error loading more followers: $e');
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
                color: AppTheme.secondaryWarm.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.borderLightGray,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.black,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'My Profile',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
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



                  // Profile Information
                  _buildProfileInformation(),
                  const SizedBox(height: 24),

                  // Followers Section
                  _buildFollowersSection(),
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
          color: AppTheme.borderLightGray,
        ),
      ),
      child: Column(
        children: [
          // Profile Picture and Company Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Profile Picture
              Column(
                children: [
                  ProfilePictureDisplay(
                    avatarUrl: _profile['avatar_url'],
                    size: 80,
                    backgroundColor: AppTheme.primaryMaroon.withOpacity(0.1),
                    iconColor: AppTheme.primaryMaroon,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Profile Picture',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              // Company Logo
              Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppTheme.secondaryWarm.withOpacity(0.1),
                    child: _profile['company_logo_url'] != null
                        ? ClipOval(
                            child: Image.network(
                              _profile['company_logo_url'],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(
                                  Icons.business,
                                  size: 40,
                                  color: Colors.black,
                                );
                              },
                            ),
                          )
                        : const Icon(
                            Icons.business,
                            size: 40,
                            color: Colors.black,
                          ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Company Logo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Verified badge
          if (_profile['verified'] == true)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryMaroon,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.verified,
                    color: Colors.white,
                    size: 16,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Verified',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Company Name
          Text(
            _profile['company_name'] ?? 'Company Name',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Industry
          Text(
            _profile['industry'] ?? 'Industry',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black,
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
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${_profile['reviews'] ?? 0} reviews)',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Instagram-style Stats Cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildInstagramStyleStatCard(
                count: '${_profile['applications_submitted'] ?? 0}',
                label: 'Applications',
                icon: Icons.assignment,
              ),
              _buildInstagramStyleStatCard(
                count: '${_profile['applications_approved'] ?? 0}',
                label: 'Approved',
                icon: Icons.check_circle,
              ),
              _buildInstagramStyleStatCard(
                count: '$_followersCount',
                label: 'Followers',
                icon: Icons.people,
              ),
            ],
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
          color: AppTheme.borderLightGray,
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
              color: Colors.black,
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
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _profile['description'] ?? 'No description available',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black.withOpacity(0.9),
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
            color: AppTheme.primaryMaroon,
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
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFollowersSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderLightGray,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Followers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMaroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$_followersCount',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryMaroon,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_isLoadingFollowers && _followers.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_followers.isEmpty)
            _buildEmptyFollowersState()
          else
            Column(
              children: [
                ..._followers.map((follower) => _buildFollowerItem(follower)),
                if (_hasMoreFollowers) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoadingFollowers ? null : _loadMoreFollowers,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryMaroon,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoadingFollowers
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Load More Followers'),
                    ),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyFollowersState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPeach.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.borderLightGray,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 48,
            color: AppTheme.textMediumGray,
          ),
          const SizedBox(height: 16),
          Text(
            'No followers yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMediumGray,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'When shoppers mark your brand as favorite, they will appear here.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textMediumGray,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFollowerItem(Map<String, dynamic> follower) {
    final user = follower['user'] ?? {};
    final profile = user['profiles'] ?? {};
    final fullName = profile['full_name'] ?? 'Unknown User';
    final email = user['email'] ?? 'No email';
    final avatarUrl = profile['avatar_url'];
    final role = profile['role'] ?? 'user';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.borderLightGray,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          ProfilePictureDisplay(
            avatarUrl: avatarUrl,
            size: 48,
            backgroundColor: AppTheme.primaryMaroon.withOpacity(0.1),
            iconColor: AppTheme.primaryMaroon,
          ),
          const SizedBox(width: 12),
          
          // User Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getRoleColor(role).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getRoleColor(role).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    role.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: _getRoleColor(role),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Followed Date
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Icon(
                Icons.favorite,
                size: 16,
                color: AppTheme.primaryMaroon,
              ),
              const SizedBox(height: 4),
              Text(
                _formatFollowDate(follower['created_at']),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'brand':
        return AppTheme.primaryMaroon;
      case 'organizer':
        return AppTheme.primaryBlue;
      case 'shopper':
        return AppTheme.successGreen;
      default:
        return AppTheme.textMediumGray;
    }
  }

  String _formatFollowDate(dynamic date) {
    if (date == null) return 'Recently';
    
    try {
      final dateTime = date is String ? DateTime.parse(date) : date as DateTime;
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays == 0) {
        if (difference.inHours == 0) {
          return '${difference.inMinutes}m ago';
        }
        return '${difference.inHours}h ago';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else if (difference.inDays < 30) {
        final weeks = (difference.inDays / 7).floor();
        return '${weeks}w ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  Widget _buildInstagramStyleStatCard({
    required String count,
    required String label,
    required IconData icon,
  }) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to detailed view based on the stat type
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('View $label details'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppTheme.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.borderLightGray.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryMaroon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: AppTheme.primaryMaroon,
              ),
            ),
            const SizedBox(height: 8),
            
            // Count
            Text(
              count,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            
            // Label
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettings() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderLightGray,
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
              color: Colors.black,
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
            color: AppTheme.borderLightGray,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: isDestructive ? AppTheme.errorRed : Colors.black,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? AppTheme.errorRed : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: Colors.black.withOpacity(0.8),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.black.withOpacity(0.7),
      ),
      onTap: onTap,
    );
  }
}
