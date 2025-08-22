import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../widgets/exhibition_card.dart';
import '../widgets/brand_card.dart';


class ShopperFavoritesScreen extends StatefulWidget {
  const ShopperFavoritesScreen({super.key});

  @override
  State<ShopperFavoritesScreen> createState() => _ShopperFavoritesScreenState();
}

class _ShopperFavoritesScreenState extends State<ShopperFavoritesScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseService _supabaseService = SupabaseService.instance;
  late TabController _tabController;
  
  List<Map<String, dynamic>> _favoriteExhibitions = [];
  List<Map<String, dynamic>> _favoriteBrands = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final userId = _supabaseService.currentUser?.id;
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please log in to view your favorites'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
        return;
      }

      // Load favorite exhibitions using centralized method
      final favoriteExhibitionsData = await _supabaseService.getExhibitionFavorites(userId);

      print('Raw favorite exhibitions data: $favoriteExhibitionsData');

      // Process favorite exhibitions to add stall availability data
      final processedFavoriteExhibitions = await Future.wait(favoriteExhibitionsData.map((item) async {
        final exhibition = item['exhibition'] as Map<String, dynamic>?;
        if (exhibition == null) return <String, dynamic>{};
        
        // Get available stall instances count
        int availableStalls = 0;
        try {
          availableStalls = await _supabaseService.getAvailableStallInstancesCount(exhibition['id']);
        } catch (e) {
          print('Error fetching stall instances for exhibition ${exhibition['id']}: $e');
        }
        
        // Update the exhibition data with stall availability
        final updatedExhibition = {
          ...exhibition,
          'is_favorited': true,
          'availableStalls': availableStalls,
        };
        
        return updatedExhibition;
      }));

      // Load favorite brands using centralized method
      final favoriteBrandsData = await _supabaseService.getUserFavoriteBrands(userId);

      print('Raw favorite brands data: $favoriteBrandsData');
      print('Raw favorite brands data length: ${favoriteBrandsData.length}');
      
      if (favoriteBrandsData.isNotEmpty) {
        print('Sample raw brand data structure: ${favoriteBrandsData.first.keys}');
        print('Sample raw brand data: ${favoriteBrandsData.first}');
      }
      
      // Test: Check if there are any brand favorites in the database
      try {
        final testBrandFavorites = await _supabaseService.client
            .from('brand_favorites')
            .select('*')
            .eq('user_id', userId);
        print('Test: Found ${testBrandFavorites.length} brand favorites in database for user $userId');
        if (testBrandFavorites.isNotEmpty) {
          print('Test: Sample brand favorite record: ${testBrandFavorites.first}');
        }
      } catch (e) {
        print('Test: Error checking brand favorites: $e');
      }

      setState(() {
        _favoriteExhibitions = List<Map<String, dynamic>>.from(
          processedFavoriteExhibitions.map((item) => item),
        );
        
        _favoriteBrands = List<Map<String, dynamic>>.from(
          favoriteBrandsData.map((item) {
            print('Processing brand item: $item');
            final brand = item['brand'] as Map<String, dynamic>?;
            print('Extracted brand: $brand');
            if (brand != null) {
              brand['is_favorited'] = true;
              print('Added is_favorited flag to brand');
              return brand;
            }
            print('Brand is null, returning empty map');
            return <String, dynamic>{};
          }).where((brand) => brand.isNotEmpty),
        );
        
        _isLoading = false;
      });

      print('Processed favorite exhibitions: ${_favoriteExhibitions.length}');
      print('Processed favorite brands: ${_favoriteBrands.length}');
      
      if (_favoriteExhibitions.isNotEmpty) {
        print('Sample processed exhibition: ${_favoriteExhibitions.first}');
      }
                    if (_favoriteBrands.isNotEmpty) {
         print('Sample processed brand: ${_favoriteBrands.first}');
       } else {
         print('No favorite brands found. Raw data length: ${favoriteBrandsData.length}');
         if (favoriteBrandsData.isNotEmpty) {
           print('Sample raw brand data: ${favoriteBrandsData.first}');
         }
       }
    } catch (e) {
      print('Error in _loadFavorites: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading favorites: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _removeExhibitionFavorite(Map<String, dynamic> exhibition) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;

      // Use centralized method to remove exhibition favorite
      await _supabaseService.toggleExhibitionFavorite(userId, exhibition['id']);

      setState(() {
        _favoriteExhibitions.removeWhere((e) => e['id'] == exhibition['id']);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing from favorites: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _removeBrandFavorite(Map<String, dynamic> brand) async {
    try {
      final userId = _supabaseService.currentUser?.id;
      if (userId == null) return;

      // Use centralized method to remove brand favorite
      await _supabaseService.toggleBrandFavorite(userId, brand['id']);

      setState(() {
        _favoriteBrands.removeWhere((b) => b['id'] == brand['id']);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Removed from favorites'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing from favorites: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            // Tab bar
            Container(
              color: AppTheme.white,
              child: TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryMaroon,
                unselectedLabelColor: AppTheme.textMediumGray,
                indicatorColor: AppTheme.primaryMaroon,
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Exhibitions'),
                        if (_favoriteExhibitions.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_favoriteExhibitions.length}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Brands'),
                        if (_favoriteBrands.isNotEmpty) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.accentGold,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_favoriteBrands.length}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
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
      color: AppTheme.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back,
              color: AppTheme.primaryMaroon,
            ),
          ),
          Expanded(
            child: Text(
              'My Favorites',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.primaryMaroon,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            onPressed: _loadFavorites,
            icon: Icon(
              Icons.refresh,
              color: AppTheme.primaryMaroon,
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

    if (_favoriteExhibitions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: AppTheme.textMediumGray,
            ),
            const SizedBox(height: 16),
            Text(
              'No favorite exhibitions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textMediumGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start exploring exhibitions and add them to your favorites',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/explore');
              },
              child: const Text('Explore Exhibitions'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: AppTheme.primaryMaroon,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteExhibitions.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: ExhibitionCard(
              exhibition: _favoriteExhibitions[index],
              onTap: () => _navigateToExhibitionDetails(_favoriteExhibitions[index]),
              onFavoriteToggle: () => _removeExhibitionFavorite(_favoriteExhibitions[index]),
              onAttendingToggle: () {
                // Handle attending toggle if needed
              },
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

    if (_favoriteBrands.isEmpty) {
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
              'No favorite brands',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.textMediumGray,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start exploring brands and add them to your favorites',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textMediumGray,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/explore');
              },
              child: const Text('Explore Brands'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadFavorites,
      color: AppTheme.primaryMaroon,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _favoriteBrands.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: BrandCard(
              brand: _favoriteBrands[index],
              onTap: () => _navigateToBrandDetails(_favoriteBrands[index]),
              onFavoriteToggle: () => _removeBrandFavorite(_favoriteBrands[index]),
            ),
          );
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
    // TODO: Implement brand details screen for shoppers
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Brand details coming soon!'),
        backgroundColor: AppTheme.primaryMaroon,
      ),
    );
  }
}
