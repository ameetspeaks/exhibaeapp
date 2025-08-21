import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/widgets/profile_picture_display.dart';
import '../../../../core/widgets/responsive_card.dart';

class BrandProfilesScreen extends StatefulWidget {
  const BrandProfilesScreen({super.key});

  @override
  State<BrandProfilesScreen> createState() => _BrandProfilesScreenState();
}

class _BrandProfilesScreenState extends State<BrandProfilesScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  List<Map<String, dynamic>> _brands = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadBrandProfiles();
  }

  Future<void> _loadBrandProfiles() async {
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

      final brands = await _supabaseService.getBrandProfiles(organizerId: currentUser.id);

      if (mounted) {
        setState(() {
          _brands = brands;
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

  List<Map<String, dynamic>> get _filteredBrands {
    List<Map<String, dynamic>> filtered = _brands;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((brand) {
        final query = _searchQuery.toLowerCase();
        return brand['company_name'].toString().toLowerCase().contains(query) ||
               brand['full_name'].toString().toLowerCase().contains(query) ||
               brand['industry'].toString().toLowerCase().contains(query);
      }).toList();
    }

    // Apply status filter
    if (_selectedFilter != 'all') {
      switch (_selectedFilter) {
        case 'active':
          filtered = filtered.where((brand) => brand['total_applications'] > 0).toList();
          break;
        case 'new':
          filtered = filtered.where((brand) => brand['total_applications'] <= 1).toList();
          break;
        case 'frequent':
          filtered = filtered.where((brand) => brand['total_applications'] >= 5).toList();
          break;
      }
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      appBar: AppBar(
        title: Text(
          'Brand Profiles',
          style: TextStyle(
            color: AppTheme.primaryMaroon,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primaryMaroon),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: AppTheme.primaryMaroon),
            onPressed: () {
              _showSearchDialog();
            },
          ),
        ],
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
                        'Error loading brand profiles',
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
                        onPressed: _loadBrandProfiles,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryMaroon,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBrandProfiles,
                  color: AppTheme.primaryMaroon,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFilterSection(),
                        const SizedBox(height: 20),
                        _buildBrandList(),
                      ],
                    ),
                  ),
                ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Search Brands',
          style: TextStyle(color: AppTheme.primaryMaroon),
        ),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Search by company name, contact, or industry...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
              });
              Navigator.pop(context);
            },
            child: Text('Clear'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryMaroon,
              foregroundColor: Colors.white,
            ),
            child: Text('Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return ResponsiveCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Brands',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryMaroon,
                ),
              ),
              if (_searchQuery.isNotEmpty)
                Chip(
                  label: Text('Search: $_searchQuery'),
                  onDeleted: () {
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('all', 'All'),
              _buildFilterChip('active', 'Active'),
              _buildFilterChip('new', 'New'),
              _buildFilterChip('frequent', 'Frequent'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      backgroundColor: Colors.white,
      selectedColor: AppTheme.primaryMaroon.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryMaroon,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryMaroon : Colors.black,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryMaroon : AppTheme.borderLightGray,
      ),
    );
  }

  Widget _buildBrandList() {
    if (_filteredBrands.isEmpty) {
      return ResponsiveCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.business_outlined,
              size: 48,
              color: AppTheme.primaryMaroon.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No brands found',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Brand profiles will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: _filteredBrands.map((brand) => _buildBrandCard(brand)).toList(),
    );
  }

  Widget _buildBrandCard(Map<String, dynamic> brand) {
    return ResponsiveCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/brand-profile-details',
            arguments: {'brand': brand},
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ProfilePictureDisplay(
                  avatarUrl: brand['avatar_url'],
                  size: 50,
                  backgroundColor: AppTheme.primaryMaroon.withOpacity(0.1),
                  iconColor: AppTheme.primaryMaroon,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        brand['company_name'] ?? 'Unknown Company',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        brand['full_name'] ?? 'Unknown Contact',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryMaroon.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryMaroon,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          brand['industry'] ?? 'Unknown Industry',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primaryMaroon,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppTheme.primaryMaroon,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem('Total', brand['total_applications'].toString(), Icons.apps),
                ),
                Expanded(
                  child: _buildStatItem('Approved', brand['approved_applications'].toString(), Icons.check_circle),
                ),
                Expanded(
                  child: _buildStatItem('Pending', brand['pending_applications'].toString(), Icons.pending),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    brand['location'] ?? 'Location not specified',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withOpacity(0.6),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Last: ${brand['last_activity']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryMaroon,
          size: 16,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryMaroon,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.black.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}
