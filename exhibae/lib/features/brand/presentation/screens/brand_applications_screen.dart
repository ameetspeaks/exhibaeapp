import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';

class BrandApplicationsScreen extends StatefulWidget {
  const BrandApplicationsScreen({super.key});

  @override
  State<BrandApplicationsScreen> createState() => _BrandApplicationsScreenState();
}

class _BrandApplicationsScreenState extends State<BrandApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Map<String, dynamic>> _applications = [];
  final SupabaseService _supabaseService = SupabaseService.instance;

  StreamSubscription? _applicationsSubscription;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadApplications();
    _subscribeToApplications();
  }

  @override
  void dispose() {
    _applicationsSubscription?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _subscribeToApplications() {
    final currentUser = _supabaseService.currentUser;
    if (currentUser != null) {
      _applicationsSubscription = _supabaseService
          .subscribeToStallApplications(brandId: currentUser.id)
          .listen((applications) {
        if (mounted) {
          setState(() {
            _applications = applications;
          });
        }
      }, onError: (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error subscribing to applications: $error'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      });
    }
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser != null) {
        final applications = await _supabaseService.getStallApplications(
          brandId: currentUser.id,
        );
        setState(() {
          _applications = applications;
          _isLoading = false;
        });
      } else {
        setState(() {
          _applications = [];
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
            content: Text('Error loading applications: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getApplicationsByStatus(String status) {
    return _applications.where((app) => app['status'] == status).toList();
  }

  int _getApplicationsCountByStatus(String status) {
    return _applications.where((app) => app['status'] == status).length;
  }

  int _getApprovedApplicationsCount() {
    return _getApplicationsCountByStatus('approved') + _getApplicationsCountByStatus('booked');
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'booked':
        return AppTheme.successGreen;
      case 'pending':
        return AppTheme.warningOrange;
      case 'rejected':
        return AppTheme.errorRed;
      case 'payment_pending':
      case 'payment_review':
        return AppTheme.primaryBlue;
      default:
        return AppTheme.textMediumGray;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'booked':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'rejected':
        return Icons.cancel;
      case 'payment_pending':
      case 'payment_review':
      case 'payment':
        return Icons.payment;
      default:
        return Icons.info;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'Approved';
      case 'booked':
        return 'Booked';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      case 'payment_pending':
        return 'Payment Pending';
      case 'payment_review':
        return 'Payment Review';
      default:
        return status;
    }
  }

  Future<void> _cancelApplication(String applicationId) async {
    try {
      await _supabaseService.deleteStallApplication(applicationId);
      await _loadApplications(); // Reload the list
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application cancelled successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling application: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLightGray,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(
              Icons.assignment,
              color: AppTheme.primaryBlue,
              size: 24,
            ),
            const SizedBox(width: 12),
            const Text(
              'My Applications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDarkCharcoal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadApplications,
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            color: AppTheme.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppTheme.primaryBlue,
              labelColor: AppTheme.primaryBlue,
              unselectedLabelColor: AppTheme.textMediumGray,
              tabs: [
                Tab(text: 'All (${_applications.length})'),
                Tab(text: 'Pending (${_getApplicationsCountByStatus('pending')})'),
                Tab(text: 'Approved (${_getApprovedApplicationsCount()})'),
              ],
            ),
          ),
          
          // Tab Content
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildApplicationsList(_applications),
                      _buildApplicationsList(_getApplicationsByStatus('pending')),
                      _buildApplicationsList(_getApplicationsByStatus('approved') + _getApplicationsByStatus('booked')),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
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

  Widget _buildApplicationsList(List<Map<String, dynamic>> applications) {
    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: AppTheme.textMediumGray,
            ),
            const SizedBox(height: 16),
            const Text(
              'No applications found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDarkCharcoal,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start applying to exhibitions to see your applications here',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textMediumGray,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: applications.length,
        itemBuilder: (context, index) {
          final application = applications[index];
          return _buildApplicationCard(application);
        },
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    final status = application['status']?.toString() ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);
    final statusDisplayName = _getStatusDisplayName(status);
    
    // Extract nested data
    final exhibition = application['exhibition'] as Map<String, dynamic>?;
    final stall = application['stall'] as Map<String, dynamic>?;
    final brand = application['brand'] as Map<String, dynamic>?;
    
    // Format dates
    final createdAt = application['created_at'] != null 
        ? DateTime.parse(application['created_at']).toLocal()
        : null;
    final appliedDate = createdAt != null 
        ? '${createdAt.day}/${createdAt.month}/${createdAt.year}'
        : 'Unknown Date';
    
    final exhibitionDate = _buildExhibitionDateString(exhibition);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header with Status Color
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _buildExhibitionTitleString(exhibition),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDarkCharcoal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stall: ${_buildStallNameString(stall)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMediumGray,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Stall No: ${_buildStallNumberString(stall, application)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMediumGray,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    statusDisplayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exhibition Date
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Exhibition Date: ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDarkCharcoal,
                      ),
                    ),
                    Text(
                      exhibitionDate,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textDarkCharcoal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Stall Number
                Row(
                  children: [
                    Icon(
                      Icons.numbers,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Stall No: ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDarkCharcoal,
                      ),
                    ),
                    Text(
                      _buildStallNumberString(stall, application),
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textDarkCharcoal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Location
                if (_hasValidLocation(exhibition)) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: AppTheme.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _buildLocationString(exhibition!),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.textDarkCharcoal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Organizer Name
                Row(
                  children: [
                    Icon(
                      Icons.business,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Organizer: ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDarkCharcoal,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _buildOrganizerNameString(brand),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textDarkCharcoal,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Applied Date
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 16,
                      color: AppTheme.primaryBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Applied on: ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDarkCharcoal,
                      ),
                    ),
                    Text(
                      appliedDate,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textDarkCharcoal,
                      ),
                    ),
                  ],
                ),
                
                // Message if available
                if (_hasValidMessage(application)) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLightGray,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Message:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMediumGray,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          application['message'],
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textDarkCharcoal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _showApplicationDetails(application);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.primaryBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(color: AppTheme.primaryBlue),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (status.toLowerCase() == 'pending')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _confirmCancelApplication(application['id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorRed,
                            foregroundColor: AppTheme.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _buildLocationString(Map<String, dynamic> exhibition) {
    final parts = <String>[];
    
    if (exhibition['address'] != null && exhibition['address'].toString().isNotEmpty) {
      parts.add(exhibition['address']);
    }
    if (exhibition['city'] != null && exhibition['city'].toString().isNotEmpty) {
      parts.add(exhibition['city']);
    }
    if (exhibition['state'] != null && exhibition['state'].toString().isNotEmpty) {
      parts.add(exhibition['state']);
    }
    
    if (parts.isEmpty) {
      return 'Location TBD';
    }
    
    return parts.join(', ');
  }

  String _buildExhibitionDateString(Map<String, dynamic>? exhibition) {
    if (exhibition == null) {
      return 'TBD';
    }
    final startDate = exhibition['start_date'] != null 
        ? DateTime.parse(exhibition['start_date']).toLocal()
        : null;
    return startDate != null 
        ? '${startDate.day}/${startDate.month}/${startDate.year}'
        : 'TBD';
  }

  String _buildOrganizerNameString(Map<String, dynamic>? brand) {
    if (brand == null) {
      return 'Unknown Organizer';
    }
    final companyName = brand['company_name']?.toString();
    final fullName = brand['full_name']?.toString();

    if (companyName != null && companyName.isNotEmpty) {
      return companyName;
    } else if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    } else {
      return 'Unknown Organizer';
    }
  }

  String _buildStallNameString(Map<String, dynamic>? stall) {
    if (stall == null) {
      return 'Unknown Stall';
    }
    final stallName = stall['name']?.toString();
    if (stallName != null && stallName.isNotEmpty) {
      return stallName;
    } else {
      return 'Unknown Stall';
    }
  }

  String _buildStallNumberString(Map<String, dynamic>? stall, Map<String, dynamic> application) {
    // First try to get from stall_instance data
    final stallInstance = application['stall_instance'] as Map<String, dynamic>?;
    if (stallInstance != null) {
      final instanceNumber = stallInstance['instance_number']?.toString();
      if (instanceNumber != null && instanceNumber.isNotEmpty) {
        return instanceNumber;
      }
    }
    
    // Fallback to stall data
    if (stall != null) {
      final stallNumber = stall['stall_number']?.toString();
      if (stallNumber != null && stallNumber.isNotEmpty) {
        return stallNumber;
      }
    }
    
    return 'N/A';
  }

  String _buildExhibitionTitleString(Map<String, dynamic>? exhibition) {
    if (exhibition == null) {
      return 'Unknown Exhibition';
    }
    final title = exhibition['title']?.toString();
    if (title != null && title.isNotEmpty) {
      return title;
    } else {
      return 'Exhibition';
    }
  }

  bool _hasValidMessage(Map<String, dynamic> application) {
    final message = application['message']?.toString();
    return message != null && message.isNotEmpty;
  }

  bool _hasValidLocation(Map<String, dynamic>? exhibition) {
    if (exhibition == null) {
      return false;
    }
    final address = exhibition['address']?.toString();
    final city = exhibition['city']?.toString();
    final state = exhibition['state']?.toString();
    return address != null && address.isNotEmpty || city != null && city.isNotEmpty || state != null && state.isNotEmpty;
  }

  void _showApplicationDetails(Map<String, dynamic> application) {
    final status = application['status']?.toString() ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusDisplayName = _getStatusDisplayName(status);
    
    // Extract nested data
    final exhibition = application['exhibition'] as Map<String, dynamic>?;
    final stall = application['stall'] as Map<String, dynamic>?;
    final brand = application['brand'] as Map<String, dynamic>?;
    
    // Format dates
    final createdAt = application['created_at'] != null 
        ? DateTime.parse(application['created_at']).toLocal()
        : null;
    final appliedDate = createdAt != null 
        ? '${createdAt.day}/${createdAt.month}/${createdAt.year} at ${createdAt.hour}:${createdAt.minute.toString().padLeft(2, '0')}'
        : 'Unknown Date';
    
    final startDate = exhibition?['start_date'] != null 
        ? DateTime.parse(exhibition!['start_date']).toLocal()
        : null;
    final exhibitionDate = startDate != null 
        ? '${startDate.day}/${startDate.month}/${startDate.year}'
        : 'TBD';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getStatusIcon(status),
                        color: statusColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _buildExhibitionTitleString(exhibition),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDarkCharcoal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Stall No: ${_buildStallNumberString(stall, application)}',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.primaryBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              statusDisplayName,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Details
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailRow('Stall', _buildStallNameString(stall), Icons.grid_on),
                        const SizedBox(height: 16),
                        _buildDetailRow('Stall No', _buildStallNumberString(stall, application), Icons.numbers),
                        const SizedBox(height: 16),
                        _buildDetailRow('Exhibition Date', exhibitionDate, Icons.calendar_today),
                        const SizedBox(height: 16),
                        if (_hasValidLocation(exhibition))
                          _buildDetailRow('Location', _buildLocationString(exhibition!), Icons.location_on),
                        if (_hasValidLocation(exhibition)) const SizedBox(height: 16),
                        _buildDetailRow('Organizer', _buildOrganizerNameString(brand), Icons.business),
                        const SizedBox(height: 16),
                        _buildDetailRow('Applied On', appliedDate, Icons.access_time),
                        if (_hasValidMessage(application)) ...[
                          const SizedBox(height: 16),
                          _buildDetailRow('Message', application['message'], Icons.message),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.primaryBlue),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(color: AppTheme.primaryBlue, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (status.toLowerCase() == 'pending')
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            await _confirmCancelApplication(application['id']);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.errorRed,
                            foregroundColor: AppTheme.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text(
                            'Cancel Application',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppTheme.primaryBlue,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textMediumGray,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppTheme.textDarkCharcoal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _confirmCancelApplication(String applicationId) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Cancellation'),
          content: const Text('Are you sure you want to cancel this application? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
                foregroundColor: AppTheme.white,
              ),
              child: const Text('Yes, Cancel Application'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _cancelApplication(applicationId);
    }
  }
}
