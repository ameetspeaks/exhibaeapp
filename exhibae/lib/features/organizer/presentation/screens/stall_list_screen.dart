import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/routes/app_router.dart';

class StallListScreen extends StatefulWidget {
  final String exhibitionId;

  const StallListScreen({
    super.key,
    required this.exhibitionId,
  });

  @override
  State<StallListScreen> createState() => _StallListScreenState();
}

class _StallListScreenState extends State<StallListScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _stalls = [];
  String? _error;
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadStalls();
  }

  Future<void> _loadStalls() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _supabaseService.client
          .from('stalls')
          .select('''
            *,
            unit:measurement_units(*),
            amenities:stall_amenities!stall_amenities_stall_id_fkey(
              amenity:amenities(*)
            ),
            instances:stall_instances(*)
          ''')
          .eq('exhibition_id', widget.exhibitionId)
          .order('created_at');

      if (mounted) {
        setState(() {
          _stalls = List<Map<String, dynamic>>.from(response);
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

  List<Map<String, dynamic>> get _filteredStalls {
    return _stalls.where((stall) {
      // Search filter
      final matchesSearch = stall['name']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false;
      
      if (!matchesSearch) return false;
      
      // Status filter
      if (_selectedFilter != 'all') {
        final instances = List<Map<String, dynamic>>.from(stall['instances'] ?? []);
        final availableCount = instances.where((i) => i['status'] == 'available').length;
        
        switch (_selectedFilter) {
          case 'available':
            return availableCount > 0;
          case 'booked':
            return availableCount < instances.length;
          case 'full':
            return availableCount == 0;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Stalls',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                AppRouter.stallForm,
                arguments: {'exhibitionId': widget.exhibitionId},
              ).then((result) {
                if (result == true) {
                  _loadStalls();
                }
              });
            },
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
                Icons.add,
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
                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: const TextStyle(color: AppTheme.white),
                    decoration: InputDecoration(
                      hintText: 'Search stalls...',
                      hintStyle: TextStyle(color: AppTheme.white.withOpacity(0.6)),
                      prefixIcon: Icon(Icons.search, color: AppTheme.white.withOpacity(0.6)),
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
                      _buildFilterChip('Available', 'available'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Partially Booked', 'booked'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Fully Booked', 'full'),
                    ],
                  ),
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
                    : _filteredStalls.isEmpty
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
                                    Icons.grid_off,
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
                                  _searchQuery.isNotEmpty
                                      ? 'Try adjusting your search or filters'
                                      : 'Add your first stall to get started',
                                  style: TextStyle(
                                    color: AppTheme.white.withOpacity(0.8),
                                    fontSize: 16,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                if (_searchQuery.isEmpty)
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRouter.stallForm,
                                        arguments: {'exhibitionId': widget.exhibitionId},
                                      ).then((result) {
                                        if (result == true) {
                                          _loadStalls();
                                        }
                                      });
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.white,
                                      foregroundColor: AppTheme.gradientBlack,
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: const Text(
                                      'Add Stall',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredStalls.length,
                            itemBuilder: (context, index) {
                              final stall = _filteredStalls[index];
                              return _buildStallCard(stall);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = selected ? value : 'all';
        });
      },
      backgroundColor: isSelected ? AppTheme.white : AppTheme.white.withOpacity(0.1),
      selectedColor: AppTheme.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.white : AppTheme.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppTheme.gradientBlack : AppTheme.white,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }

  Widget _buildStallCard(Map<String, dynamic> stall) {
    final instances = List<Map<String, dynamic>>.from(stall['instances'] ?? []);
    final availableCount = instances.where((i) => i['status'] == 'available').length;
    final totalCount = instances.length;
    final amenities = List<Map<String, dynamic>>.from(stall['amenities'] ?? []);
    
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
            Navigator.pushNamed(
              context,
              AppRouter.stallDetails,
              arguments: stall,
            ).then((result) {
              if (result == true) {
                _loadStalls();
              }
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                        Icons.grid_on,
                        color: AppTheme.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stall['name'] ?? 'Untitled Stall',
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
                            '${stall['length']}x${stall['width']}${stall['unit']?['symbol'] ?? 'm'}',
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
                        color: availableCount > 0
                            ? Colors.green.withOpacity(0.1)
                            : AppTheme.errorRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: availableCount > 0
                              ? Colors.green.withOpacity(0.2)
                              : AppTheme.errorRed.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        availableCount > 0
                            ? '$availableCount/$totalCount Available'
                            : 'Fully Booked',
                        style: TextStyle(
                          fontSize: 12,
                          color: availableCount > 0
                              ? Colors.green
                              : AppTheme.errorRed,
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
                        Icons.payments,
                        size: 16,
                        color: AppTheme.white.withOpacity(0.8),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '₹${stall['price']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.white,
                        ),
                      ),
                      const Spacer(),
                      if (amenities.isNotEmpty) ...[
                        Icon(
                          Icons.star,
                          size: 16,
                          color: AppTheme.white.withOpacity(0.8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${amenities.length} Amenities',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.white.withOpacity(0.8),
                          ),
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
}
