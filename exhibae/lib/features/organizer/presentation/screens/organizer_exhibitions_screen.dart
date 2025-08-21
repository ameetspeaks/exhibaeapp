import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/responsive_card.dart';

class OrganizerExhibitionsScreen extends StatefulWidget {
  const OrganizerExhibitionsScreen({super.key});

  @override
  State<OrganizerExhibitionsScreen> createState() => _OrganizerExhibitionsScreenState();
}

class _OrganizerExhibitionsScreenState extends State<OrganizerExhibitionsScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _exhibitions = [];
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadExhibitions();
  }

  Future<void> _loadExhibitions() async {
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
        // Continue loading exhibitions even if this fails
        print('Error checking completed exhibitions: $e');
      }

      // Use getOrganizerExhibitions to get all exhibitions for this organizer
      final organizerExhibitions = await _supabaseService.getOrganizerExhibitions(userId);

      if (mounted) {
        setState(() {
          _exhibitions = organizerExhibitions;
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

  List<Map<String, dynamic>> get _filteredExhibitions {
    return _exhibitions.where((exhibition) {
      final matchesSearch = exhibition['title']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      
      if (!matchesSearch) return false;
      
      switch (_selectedFilter) {
        case 'active':
          return exhibition['status'] == 'published' || exhibition['status'] == 'live';
        case 'upcoming':
          return exhibition['status'] == 'draft';
        case 'past':
          return exhibition['status'] == 'completed';
        default:
          return true;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundPeach,
        elevation: 0,
        title: const Text(
          'My Exhibitions',
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              try {
                // Check and update completed exhibitions
                await _supabaseService.checkAndUpdateCompletedExhibitions();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Completed exhibitions updated'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Reload exhibitions
                _loadExhibitions();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error updating exhibitions: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
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
              child: const Icon(
                Icons.refresh,
                color: AppTheme.primaryMaroon,
              ),
            ),
            tooltip: 'Update Completed Exhibitions',
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              _createNewExhibition();
            },
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
              child: const Icon(
                Icons.add,
                color: AppTheme.primaryMaroon,
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
                      hintText: 'Search exhibitions...',
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
                      _buildFilterChip('Active', 'active'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Upcoming', 'upcoming'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Past', 'past'),
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
                              'Error loading exhibitions',
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
                              onPressed: _loadExhibitions,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryMaroon,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredExhibitions.isEmpty
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
                                    Icons.explore_outlined,
                                    size: 80,
                                    color: AppTheme.primaryMaroon,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                Text(
                                  'No Exhibitions Found',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Create your first exhibition to get started.',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.black.withOpacity(0.8),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _createNewExhibition,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryMaroon,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create Exhibition'),
                                ),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadExhibitions,
                            color: AppTheme.primaryMaroon,
                            backgroundColor: AppTheme.backgroundPeach,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredExhibitions.length,
                              itemBuilder: (context, index) {
                                final exhibition = _filteredExhibitions[index];
                                return _buildExhibitionCard(exhibition);
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
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: AppTheme.backgroundPeach,
      selectedColor: AppTheme.primaryMaroon,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppTheme.primaryMaroon : AppTheme.borderLightGray,
        width: 1,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildExhibitionCard(Map<String, dynamic> exhibition) {
    final status = exhibition['status'] ?? 'draft';
    
    // Debug: Print status to see what we're working with
          // Status logging removed
    
    final startDate = exhibition['start_date'] != null
        ? DateTime.parse(exhibition['start_date'])
        : null;
    final endDate = exhibition['end_date'] != null
        ? DateTime.parse(exhibition['end_date'])
        : null;
    
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

    // Set background color based on status
    Color getCardBackgroundColor() {
      Color backgroundColor;
      switch (status) {
        case 'published':
          backgroundColor = const Color(0xFFF0FDF4); // Light green background for published status
          break;
        case 'draft':
          backgroundColor = const Color(0xFFFEFCE8); // Light amber background for draft status
          break;
        case 'completed':
          backgroundColor = const Color(0xFFEFF6FF); // Light blue background for completed status
          break;
        case 'cancelled':
          backgroundColor = const Color(0xFFFEF2F2); // Light red background for cancelled status
          break;
        default:
          backgroundColor = AppTheme.white;
          break;
      }
      
      // Background color calculated based on status
      
      return backgroundColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: getCardBackgroundColor(),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: status == 'draft' ? const Color(0xFFFACC15) : AppTheme.borderLightGray,
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
          onTap: () => _showExhibitionDetails(exhibition),
          borderRadius: BorderRadius.circular(12),
                      child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status indicator bar at the top
                  Container(
                    width: double.infinity,
                    height: 4,
                    decoration: BoxDecoration(
                      color: getStatusColor(),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Status indicator removed
                  const SizedBox(height: 4),
                  Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exhibition['title'] ?? 'Untitled Exhibition',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            exhibition['location'] ?? 'Location not specified',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black.withOpacity(0.7),
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
                          color: getStatusColor(),
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
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                                     decoration: BoxDecoration(
                     color: status == 'published'
                         ? const Color(0xFFF0FDF4).withOpacity(0.3) // Light green for published
                         : status == 'draft' 
                             ? const Color(0xFFFEFCE8).withOpacity(0.3) // Light amber for draft
                             : status == 'completed'
                                 ? const Color(0xFFEFF6FF).withOpacity(0.3) // Light blue for completed
                                 : status == 'cancelled'
                                     ? const Color(0xFFFEF2F2).withOpacity(0.3) // Light red for cancelled
                                     : AppTheme.backgroundPeach.withOpacity(0.3), // Default peach
                     borderRadius: BorderRadius.circular(8),
                   ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          Icons.calendar_today,
                          'Date',
                          startDate != null && endDate != null
                              ? '${startDate.day}/${startDate.month} - ${endDate.day}/${endDate.month}'
                              : 'Not set',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        color: AppTheme.borderLightGray,
                      ),
                      Expanded(
                        child: _buildStatItem(
                          Icons.people,
                          'Applications',
                          '${exhibition['application_count'] ?? 0}',
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        color: AppTheme.white.withOpacity(0.1),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          Icons.grid_on,
                          'Stalls',
                          '${exhibition['stall_count'] ?? 0}',
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: AppTheme.primaryMaroon.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.primaryMaroon.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  void _showExhibitionDetails(Map<String, dynamic> exhibition) async {
    // Safety check for exhibition data
    if (exhibition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exhibition data not available'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    // Debug: Print exhibition data structure
    print('Exhibition data keys: ${exhibition.keys.toList()}');
    print('Exhibition status: ${exhibition['status']}');

    // Fetch real stall applications data
    List<Map<String, dynamic>> stallApplications = [];
    try {
      final exhibitionId = exhibition['id']?.toString();
      if (exhibitionId != null) {
        stallApplications = await _supabaseService.getStallApplicationsByExhibition(exhibitionId);
        print('Fetched ${stallApplications.length} stall applications for exhibition $exhibitionId');
      }
    } catch (e) {
      print('Error fetching stall applications: $e');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.gradientBlack,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _safeGetString(exhibition['title'], 'Untitled Exhibition'),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.white,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _safeGetString(exhibition['address'], 'Location not specified'),
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
                        color: _getStatusColor(_safeGetString(exhibition['status'], 'draft')).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getStatusColor(_safeGetString(exhibition['status'], 'draft')).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getStatusDisplayText(_safeGetString(exhibition['status'], 'draft')),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(_safeGetString(exhibition['status'], 'draft')),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Basic Info Section
                      _buildInfoSection(
                        'Basic Information',
                        [
                          _buildInfoRow('Description', _safeGetString(exhibition['description'], 'No description available')),
                          _buildInfoRow('Start Date', _safeGetDate(exhibition['start_date'])),
                          _buildInfoRow('End Date', _safeGetDate(exhibition['end_date'])),
                          _buildInfoRow('Category', _getCategoryName(exhibition['category'])),
                          _buildInfoRow('Organizer', _safeGetEmail(exhibition['organiser'])),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Statistics Section
                      _buildInfoSection(
                        'Statistics',
                        [
                          _buildInfoRow('Total Applications', '${stallApplications.length}'),
                          _buildInfoRow('Total Stalls', _safeGetString(exhibition['stall_count'], '0')),
                          _buildInfoRow('Booked Stalls', '${stallApplications.where((app) => app['status'] == 'booked').length}'),
                          _buildInfoRow('Pending Applications', '${stallApplications.where((app) => app['status'] == 'pending').length}'),
                          _buildInfoRow('Revenue Generated', '₹${_safeGetString(exhibition['total_revenue'], '0')}'),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Applications Section - Real Data
                      _buildApplicationsSectionWithRealData(stallApplications),

                      const SizedBox(height: 20),

                      // Stalls Section - Real Data
                      _buildStallsSectionWithRealData(stallApplications),

                      const SizedBox(height: 20),

                      // Payment Section - Real Data
                      _buildPaymentSectionWithRealData(stallApplications),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),

                             // Action Buttons
               Padding(
                 padding: const EdgeInsets.all(20),
                 child: Row(
                   children: [
                     Expanded(
                       child: ElevatedButton(
                         onPressed: _canEditExhibition(exhibition) ? () {
                           Navigator.pop(context);
                           _editExhibition(exhibition);
                         } : null,
                         style: ElevatedButton.styleFrom(
                           backgroundColor: _canEditExhibition(exhibition) 
                               ? AppTheme.white.withOpacity(0.1)
                               : AppTheme.white.withOpacity(0.05),
                           foregroundColor: _canEditExhibition(exhibition) 
                               ? AppTheme.white
                               : AppTheme.white.withOpacity(0.5),
                           padding: const EdgeInsets.symmetric(vertical: 14),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(12),
                             side: BorderSide(
                               color: _canEditExhibition(exhibition) 
                                   ? AppTheme.white.withOpacity(0.3)
                                   : AppTheme.white.withOpacity(0.1),
                             ),
                           ),
                         ),
                         child: Text(
                           _canEditExhibition(exhibition) ? 'Edit Exhibition' : 'Cannot Edit',
                           style: TextStyle(
                             fontSize: 15, 
                             fontWeight: FontWeight.w600,
                             color: _canEditExhibition(exhibition) 
                                 ? AppTheme.white
                                 : AppTheme.white.withOpacity(0.5),
                           ),
                         ),
                       ),
                     ),
                     const SizedBox(width: 16),
                     Expanded(
                       child: ElevatedButton(
                         onPressed: () {
                           Navigator.pop(context);
                           _viewApplications(exhibition);
                         },
                         style: ElevatedButton.styleFrom(
                           backgroundColor: AppTheme.white,
                           foregroundColor: AppTheme.gradientBlack,
                           padding: const EdgeInsets.symmetric(vertical: 14),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(12),
                           ),
                         ),
                         child: const Text(
                           'View Applications',
                           style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                         ),
                       ),
                     ),
                   ],
                 ),
               ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null || status.isEmpty) return Colors.grey;
    
    switch (status.toLowerCase()) {
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
      // Stall application statuses
      case 'pending':
        return Colors.orange;
      case 'payment_pending':
        return Colors.amber;
      case 'payment_review':
        return Colors.blue;
      case 'booked':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayText(String? status) {
    if (status == null || status.isEmpty) return 'DRAFT';
    
    switch (status.toLowerCase()) {
      case 'draft':
        return 'PENDING FOR APPROVAL';
      default:
        return status.toUpperCase();
    }
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.white.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editExhibition(Map<String, dynamic> exhibition) {
    // Safety check for exhibition data
    if (exhibition == null || exhibition.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot edit: Exhibition data not available'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    // Check if exhibition can be edited
    if (!_canEditExhibition(exhibition)) {
      final status = exhibition['status']?.toString().toUpperCase() ?? 'UNKNOWN';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot edit: Exhibition is $status'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    // Navigate to exhibition form with existing data
    Navigator.pushNamed(
      context,
      '/exhibition-form',
      arguments: {
        'exhibition': exhibition,
        'isEditing': true,
      },
    );
  }

  void _viewApplications(Map<String, dynamic> exhibition) {
    // Safety check for exhibition data
    if (exhibition == null || exhibition.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot view applications: Exhibition data not available'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    // Navigate to applications list filtered for this exhibition
    Navigator.pushNamed(
      context,
      '/applications',
      arguments: {
        'exhibitionId': _safeGetString(exhibition['id'], ''),
        'exhibitionTitle': _safeGetString(exhibition['title'], 'Unknown Exhibition'),
      },
    );
  }

  void _createNewExhibition() {
    Navigator.pushNamed(
      context,
      '/exhibition-form',
      arguments: {
        'isEditing': false,
      },
    );
  }

  // Check if an exhibition can be edited
  bool _canEditExhibition(Map<String, dynamic> exhibition) {
    final status = exhibition['status']?.toString().toLowerCase() ?? 'draft';
    // Only allow editing for draft, published, and live statuses
    return status == 'draft' || status == 'published' || status == 'live';
  }

  // Null safety helper methods
  String _safeGetString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    
    try {
      if (value is String) return value.isEmpty ? defaultValue : value;
      if (value is Map) return value.toString();
      if (value is num) return value.toString();
      if (value is bool) return value.toString();
      if (value is List) return value.isEmpty ? defaultValue : value.toString();
      
      final stringValue = value.toString();
      return stringValue.isEmpty ? defaultValue : stringValue;
    } catch (e) {
      print('Error in _safeGetString: $e');
      return defaultValue;
    }
  }

  String _safeGetDate(dynamic dateValue) {
    if (dateValue == null) return 'Not set';
    try {
      if (dateValue is String) {
        final date = DateTime.parse(dateValue);
        return '${date.day}/${date.month}/${date.year}';
      }
      return 'Invalid date';
    } catch (e) {
      return 'Invalid date';
    }
  }

  String _safeGetEmail(dynamic userValue) {
    if (userValue == null) return 'Unknown';
    if (userValue is Map) {
      return userValue['email']?.toString() ?? 'Unknown';
    }
    if (userValue is String) return userValue;
    return 'Unknown';
  }

  String _getCategoryName(dynamic categoryValue) {
    if (categoryValue == null) return 'Not specified';
    
    if (categoryValue is Map) {
      return categoryValue['name']?.toString() ?? 'Unknown Category';
    }
    
    if (categoryValue is String) {
      // Map common category values to readable names
      switch (categoryValue.toLowerCase()) {
        case 'fashion':
          return 'Fashion & Apparel';
        case 'technology':
          return 'Technology & Electronics';
        case 'food':
          return 'Food & Beverages';
        case 'art':
          return 'Art & Culture';
        case 'automotive':
          return 'Automotive';
        case 'health':
          return 'Health & Wellness';
        case 'education':
          return 'Education & Training';
        case 'real_estate':
          return 'Real Estate';
        case 'tourism':
          return 'Tourism & Travel';
        case 'sports':
          return 'Sports & Fitness';
        case 'beauty':
          return 'Beauty & Personal Care';
        case 'home':
          return 'Home & Lifestyle';
        default:
          // Capitalize first letter and replace underscores with spaces
          return categoryValue.split('_').map((word) => 
            word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}' : ''
          ).join(' ');
      }
    }
    
    return 'Unknown Category';
  }

  Widget _buildApplicationsSection(Map<String, dynamic> exhibition) {
    return _buildInfoSection(
      'Recent Applications',
      [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No applications yet',
            style: TextStyle(
              color: AppTheme.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStallsSection(Map<String, dynamic> exhibition) {
    return _buildInfoSection(
      'Stall Information',
      [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No stalls configured yet',
            style: TextStyle(
              color: AppTheme.white.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection(Map<String, dynamic> exhibition) {
    return _buildInfoSection(
      'Payment Summary',
      [
        _buildPaymentRow('Total Revenue', '₹0', true),
        _buildPaymentRow('Pending Payments', '₹0', false),
        _buildPaymentRow('Completed Payments', '₹0', false),
        _buildPaymentRow('Commission (10%)', '₹0', false),
        _buildPaymentRow('Net Revenue', '₹0', true),
      ],
    );
  }

  Widget _buildPaymentRow(String label, String amount, bool isTotal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              color: AppTheme.white.withOpacity(isTotal ? 1.0 : 0.7),
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            amount,
            style: TextStyle(
              fontSize: isTotal ? 17 : 15,
              color: AppTheme.white,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationsSectionWithRealData(List<Map<String, dynamic>> stallApplications) {
    return _buildInfoSection(
      'Recent Applications',
      [
        if (stallApplications.isNotEmpty)
          ...stallApplications.map((app) => _buildApplicationCard(app)).toList()
        else
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No applications yet',
              style: TextStyle(
                color: AppTheme.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> application) {
    final status = application['status'] ?? 'pending';
    final brand = application['brand'] as Map<String, dynamic>?;
    final stall = application['stall'] as Map<String, dynamic>?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _safeGetString(brand?['company_name'] ?? brand?['full_name'], 'Unknown Brand'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _safeGetString(stall?['name'], 'Unknown Stall'),
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.white.withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _safeGetDate(application['created_at']),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(application['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(application['status']).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              _safeGetString(application['status'], 'pending').toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                color: _getStatusColor(application['status']),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStallsSectionWithRealData(List<Map<String, dynamic>> stallApplications) {
    return _buildInfoSection(
      'Stall Information',
      [
        if (stallApplications.isNotEmpty)
          ...stallApplications.map((app) => _buildStallCard(app)).toList()
        else
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'No stalls configured yet',
              style: TextStyle(
                color: AppTheme.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStallCard(Map<String, dynamic> application) {
    final status = application['status'] ?? 'pending';
    final stall = application['stall'] as Map<String, dynamic>?;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _safeGetString(stall?['name'], 'Unknown Stall'),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_safeGetString(stall?['width'], '3')}m × ${_safeGetString(stall?['length'], '3')}m',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${_safeGetString(stall?['price'], '0')}',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.white.withOpacity(0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: _getStatusColor(application['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(application['status']).withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              _safeGetString(application['status'], 'pending').toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                color: _getStatusColor(application['status']),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSectionWithRealData(List<Map<String, dynamic>> stallApplications) {
    // Calculate payment data based on stall applications
    double totalRevenue = 0.0;
    double pendingPayments = 0.0;
    double completedPayments = 0.0;
    
    for (final application in stallApplications) {
      final stall = application['stall'] as Map<String, dynamic>?;
      final price = double.tryParse(_safeGetString(stall?['price'], '0')) ?? 0.0;
      
      if (application['status'] == 'booked') {
        totalRevenue += price;
        completedPayments += price;
      } else if (application['status'] == 'payment_pending' || application['status'] == 'payment_review') {
        totalRevenue += price;
        pendingPayments += price;
      }
    }
    
    final commissionRate = 0.10; // 10% commission
    final commission = totalRevenue * commissionRate;
    final netRevenue = totalRevenue - commission;
    
    return _buildInfoSection(
      'Payment Summary',
      [
        _buildPaymentRow('Total Revenue', '₹${totalRevenue.toStringAsFixed(0)}', true),
        _buildPaymentRow('Pending Payments', '₹${pendingPayments.toStringAsFixed(0)}', false),
        _buildPaymentRow('Completed Payments', '₹${completedPayments.toStringAsFixed(0)}', false),
        _buildPaymentRow('Commission (10%)', '₹${commission.toStringAsFixed(0)}', false),
        _buildPaymentRow('Net Revenue', '₹${netRevenue.toStringAsFixed(0)}', true),
      ],
    );
  }

}
