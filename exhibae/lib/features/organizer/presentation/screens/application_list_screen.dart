import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/profile_picture_display.dart';
import '../../../../core/routes/app_router.dart';

class ApplicationListScreen extends StatefulWidget {
  final String? exhibitionId;
  final String? exhibitionTitle;
  
  const ApplicationListScreen({
    super.key,
    this.exhibitionId,
    this.exhibitionTitle,
  });

  @override
  State<ApplicationListScreen> createState() => _ApplicationListScreenState();
}

class _ApplicationListScreenState extends State<ApplicationListScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _applications = [];
  bool _isLoading = true;

  String? _error;
  String _selectedFilter = 'pending';
  String _selectedExhibition = 'all';
  List<Map<String, dynamic>> _exhibitions = [];

  @override
  void initState() {
    super.initState();
    // If exhibitionId is provided, set it as the selected exhibition filter
    if (widget.exhibitionId != null) {
      _selectedExhibition = widget.exhibitionId!;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Load organizer's exhibitions
      final organizerExhibitions = await _supabaseService.getOrganizerExhibitions(userId);

      // Load applications
      final applications = await _supabaseService.getStallApplications();
      
      final organizerApplications = applications.where((app) {
        final exhibition = app['exhibition'];
        final isOrganizerApp = exhibition != null && 
               organizerExhibitions.any((ex) => ex['id'] == exhibition['id']);
        
        return isOrganizerApp;
      }).toList();

      if (mounted) {
        setState(() {
          _exhibitions = organizerExhibitions;
          _applications = organizerApplications;
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

  List<Map<String, dynamic>> get _filteredApplications {
    return _applications.where((application) {
      // Search filter
      final brand = application['brand'] ?? {};
      final exhibition = application['exhibition'] ?? {};
      final brandName = brand['company_name']?.toString().toLowerCase() ?? '';
      final exhibitionTitle = exhibition['title']?.toString().toLowerCase() ?? '';
      final matchesSearch = 
        brandName.contains(_searchQuery.toLowerCase()) ||
        exhibitionTitle.contains(_searchQuery.toLowerCase());
      
      if (!matchesSearch) return false;
      
      // Status filter
      if (_selectedFilter != 'all' && application['status'] != _selectedFilter) {
        return false;
      }

      // Exhibition filter
      if (_selectedExhibition != 'all' && exhibition['id'] != _selectedExhibition) {
        return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundPeach,
        elevation: 0,
        title: Text(
          widget.exhibitionTitle != null 
              ? '${widget.exhibitionTitle} - Applications'
              : 'Applications',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryMaroon.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryMaroon.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.refresh,
                color: AppTheme.primaryMaroon,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundPeach,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.borderLightGray,
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Search applications...',
                      hintStyle: TextStyle(color: Colors.black.withOpacity(0.6)),
                      prefixIcon: Icon(Icons.search, color: Colors.black.withOpacity(0.6)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Pending', 'pending'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Approved', 'approved'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Rejected', 'rejected'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content Section
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error loading applications',
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
                              onPressed: _loadData,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryMaroon,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredApplications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(40),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryMaroon.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: AppTheme.primaryMaroon.withOpacity(0.3),
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.assignment_outlined,
                                    size: 80,
                                    color: AppTheme.primaryMaroon,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                Text(
                                  'No Applications Found',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Applications from brands will appear here.',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black.withOpacity(0.8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            color: AppTheme.primaryMaroon,
                            backgroundColor: AppTheme.backgroundPeach,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredApplications.length,
                              itemBuilder: (context, index) {
                                final application = _filteredApplications[index];
                                return _buildApplicationCard(application);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = selected ? value : 'all';
        });
      },
      backgroundColor: AppTheme.backgroundPeach,
      selectedColor: AppTheme.primaryMaroon,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
        fontWeight: FontWeight.bold,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      showCheckmark: false,
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    final brand = application['brand'] ?? {};
    final exhibition = application['exhibition'] ?? {};
    final stall = application['stall'] ?? {};
    final status = application['status'] ?? 'pending';
    
    Color getStatusColor() {
      switch (status) {
        case 'booked':
          return Colors.green;
        case 'completed':
          return Colors.blue;
        case 'payment_pending':
          return Colors.orange;
        case 'payment_review':
          return Colors.blue;
        case 'rejected':
          return AppTheme.errorRed;
        case 'cancelled':
          return Colors.grey;
        case 'pending':
        default:
          return AppTheme.primaryMaroon;
      }
    }

    String getStatusText() {
      switch (status) {
        case 'booked':
          return 'BOOKED';
        case 'completed':
          return 'COMPLETED';
        case 'payment_pending':
          return 'PAYMENT PENDING';
        case 'payment_review':
          return 'PAYMENT REVIEW';
        case 'rejected':
          return 'REJECTED';
        case 'cancelled':
          return 'CANCELLED';
        case 'pending':
        default:
          return 'PENDING';
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderLightGray,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRouter.applicationDetails,
              arguments: application,
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            exhibition['title'] ?? 'Unknown Exhibition',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(0.7),
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
                          color: getStatusColor(),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        getStatusText(),
                        style: TextStyle(
                          fontSize: 11,
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
                    color: AppTheme.backgroundPeach,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.grid_on,
                        size: 16,
                        color: AppTheme.primaryMaroon.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Stall ${stall['name'] ?? 'Unknown'} - ${stall['length'] ?? '0'}x${stall['width'] ?? '0'}${stall['unit']?['symbol'] ?? 'm'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        ),
                      ),
                      Text(
                        '₹${stall['price'] ?? '0'}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                // Show action buttons only for pending applications
                if (status == 'pending') ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            try {
                              await _supabaseService.updateStallApplication(
                                application['id'],
                                status: 'rejected',
                              );
                              
                              if (mounted) {
                                _loadData();
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error rejecting application: $e'),
                                    backgroundColor: AppTheme.errorRed,
                                  ),
                                );
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.errorRed,
                            side: BorderSide(
                              color: AppTheme.errorRed.withOpacity(0.5),
                              width: 1,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Reject'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await _supabaseService.updateStallApplication(
                                application['id'],
                                status: 'payment_pending',
                              );
                              
                              if (mounted) {
                                _loadData();
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error approving application: $e'),
                                    backgroundColor: AppTheme.errorRed,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: AppTheme.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Approve'),
                        ),
                      ),
                    ],
                  ),
                ],
                // Show payment review button for payment_review status
                if (status == 'payment_review') ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _navigateToPaymentReview(application),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryMaroon,
                        foregroundColor: AppTheme.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Review Payment'),
                    ),
                  ),
                ],
                // Show additional info for other statuses
                if (status != 'pending' && status != 'payment_review') ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: getStatusColor().withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: getStatusColor().withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(status),
                          size: 16,
                          color: getStatusColor(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getStatusDescription(status),
                            style: TextStyle(
                              fontSize: 12,
                              color: getStatusColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'booked':
        return Icons.check_circle;
      case 'completed':
        return Icons.event_available;
      case 'payment_pending':
        return Icons.payment;
      case 'payment_review':
        return Icons.rate_review;
      case 'rejected':
        return Icons.cancel;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.info;
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'booked':
        return 'Application approved and stall booked';
      case 'completed':
        return 'Exhibition completed successfully';
      case 'payment_pending':
        return 'Waiting for payment confirmation';
      case 'payment_review':
        return 'Payment under review';
      case 'rejected':
        return 'Application has been rejected';
      case 'cancelled':
        return 'Application was cancelled';
      default:
        return 'Application is pending review';
    }
  }

  void _navigateToPaymentReview(Map<String, dynamic> application) {
    Navigator.pushNamed(
      context,
      AppRouter.paymentReview,
      arguments: {'application': application},
    ).then((result) {
      if (result == true) {
        _loadData();
      }
    });
  }
}
