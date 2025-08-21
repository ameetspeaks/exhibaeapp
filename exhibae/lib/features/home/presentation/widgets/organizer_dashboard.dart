import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/dashboard_service.dart';
import '../../../../core/widgets/app_logo.dart';
import '../../../../core/widgets/responsive_card.dart';
import '../../../../core/widgets/profile_picture_display.dart';

class OrganizerDashboard extends StatefulWidget {
  const OrganizerDashboard({super.key});

  @override
  State<OrganizerDashboard> createState() => _OrganizerDashboardState();
}

class _OrganizerDashboardState extends State<OrganizerDashboard> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final DashboardService _dashboardService = DashboardService.instance;
  
  Map<String, dynamic> _dashboardData = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final currentUser = _supabaseService.client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      final data = await _dashboardService.getOrganizerDashboardData(currentUser.id);
      if (mounted) {
        setState(() {
          _dashboardData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundPeach,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundPeach,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error loading dashboard',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(
                  color: Colors.black.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadDashboardData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMaroon,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryMaroon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.borderLightGray,
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.dashboard,
                color: AppTheme.primaryMaroon,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryMaroon,
              ),
            ),
          ],
        ),
        actions: [
          // Notifications button
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMaroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.borderLightGray,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: AppTheme.primaryMaroon,
                  size: 20,
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notifications coming soon!')),
                );
              },
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: AppTheme.primaryMaroon,
        backgroundColor: AppTheme.backgroundPeach,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 20),
              _buildStatsSection(),
              const SizedBox(height: 20),
              _buildQuickActionsSection(),
              const SizedBox(height: 20),
              _buildRecentApplicationsSection(),
              const SizedBox(height: 20),
              _buildRecentExhibitionsSection(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final profile = _dashboardData['profile'] as Map<String, dynamic>?;
    final companyName = profile?['company_name'] ?? 'Organizer';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPeach.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.borderLightGray,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryMaroon.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryMaroon.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.business,
                  color: AppTheme.primaryMaroon,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.primaryMaroon.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      companyName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Organizer',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.primaryMaroon.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryMaroon.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.borderLightGray,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  color: AppTheme.primaryMaroon,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Manage your exhibitions and applications efficiently!',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryMaroon,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Container(
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              title: 'Active Exhibitions',
              value: '${_dashboardData['stats']?['activeExhibitions'] ?? 0}',
              icon: Icons.event,
              color: AppTheme.primaryMaroon,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              title: 'Total Applications',
              value: '${_dashboardData['stats']?['totalApplications'] ?? 0}',
              icon: Icons.assignment,
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryMaroon,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Revenue Analytics',
                  subtitle: 'View earnings & analytics',
                  icon: Icons.attach_money,
                  color: Colors.green,
                  onTap: () => Navigator.pushNamed(context, '/revenue'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                                 child: _buildQuickActionCard(
                   title: 'Followers',
                   subtitle: 'View your followers',
                   icon: Icons.people,
                   color: AppTheme.primaryMaroon,
                   onTap: () => Navigator.pushNamed(context, '/favorites'),
                 ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ResponsiveCard(
      padding: const EdgeInsets.all(16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.black.withOpacity(0.4),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      height: 60,
      child: ResponsiveCard(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppTheme.borderLightGray,
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 14,
                  ),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.primaryMaroon.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildRecentApplicationsSection() {
    final recentApplications = _dashboardData['pendingApplications'] as List<dynamic>? ?? [];
    
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Applications',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryMaroon,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/applications');
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.primaryMaroon,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentApplications.isEmpty)
            ResponsiveCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 48,
                    color: AppTheme.primaryMaroon.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No applications yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Applications from brands will appear here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            ...recentApplications.take(3).map((application) => _buildApplicationCard(application)),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    final brand = application['brand'] ?? {};
    final status = application['status'] ?? 'pending';
    
    Color getStatusColor() {
      switch (status) {
        case 'approved':
          return Colors.green;
        case 'rejected':
          return AppTheme.errorRed;
        default:
          return AppTheme.primaryMaroon;
      }
    }

    return ResponsiveCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ProfilePictureDisplay(
            avatarUrl: brand['avatar_url'],
            size: 40,
            backgroundColor: AppTheme.primaryMaroon.withOpacity(0.1),
            iconColor: AppTheme.primaryMaroon,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand['company_name'] ?? 'Unknown Brand',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  application['exhibition']?['title'] ?? 'Unknown Exhibition',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: getStatusColor().withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: getStatusColor(),
                width: 1,
              ),
            ),
            child: Text(
              status.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                color: getStatusColor(),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentExhibitionsSection() {
    final recentExhibitions = _dashboardData['organizerExhibitions'] as List<dynamic>? ?? [];
    
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Exhibitions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryMaroon,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/exhibitions');
                },
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: AppTheme.primaryMaroon,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recentExhibitions.isEmpty)
            ResponsiveCard(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.event_outlined,
                    size: 48,
                    color: AppTheme.primaryMaroon.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No exhibitions yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create your first exhibition to get started',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/exhibition-form');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryMaroon,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Exhibition'),
                  ),
                ],
              ),
            )
          else
            ...recentExhibitions.take(3).map((exhibition) => _buildExhibitionCard(exhibition)),
        ],
      ),
    );
  }

  Widget _buildExhibitionCard(Map<String, dynamic> exhibition) {
    final status = exhibition['status'] ?? 'draft';
    final exhibitionId = exhibition['id'] as String?;
    
    Color getStatusColor() {
      switch (status) {
        case 'published':
          return const Color(0xFF22C55E); // Green for "live/active"
        case 'live':
          return const Color(0xFF22C55E); // Green for "live/active"
        case 'completed':
          return const Color(0xFF3B82F6); // Blue for "done/closed properly"
        case 'draft':
          return const Color(0xFFFACC15); // Amber/Yellow for "work in progress"
        case 'cancelled':
          return const Color(0xFFEF4444); // Red for "stopped/terminated"
        default:
          return Colors.grey;
      }
    }

    String getStatusDisplayText() {
      switch (status) {
        case 'draft':
          return 'PENDING FOR APPROVAL';
        default:
          return status.toUpperCase();
      }
    }

    // Set background color based on status
    Color getCardBackgroundColor() {
      switch (status) {
        case 'published':
          return const Color(0xFFF0FDF4); // Light green background for published status
        case 'draft':
          return const Color(0xFFFEFCE8); // Light amber background for draft status
        case 'completed':
          return const Color(0xFFEFF6FF); // Light blue background for completed status
        case 'cancelled':
          return const Color(0xFFFEF2F2); // Light red background for cancelled status
        default:
          return AppTheme.white;
      }
    }

    return ResponsiveCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      backgroundColor: getCardBackgroundColor(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMaroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppTheme.borderLightGray,
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.event,
                  color: AppTheme.primaryMaroon,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exhibition['title'] ?? 'Untitled Exhibition',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      exhibition['location'] ?? 'Location not specified',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: getStatusColor(),
                    width: 1,
                  ),
                ),
                child: Text(
                  getStatusDisplayText(),
                  style: TextStyle(
                    fontSize: 10,
                    color: getStatusColor(),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (exhibitionId != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                                 Expanded(
                   child: OutlinedButton.icon(
                     onPressed: () {
                       Navigator.pushNamed(
                         context,
                         '/applications',
                         arguments: {
                           'exhibitionId': exhibitionId,
                           'exhibitionTitle': exhibition['title'] ?? 'Unknown Exhibition',
                         },
                       );
                     },
                     style: OutlinedButton.styleFrom(
                       foregroundColor: AppTheme.primaryMaroon,
                       side: BorderSide(color: AppTheme.primaryMaroon),
                       padding: const EdgeInsets.symmetric(vertical: 8),
                     ),
                     icon: const Icon(Icons.assignment, size: 16),
                     label: const Text('Applications'),
                   ),
                 ),
                const SizedBox(width: 8),
                                 Expanded(
                   child: ElevatedButton.icon(
                                           onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/organizer-exhibition-details',
                          arguments: {
                            'exhibition': exhibition,
                          },
                        );
                      },
                                           style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryMaroon,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('Manage'),
                   ),
                 ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Check if an exhibition can be edited
  bool _canEditExhibition(Map<String, dynamic> exhibition) {
    final status = exhibition['status']?.toString().toLowerCase() ?? 'draft';
    // Only allow editing for draft, published, and live statuses
    return status == 'draft' || status == 'published' || status == 'live';
  }
}
