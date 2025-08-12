import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';

class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _analyticsData;
  String? _error;
  String _selectedTimeRange = 'month';

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get exhibitions data
      final exhibitions = await _supabaseService.getExhibitions();
      final organizerExhibitions = exhibitions.where((exhibition) => 
        exhibition['organiser']?['id'] == userId
      ).toList();

      // Get applications data
      final applications = await _supabaseService.getStallApplications();
      final exhibitionIds = organizerExhibitions.map((e) => e['id']).toList();
      final exhibitionApplications = applications.where((app) => 
        exhibitionIds.contains(app['exhibition_id'])
      ).toList();

      // Calculate analytics
      final totalExhibitions = organizerExhibitions.length;
      final activeExhibitions = organizerExhibitions.where((e) => 
        e['status'] == 'published' || e['status'] == 'live'
      ).length;
      final totalApplications = exhibitionApplications.length;
      final approvedApplications = exhibitionApplications.where((a) => 
        a['status'] == 'approved'
      ).length;
      final totalRevenue = exhibitionApplications
          .where((a) => a['status'] == 'approved')
          .fold(0.0, (sum, app) => sum + (app['stall']?['price'] ?? 0.0));

      // Calculate trends
      final now = DateTime.now();
      final startDate = _selectedTimeRange == 'month'
          ? DateTime(now.year, now.month - 1, now.day)
          : DateTime(now.year, now.month - 3, now.day);

      final recentApplications = exhibitionApplications.where((app) {
        final createdAt = DateTime.parse(app['created_at']);
        return createdAt.isAfter(startDate);
      }).toList();

      final applicationTrend = recentApplications.length;
      final revenueTrend = recentApplications
          .where((a) => a['status'] == 'approved')
          .fold(0.0, (sum, app) => sum + (app['stall']?['price'] ?? 0.0));

      if (mounted) {
        setState(() {
          _analyticsData = {
            'totalExhibitions': totalExhibitions,
            'activeExhibitions': activeExhibitions,
            'totalApplications': totalApplications,
            'approvedApplications': approvedApplications,
            'totalRevenue': totalRevenue,
            'applicationTrend': applicationTrend,
            'revenueTrend': revenueTrend,
          };
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Analytics',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedTimeRange,
                items: [
                  DropdownMenuItem(
                    value: 'month',
                    child: Text(
                      'Last Month',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'quarter',
                    child: Text(
                      'Last Quarter',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedTimeRange = value;
                    });
                    _loadAnalytics();
                  }
                },
                dropdownColor: AppTheme.gradientBlack,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: AppTheme.white,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading analytics',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: AppTheme.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAnalytics,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.white.withOpacity(0.2),
                          foregroundColor: AppTheme.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview Section
                      _buildSection(
                        'Overview',
                        Icons.analytics,
                        [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Total Exhibitions',
                                  _analyticsData!['totalExhibitions'].toString(),
                                  Icons.event,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  'Active Exhibitions',
                                  _analyticsData!['activeExhibitions'].toString(),
                                  Icons.event_available,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Total Applications',
                                  _analyticsData!['totalApplications'].toString(),
                                  Icons.assignment,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildStatCard(
                                  'Approved Applications',
                                  _analyticsData!['approvedApplications'].toString(),
                                  Icons.check_circle,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Revenue Section
                      _buildSection(
                        'Revenue',
                        Icons.payments,
                        [
                          _buildRevenueCard(
                            'Total Revenue',
                            '₹${_analyticsData!['totalRevenue'].toStringAsFixed(2)}',
                            'Revenue this ${_selectedTimeRange == 'month' ? 'month' : 'quarter'}: ₹${_analyticsData!['revenueTrend'].toStringAsFixed(2)}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Trends Section
                      _buildSection(
                        'Trends',
                        Icons.trending_up,
                        [
                          _buildTrendCard(
                            'Applications',
                            _analyticsData!['applicationTrend'],
                            _analyticsData!['totalApplications'],
                            _selectedTimeRange == 'month' ? 'Last Month' : 'Last Quarter',
                          ),
                          const SizedBox(height: 16),
                          _buildTrendCard(
                            'Revenue',
                            _analyticsData!['revenueTrend'],
                            _analyticsData!['totalRevenue'],
                            _selectedTimeRange == 'month' ? 'Last Month' : 'Last Quarter',
                            isRevenue: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
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
              fontSize: 14,
              color: AppTheme.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(String title, String value, String subtitle) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppTheme.white,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.white.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendCard(String title, double recent, double total, String period, {bool isRevenue = false}) {
    final percentage = total > 0 ? (recent / total * 100).round() : 0;
    final formattedRecent = isRevenue ? '₹${recent.toStringAsFixed(2)}' : recent.toString();
    final formattedTotal = isRevenue ? '₹${total.toStringAsFixed(2)}' : total.toString();

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '$percentage% of total',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.white.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      period,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedRecent,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.white.withOpacity(0.2),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.white.withOpacity(0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedTotal,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
