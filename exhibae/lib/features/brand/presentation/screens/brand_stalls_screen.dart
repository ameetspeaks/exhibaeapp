import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';

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
  bool _isTestMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        print('Loaded ${filteredApplications.length} stalls for user $userId');
        print('Total applications from database: ${allApplications.length}');
        if (allApplications.isNotEmpty) {
          print('All applications statuses: ${allApplications.map((app) => app['status']).toList()}');
        }
        if (filteredApplications.isNotEmpty) {
          print('First stall data: ${filteredApplications.first}');
        }
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
    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'My Stalls',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            if (_isTestMode)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'TEST MODE',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            IconButton(
              onPressed: _loadStalls,
              icon: Icon(
                Icons.refresh,
                color: AppTheme.white,
              ),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppTheme.white,
            indicatorWeight: 3,
            labelColor: AppTheme.white,
            unselectedLabelColor: AppTheme.white.withOpacity(0.6),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Pending'),
              Tab(text: 'Booked'),
            ],
          ),
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
                          'Error loading stalls',
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
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadStalls,
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
                : _stalls.isEmpty
                    ? Center(
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
                                Icons.store_outlined,
                                size: 64,
                                color: AppTheme.white.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No stalls found',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getEmptyStateMessage(),
                              style: TextStyle(
                                color: AppTheme.white.withOpacity(0.8),
                                fontSize: 16,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            if (!_isTestMode) ...[
                              ElevatedButton(
                                onPressed: _createTestStallApplication,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.white.withOpacity(0.2),
                                  foregroundColor: AppTheme.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Load Test Data'),
                              ),
                            ] else ...[
                              ElevatedButton(
                                onPressed: _clearTestData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.withOpacity(0.2),
                                  foregroundColor: Colors.blue,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Clear Test Data'),
                              ),
                            ],
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadStalls,
                        color: AppTheme.white,
                        backgroundColor: AppTheme.gradientBlack,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _stalls.length,
                          itemBuilder: (context, index) {
                            final stall = _stalls[index];
                            return _buildStallCard(stall);
                          },
                        ),
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
        return Colors.green;
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
          color: _getStatusColor(status).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            _showStallDetails(stall);
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
                    color: AppTheme.white.withOpacity(0.05),
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
                            color: AppTheme.white.withOpacity(0.8),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Stall ${stallDetails['name'] ?? 'Unknown'}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.white,
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
                            color: AppTheme.white.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${stallDetails['length'] ?? '0'} x ${stallDetails['width'] ?? '0'} ${stallDetails['unit']?['symbol'] ?? 'm'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.white.withOpacity(0.7),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '₹${stallInstance['price'] ?? stallDetails['price'] ?? '0'}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.white,
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
                              color: AppTheme.white.withOpacity(0.6),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                stall['message'].toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.white.withOpacity(0.7),
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  Color _getCardBackgroundColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green.withOpacity(0.1);
      case 'rejected':
        return AppTheme.errorRed.withOpacity(0.1);
      case 'pending':
        return Colors.orange.withOpacity(0.1);
      case 'cancelled':
        return Colors.grey.withOpacity(0.1);
      default:
        return AppTheme.white.withOpacity(0.1);
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return 'BOOKED';
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

  Future<void> _createTestStallApplication() async {
    try {
      // Create mock data for testing
      final mockStall = {
        'id': 'mock-stall-1',
        'exhibition': {
          'title': 'Tech Expo 2024',
          'city': 'Mumbai',
          'state': 'Maharashtra',
          'start_date': '2024-12-01',
          'end_date': '2024-12-03',
        },
        'stall': {
          'name': 'Premium A1',
          'length': 4.0,
          'width': 3.0,
          'unit': {'symbol': 'm²'},
          'price': 12000.0,
        },
        'stall_instance': {
          'price': 12000.0,
        },
        'status': 'approved',
        'message': 'This is a test approved stall application',
        'created_at': DateTime.now().toIso8601String(),
      };

      final mockStall2 = {
        'id': 'mock-stall-2',
        'exhibition': {
          'title': 'Design Festival 2024',
          'city': 'Delhi',
          'state': 'Delhi',
          'start_date': '2024-11-15',
          'end_date': '2024-11-17',
        },
        'stall': {
          'name': 'Standard B2',
          'length': 3.0,
          'width': 2.5,
          'unit': {'symbol': 'm²'},
          'price': 8000.0,
        },
        'stall_instance': {
          'price': 8000.0,
        },
        'status': 'pending',
        'message': 'This is a test pending stall application',
        'created_at': DateTime.now().toIso8601String(),
      };

      setState(() {
        _stalls = [mockStall, mockStall2];
        _isLoading = false;
        _isTestMode = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test data loaded! Check All, Pending, and Booked tabs.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading test data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

    Future<void> _clearTestData() async {
    setState(() {
      _isTestMode = false;
      _isLoading = true;
    });
    
    // Go back to real data fetching
    await _loadStalls();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Test data cleared. Loading real data...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showStallDetails(Map<String, dynamic> stall) {
    final exhibition = stall['exhibition'] ?? {};
    final stallDetails = stall['stall'] ?? {};
    final stallInstance = stall['stall_instance'] ?? {};
    final status = stall['status'] ?? 'pending';
    final message = stall['message'] ?? '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.gradientBlack,
                  AppTheme.gradientPink,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _getStatusColor(status).withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with status
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.store,
                        color: _getStatusColor(status),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Stall Details',
                          style: TextStyle(
                            color: AppTheme.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _getStatusColor(status),
                            width: 1,
                          ),
                        ),
                                                  child: Text(
                            _getStatusDisplayText(status),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ),
                    ],
                  ),
                ),
                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Exhibition Info
                        _buildDetailSection(
                          'Exhibition',
                          Icons.event,
                          [
                            exhibition['title'] ?? 'Unknown Exhibition',
                            '${exhibition['city'] ?? ''}, ${exhibition['state'] ?? ''}',
                            '${exhibition['start_date'] != null ? _formatDate(exhibition['start_date']) : ''} - ${exhibition['end_date'] != null ? _formatDate(exhibition['end_date']) : ''}',
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Stall Info
                        _buildDetailSection(
                          'Stall Details',
                          Icons.grid_on,
                          [
                            'Stall ${stallDetails['name'] ?? 'Unknown'}',
                            'Dimensions: ${stallDetails['length'] ?? '0'} x ${stallDetails['width'] ?? '0'} ${stallDetails['unit']?['symbol'] ?? 'm'}',
                            'Price: ₹${stallInstance['price'] ?? stallDetails['price'] ?? '0'}',
                          ],
                        ),
                        if (message.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _buildDetailSection(
                            'Message',
                            Icons.message,
                            [message],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                // Close button
                Container(
                  padding: const EdgeInsets.all(20),
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getStatusColor(status).withOpacity(0.2),
                      foregroundColor: _getStatusColor(status),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(String title, IconData icon, List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: AppTheme.white,
              size: 20,
            ),
            const SizedBox(width: 8),
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
        const SizedBox(height: 12),
        ...details.map((detail) => Padding(
          padding: const EdgeInsets.only(left: 28, bottom: 4),
          child: Text(
            detail,
            style: TextStyle(
              color: AppTheme.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        )),
      ],
    );
  }
}