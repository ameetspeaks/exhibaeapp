import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../services/report_export_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _isLoading = true;
  Map<String, dynamic>? _reportsData;
  String? _error;
  String _selectedReport = 'exhibitions';
  String _selectedTimeRange = 'month';
  String _selectedStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
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

      // Filter by time range
      final now = DateTime.now();
      final startDate = _selectedTimeRange == 'month'
          ? DateTime(now.year, now.month - 1, now.day)
          : _selectedTimeRange == 'quarter'
              ? DateTime(now.year, now.month - 3, now.day)
              : DateTime(now.year - 1, now.month, now.day);

      final filteredExhibitions = organizerExhibitions.where((exhibition) {
        final createdAt = DateTime.parse(exhibition['created_at']);
        return createdAt.isAfter(startDate);
      }).toList();

      final filteredApplications = exhibitionApplications.where((app) {
        final createdAt = DateTime.parse(app['created_at']);
        return createdAt.isAfter(startDate);
      }).toList();

      // Filter by status
      final statusFilteredExhibitions = _selectedStatus == 'all'
          ? filteredExhibitions
          : filteredExhibitions.where((e) => e['status'] == _selectedStatus).toList();

      final statusFilteredApplications = _selectedStatus == 'all'
          ? filteredApplications
          : filteredApplications.where((a) => a['status'] == _selectedStatus).toList();

      if (mounted) {
        setState(() {
          _reportsData = {
            'exhibitions': statusFilteredExhibitions,
            'applications': statusFilteredApplications,
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

  Future<void> _exportReport() async {
    try {
      setState(() {
        _isLoading = true;
      });

      if (_selectedReport == 'exhibitions') {
        await ReportExportService.exportExhibitionsReport(_reportsData?['exhibitions'] ?? []);
      } else {
        await ReportExportService.exportApplicationsReport(_reportsData?['applications'] ?? []);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report exported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting report: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
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
          'Reports',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _exportReport,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.download,
                color: AppTheme.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Report Type Selector
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedReport,
                      items: [
                        DropdownMenuItem(
                          value: 'exhibitions',
                          child: Text(
                            'Exhibitions Report',
                            style: TextStyle(
                              color: AppTheme.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'applications',
                          child: Text(
                            'Applications Report',
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
                            _selectedReport = value;
                          });
                          _loadReports();
                        }
                      },
                      dropdownColor: AppTheme.gradientBlack,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: AppTheme.white,
                      ),
                      isExpanded: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Filters Row
                Row(
                  children: [
                    // Time Range Filter
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
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
                              DropdownMenuItem(
                                value: 'year',
                                child: Text(
                                  'Last Year',
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
                                _loadReports();
                              }
                            },
                            dropdownColor: AppTheme.gradientBlack,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: AppTheme.white,
                            ),
                            isExpanded: true,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Status Filter
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppTheme.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            items: _selectedReport == 'exhibitions'
                                ? [
                                    DropdownMenuItem(
                                      value: 'all',
                                      child: Text(
                                        'All Status',
                                        style: TextStyle(
                                          color: AppTheme.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'published',
                                      child: Text(
                                        'Published',
                                        style: TextStyle(
                                          color: AppTheme.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'live',
                                      child: Text(
                                        'Live',
                                        style: TextStyle(
                                          color: AppTheme.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'completed',
                                      child: Text(
                                        'Completed',
                                        style: TextStyle(
                                          color: AppTheme.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ]
                                : [
                                    DropdownMenuItem(
                                      value: 'all',
                                      child: Text(
                                        'All Status',
                                        style: TextStyle(
                                          color: AppTheme.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'pending',
                                      child: Text(
                                        'Pending',
                                        style: TextStyle(
                                          color: AppTheme.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'approved',
                                      child: Text(
                                        'Approved',
                                        style: TextStyle(
                                          color: AppTheme.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: 'rejected',
                                      child: Text(
                                        'Rejected',
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
                                  _selectedStatus = value;
                                });
                                _loadReports();
                              }
                            },
                            dropdownColor: AppTheme.gradientBlack,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: AppTheme.white,
                            ),
                            isExpanded: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: _isLoading
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
                              'Error loading reports',
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
                              onPressed: _loadReports,
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
                    : _selectedReport == 'exhibitions'
                        ? _buildExhibitionsReport()
                        : _buildApplicationsReport(),
          ),
        ],
      ),
    );
  }

  Widget _buildExhibitionsReport() {
    final exhibitions = _reportsData?['exhibitions'] ?? [];
    
    if (exhibitions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.event_busy,
                size: 64,
                color: AppTheme.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No exhibitions found',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(
                color: AppTheme.white.withOpacity(0.8),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: exhibitions.length,
      itemBuilder: (context, index) {
        final exhibition = exhibitions[index];
        return _buildExhibitionReportCard(exhibition);
      },
    );
  }

  Widget _buildApplicationsReport() {
    final applications = _reportsData?['applications'] ?? [];
    
    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.assignment_late,
                size: 64,
                color: AppTheme.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No applications found',
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: TextStyle(
                color: AppTheme.white.withOpacity(0.8),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final application = applications[index];
        return _buildApplicationReportCard(application);
      },
    );
  }

  Widget _buildExhibitionReportCard(Map<String, dynamic> exhibition) {
    final status = exhibition['status'] ?? 'draft';
    final startDate = exhibition['start_date'] != null
        ? DateTime.parse(exhibition['start_date'])
        : null;
    final endDate = exhibition['end_date'] != null
        ? DateTime.parse(exhibition['end_date'])
        : null;
    
    Color getStatusColor() {
      switch (status) {
        case 'published':
          return AppTheme.white;
        case 'live':
          return Colors.green;
        case 'completed':
          return Colors.orange;
        default:
          return Colors.grey;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to exhibition details
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exhibition['title'] ?? 'Untitled Exhibition',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            exhibition['location'] ?? 'Location not specified',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.white.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: getStatusColor().withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: getStatusColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      _buildStatItem(
                        Icons.calendar_today,
                        'Date',
                        startDate != null && endDate != null
                            ? '${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}'
                            : 'Not set',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: AppTheme.white.withOpacity(0.1),
                      ),
                      _buildStatItem(
                        Icons.people,
                        'Applications',
                        '${exhibition['application_count'] ?? 0}',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        color: AppTheme.white.withOpacity(0.1),
                      ),
                      _buildStatItem(
                        Icons.grid_on,
                        'Stalls',
                        '${exhibition['stall_count'] ?? 0}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationReportCard(Map<String, dynamic> application) {
    final brand = application['brand'] ?? {};
    final exhibition = application['exhibition'] ?? {};
    final stall = application['stall'] ?? {};
    final status = application['status'] ?? 'pending';
    
    Color getStatusColor() {
      switch (status) {
        case 'approved':
          return Colors.green;
        case 'rejected':
          return AppTheme.errorRed;
        default:
          return AppTheme.white;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: Navigate to application details
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppTheme.white.withOpacity(0.1),
                      child: Text(
                        brand['company_name']?.substring(0, 1).toUpperCase() ?? 'B',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            brand['company_name'] ?? 'Unknown Brand',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            exhibition['title'] ?? 'Unknown Exhibition',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.white.withOpacity(0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: getStatusColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: getStatusColor().withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: getStatusColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.grid_on,
                        size: 16,
                        color: AppTheme.white.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Stall ${stall['name'] ?? 'Unknown'} - ${stall['length']}x${stall['width']}${stall['unit']?['symbol'] ?? 'm'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.white.withOpacity(0.8),
                          ),
                        ),
                      ),
                      Text(
                        '₹${stall['price'] ?? '0'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: AppTheme.white.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.white,
            ),
          ),
        ],
      ),
    );
  }
}
