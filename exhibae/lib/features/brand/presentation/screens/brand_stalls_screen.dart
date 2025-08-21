import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/routes/app_router.dart';

class BrandStallsScreen extends StatefulWidget {
  const BrandStallsScreen({super.key});

  @override
  State<BrandStallsScreen> createState() => _BrandStallsScreenState();
}

class _BrandStallsScreenState extends State<BrandStallsScreen> with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService.instance;
  late TabController _tabController;
  List<Map<String, dynamic>> _stalls = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadStalls();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _loadStalls();
    }
  }

  Future<void> _loadStalls() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // First, check and update any completed exhibitions
      try {
        await _supabaseService.checkAndUpdateCompletedExhibitions();
      } catch (e) {
        // Continue loading stalls even if this fails
      }



      // Get all stall applications for the current user
      final allApplications = await _supabaseService.getStallApplications(brandId: userId);
      
      List<Map<String, dynamic>> filteredApplications;
      switch (_tabController.index) {
        case 0: // All
          filteredApplications = allApplications;
          break;
        case 1: // Pending
          filteredApplications = allApplications.where((app) => 
            (app['status'] as String?)?.toLowerCase() == 'pending'
          ).toList();
          break;
        case 2: // Booked
          filteredApplications = allApplications.where((app) => 
            (app['status'] as String?)?.toLowerCase() == 'booked'
          ).toList();
          break;
        case 3: // Completed (shows approved applications as completed)
          filteredApplications = allApplications.where((app) => 
            (app['status'] as String?)?.toLowerCase() == 'approved'
          ).toList();
          break;
        default:
          filteredApplications = allApplications;
      }

      if (mounted) {
        setState(() {
          _stalls = filteredApplications;
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



  String _formatDate(dynamic date) {
    if (date is DateTime) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (date is String) {
      try {
        final parsedDate = DateTime.parse(date);
        return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
      } catch (e) {
        return date;
      }
    }
    return date.toString();
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundPeach,
        elevation: 0,
        title: const Text(
          'My Stalls',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                // First check for completed exhibitions
                await _supabaseService.checkAndUpdateCompletedExhibitions();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Completed exhibitions check finished'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error checking exhibitions: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              // Then reload stalls
              _loadStalls();
            },
            icon: const Icon(
              Icons.refresh,
              color: Colors.black,
            ),
            tooltip: 'Refresh & Check Completed Exhibitions',
          ),

        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryMaroon,
          indicatorWeight: 3,
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black.withOpacity(0.6),
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Booked'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: _isLoading
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
                        'Error loading stalls',
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
                        onPressed: _loadStalls,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryMaroon,
                          foregroundColor: Colors.white,
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
              : _stalls.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppTheme.backgroundPeach.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.borderLightGray,
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              Icons.store_outlined,
                              size: 64,
                              color: AppTheme.primaryMaroon.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No stalls found',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getEmptyStateMessage(),
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black.withOpacity(0.8),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadStalls,
                      color: AppTheme.primaryMaroon,
                      backgroundColor: AppTheme.backgroundPeach,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _stalls.length,
                        itemBuilder: (context, index) {
                          final stall = _stalls[index];
                          return _buildStallCard(stall);
                        },
                      ),
                    ),
    );
  }

  String _getEmptyStateMessage() {
    switch (_tabController.index) {
      case 1:
        return 'You have no pending stall applications';
      case 2:
        return 'You have no booked stalls yet';
      default:
        return 'Start by applying for a stall in an exhibition';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.blue; // Show approved as completed (blue)
      case 'booked':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'rejected':
        return AppTheme.errorRed;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
        return Colors.grey;
      default:
        return AppTheme.white;
    }
  }

  Widget _buildStallCard(Map<String, dynamic> stall) {
    final exhibition = stall['exhibition'] ?? {};
    final stallDetails = stall['stall'] ?? {};
    final status = stall['status'] ?? 'pending';
    final stallInstance = stall['stall_instance'] ?? {};

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: _getCardBackgroundColor(status),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderLightGray,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRouter.stallDetails,
              arguments: {'stall': stall},
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exhibition['title'] ?? 'Unknown Exhibition',
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
                            '${exhibition['city']}, ${exhibition['state']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(0.8),
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
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getStatusColor(status).withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getStatusDisplayText(status),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(status),
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
                    color: Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.grid_on,
                            size: 16,
                            color: Colors.black.withOpacity(0.8),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Stall ${stallDetails['name'] ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.straighten,
                            size: 14,
                            color: Colors.black.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${stallDetails['length'] ?? '0'} x ${stallDetails['width'] ?? '0'} ${stallDetails['unit']?['symbol'] ?? 'm'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '₹${stallInstance['price'] ?? stallDetails['price'] ?? '0'}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                      if (stall['message'] != null && stall['message'].toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.message,
                              size: 14,
                              color: Colors.black.withOpacity(0.6),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                stall['message'].toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black.withOpacity(0.7),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
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



  Color _getCardBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.blue.withOpacity(0.1); // Show approved as completed (blue)
      case 'booked':
        return Colors.green.withOpacity(0.1);
      case 'completed':
        return Colors.blue.withOpacity(0.1);
      case 'rejected':
        return AppTheme.errorRed.withOpacity(0.1);
      case 'pending':
        return Colors.orange.withOpacity(0.1);
      case 'cancelled':
        return Colors.grey.withOpacity(0.1);
      default:
        return Colors.black.withOpacity(0.1);
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'COMPLETED'; // Show approved as completed
      case 'booked':
        return 'BOOKED';
      case 'completed':
        return 'COMPLETED';
      case 'rejected':
        return 'REJECTED';
      case 'pending':
        return 'PENDING';
      case 'cancelled':
        return 'CANCELLED';
      default:
        return status.toUpperCase();
    }
  }


}