import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../widgets/exhibition_card.dart';
import '../widgets/brand_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/dynamic_location_selector.dart';


class ShopperExploreScreen extends StatefulWidget {
  const ShopperExploreScreen({super.key});

  @override
  State<ShopperExploreScreen> createState() => _ShopperExploreScreenState();
}

class _ShopperExploreScreenState extends State<ShopperExploreScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService.instance;
  late TabController _tabController;
  
  List<Map<String, dynamic>> _exhibitions = [];
  List<Map<String, dynamic>> _brands = [];
  List<Map<String, dynamic>> _filteredExhibitions = [];
  List<Map<String, dynamic>> _filteredBrands = [];
  
  bool _isLoading = true;
  bool _isLoadingCities = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedLocation = 'Gautam Buddha Nagar';
  String _selectedDateRange = 'All';
  List<String> _availableCities = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAvailableCities();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      print('=== EXPLORE SCREEN: LOADING DATA ===');

      // Load exhibitions with proper status filtering
      var exhibitionsQuery = _supabaseService.client
          .from('exhibitions')
          .select();
      
      // Try to filter by approved status first
      try {
        final approvedExhibitions = await _supabaseService.client
            .from('exhibitions')
            .select()
            .eq('status', 'approved')
            .limit(5);
        
        if (approvedExhibitions.isNotEmpty) {
          exhibitionsQuery = exhibitionsQuery.eq('status', 'approved');
          print('Found approved exhibitions, filtering by status');
        } else {
          print('No approved exhibitions found, loading all');
        }
      } catch (e) {
        print('Error checking approved status: $e');
      }
      
      // Apply location filter if not "All"
      if (_selectedLocation != 'All' && _selectedLocation != 'All Locations') {
        exhibitionsQuery = exhibitionsQuery.eq('city', _selectedLocation);
        print('Filtering by location: $_selectedLocation');
      }
      
      final exhibitionsData = await exhibitionsQuery
          .order('start_date', ascending: true);

      print('Exhibitions loaded: ${exhibitionsData.length}');

      // Load brands
      final brandsData = await _supabaseService.client
          .from('profiles')
          .select()
          .eq('role', 'brand')
          .order('created_at', ascending: false);

      print('Brands loaded: ${brandsData.length}');

      // Convert to proper format
      final exhibitionsList = List<Map<String, dynamic>>.from(exhibitionsData);
      final brandsList = List<Map<String, dynamic>>.from(brandsData);

      // Load user's favorite and attending status for exhibitions
      await _loadUserStatusForExhibitions(exhibitionsList);
      
      // Load user's favorite status for brands
      await _loadUserStatusForBrands(brandsList);

      setState(() {
        _exhibitions = exhibitionsList;
        _brands = brandsList;
        _filteredExhibitions = exhibitionsList;
        _filteredBrands = brandsList;
        _isLoading = false;
      });

      print('=== EXPLORE SCREEN: DATA LOADED ===');
      print('Exhibitions: ${_exhibitions.length}');
      print('Brands: ${_brands.length}');
      
      if (_exhibitions.isNotEmpty) {
        print('Sample exhibition: ${_exhibitions.first}');
      }

    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _loadUserStatusForExhibitions(List<Map<String, dynamic>> exhibitions) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        print('No current user found for status loading');
        return;
      }

      print('Loading status for ${exhibitions.length} exhibitions');

      for (int i = 0; i < exhibitions.length; i++) {
        final exhibition = exhibitions[i];
        final exhibitionId = exhibition['id'];

        // Check favorite status
        final isFavorited = await _supabaseService.isExhibitionFavorited(
          currentUser.id, 
          exhibitionId
        );

        // Check attending status
        final isAttending = await _supabaseService.isExhibitionAttending(
          currentUser.id, 
          exhibitionId
        );

        // Update the exhibition data with status
        exhibitions[i] = {
          ...exhibition,
          'is_favorited': isFavorited,
          'is_attending': isAttending,
        };
      }

      print('Exhibition status loaded successfully');
    } catch (e) {
      print('Error loading user status for exhibitions: $e');
    }
  }

  Future<void> _loadUserStatusForBrands(List<Map<String, dynamic>> brands) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;

      print('Loading status for ${brands.length} brands');

      for (int i = 0; i < brands.length; i++) {
        final brand = brands[i];
        final brandId = brand['id'];

        // Check if brand is favorited using centralized method
        final isFavorited = await _supabaseService.isBrandFavorited(currentUser.id, brandId);

        // Update the brand data with status
        brands[i] = {
          ...brand,
          'is_favorited': isFavorited,
        };
      }

      print('Brand status loaded successfully');
    } catch (e) {
      print('Error loading user status for brands: $e');
    }
  }

  Future<void> _toggleFavorite(String exhibitionId) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;

      await _supabaseService.toggleExhibitionFavorite(
        currentUser.id, 
        exhibitionId
      );

      // Reload data to update UI
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating favorite: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _toggleAttending(String exhibitionId) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) return;

      await _supabaseService.toggleExhibitionAttending(
        currentUser.id, 
        exhibitionId
      );

      // Reload data to update UI
      await _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating attendance: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _toggleBrandFavorite(String brandId) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to favorite brands'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
        return;
      }

      // Use centralized method to toggle brand favorite
      await _supabaseService.toggleBrandFavorite(currentUser.id, brandId);

      // Reload data to update UI
      await _loadData();
      
      // Show success message
      if (mounted) {
        final isFavorited = await _supabaseService.isBrandFavorited(currentUser.id, brandId);
        final message = isFavorited ? 'Added to favorites' : 'Removed from favorites';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating brand favorite: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _loadAvailableCities() async {
    try {
      setState(() {
        _isLoadingCities = true;
      });

      print('=== LOADING CITIES ===');

      // Load cities that have exhibitions
      final citiesData = await _supabaseService.client
          .from('exhibitions')
          .select('city')
          .not('city', 'is', null);

      final cities = citiesData
          .map((item) => item['city'] as String)
          .where((city) => city.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      print('Cities found: $cities');

      // Remove duplicates and ensure proper order
      final uniqueCities = ['All', 'All Locations', 'Gautam Buddha Nagar', ...cities].toSet().toList();
      
      setState(() {
        _availableCities = uniqueCities;
        _isLoadingCities = false;
      });

      print('Available cities: $_availableCities');
    } catch (e) {
      print('Error loading cities: $e');
      setState(() {
        _availableCities = ['All', 'All Locations', 'Gautam Buddha Nagar'];
        _isLoadingCities = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredExhibitions = _exhibitions.where((exhibition) {
        bool matchesSearch = _searchQuery.isEmpty ||
            exhibition['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (exhibition['description'] != null && exhibition['description'].toString().toLowerCase().contains(_searchQuery.toLowerCase()));
        
        bool matchesCategory = _selectedCategory == 'All' ||
            exhibition['category'] == _selectedCategory;
        
        bool matchesLocation = _selectedLocation == 'All' || _selectedLocation == 'All Locations' ||
            exhibition['city'] == _selectedLocation;
        
        return matchesSearch && matchesCategory && matchesLocation;
      }).toList();

      _filteredBrands = _brands.where((brand) {
        return _searchQuery.isEmpty ||
            (brand['company_name'] != null && brand['company_name'].toString().toLowerCase().contains(_searchQuery.toLowerCase())) ||
            (brand['description'] != null && brand['description'].toString().toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    });

    print('Filters applied - Exhibitions: ${_filteredExhibitions.length}, Brands: ${_filteredBrands.length}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      body: SafeArea(
        child: Column(
          children: [
            // Header with search and filter
            _buildHeader(),
            
            // Tab bar
            Container(
              color: AppTheme.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryMaroon,
                unselectedLabelColor: AppTheme.textMediumGray,
                indicatorColor: AppTheme.primaryMaroon,
                tabs: const [
                  Tab(text: 'Exhibitions'),
                  Tab(text: 'Brands'),
                ],
              ),
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildExhibitionsTab(),
                  _buildBrandsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SearchBarWidget(
                  hintText: 'Search exhibitions and brands...',
                  onChanged: (query) {
                    setState(() {
                      _searchQuery = query;
                    });
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _showFilterBottomSheet(),
                icon: Icon(
                  Icons.filter_list,
                  color: AppTheme.primaryMaroon,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Location selector
          DynamicLocationSelector(
            selectedLocation: _selectedLocation,
            availableCities: _availableCities,
            isLoading: _isLoadingCities,
            onLocationChanged: (location) {
              setState(() {
                _selectedLocation = location;
              });
              _loadData(); // Reload data when location changes
            },
            showLabel: false,
          ),
          
          // Quick stats
          if (!_isLoading) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildStatChip(
                  icon: Icons.event,
                  label: 'Exhibitions',
                  count: _filteredExhibitions.length,
                ),
                const SizedBox(width: 12),
                _buildStatChip(
                  icon: Icons.store,
                  label: 'Brands',
                  count: _filteredBrands.length,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required int count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryMaroon.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: AppTheme.primaryMaroon,
          ),
          const SizedBox(width: 4),
          Text(
            '$count $label',
            style: TextStyle(
              color: AppTheme.primaryMaroon,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExhibitionsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
        ),
      );
    }

    if (_filteredExhibitions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppTheme.textMediumGray,
            ),
            const SizedBox(height: 16),
            Text(
              'No exhibitions found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textMediumGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMediumGray,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryMaroon,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredExhibitions.length,
        itemBuilder: (context, index) {
          final exhibition = _filteredExhibitions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ExhibitionCard(
              exhibition: exhibition,
              onTap: () => _navigateToExhibitionDetails(exhibition),
              onFavoriteToggle: () => _toggleFavorite(exhibition['id']),
              onAttendingToggle: () => _toggleAttending(exhibition['id']),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrandsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
        ),
      );
    }

    if (_filteredBrands.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 64,
              color: AppTheme.textMediumGray,
            ),
            const SizedBox(height: 16),
            Text(
              'No brands found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textMediumGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMediumGray,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppTheme.primaryMaroon,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredBrands.length,
        itemBuilder: (context, index) {
          final brand = _filteredBrands[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: BrandCard(
              brand: brand,
              onTap: () {}, // No navigation needed for brands
              onFavoriteToggle: () => _toggleBrandFavorite(brand['id']),
            ),
          );
        },
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterBottomSheet(
        selectedCategory: _selectedCategory,
        selectedLocation: _selectedLocation,
        selectedDateRange: _selectedDateRange,
        onApply: (category, location, dateRange) {
          setState(() {
            _selectedCategory = category;
            _selectedLocation = location;
            _selectedDateRange = dateRange;
          });
          _applyFilters();
          Navigator.pop(context);
        },
      ),
    );
  }

  void _navigateToExhibitionDetails(Map<String, dynamic> exhibition) {
    Navigator.pushNamed(
      context,
      '/shopper-exhibition-details',
      arguments: {'exhibition': exhibition},
    );
  }

  void _navigateToBrandDetails(Map<String, dynamic> brand) {
    // Brand cards are now display-only, no navigation needed
    // This method is kept for compatibility but does nothing
  }
}
