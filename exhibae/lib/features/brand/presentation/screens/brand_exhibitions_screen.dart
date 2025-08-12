import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../widgets/exhibition_card.dart';

class BrandExhibitionsScreen extends StatefulWidget {
  const BrandExhibitionsScreen({super.key});

  @override
  State<BrandExhibitionsScreen> createState() => _BrandExhibitionsScreenState();
}

class _BrandExhibitionsScreenState extends State<BrandExhibitionsScreen> {
  bool _isLoading = false;
  bool _isGridView = false;
  List<Map<String, dynamic>> _exhibitions = [];
  final SupabaseService _supabaseService = SupabaseService.instance;
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedEventType = 'All';
  String _selectedLocation = 'All';

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _eventTypes = [];
  List<Map<String, dynamic>> _venueTypes = [];
  String _selectedVenueType = 'All';
  
  final List<String> _cities = [
    'All',
    'Delhi',
    'Mumbai',
    'Bangalore',
    'Pune',
    'Chennai',
    'Hyderabad',
    'Kolkata',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final futures = await Future.wait([
        _supabaseService.getExhibitionCategories(),
        _supabaseService.getEventTypes(),
        _supabaseService.getVenueTypes(),
        _supabaseService.getExhibitions(),
      ]);

      if (mounted) {
        // Process the exhibitions data to add required fields
        final rawExhibitions = List<Map<String, dynamic>>.from(futures[3]);
        final processedExhibitions = rawExhibitions.map((exhibition) {
          final startDate = exhibition['start_date'] != null 
            ? DateTime.parse(exhibition['start_date'])
            : DateTime.now();
          final endDate = exhibition['end_date'] != null 
            ? DateTime.parse(exhibition['end_date'])
            : DateTime.now();
          final formattedDate = '${_formatDate(startDate)} - ${_formatDate(endDate)}';
          
          final images = List<String>.from(exhibition['images'] ?? []);
          final imageUrl = images.isNotEmpty 
            ? _supabaseService.getPublicUrl('exhibition-images', images.first)
            : null;
          
          return {
            ...exhibition,
            'date': formattedDate,
            'image_url': imageUrl,
            'amenities': List<String>.from(exhibition['amenities'] ?? []),
            'venue_details': exhibition['venue_details'] ?? {},
            'isFavorite': false, // Add default favorite status
            'availableStalls': exhibition['available_stalls'] ?? 0, // Add available stalls count
            'priceRange': exhibition['price_range'] ?? 'Contact for pricing', // Add price range
            'location': exhibition['city'] ?? 'Location not specified', // Add location field
          };
        }).toList();

        setState(() {
          _categories = List<Map<String, dynamic>>.from(futures[0]);
          _eventTypes = List<Map<String, dynamic>>.from(futures[1]);
          _venueTypes = List<Map<String, dynamic>>.from(futures[2]);
          _exhibitions = processedExhibitions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading data: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExhibitions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final exhibitions = await _supabaseService.getExhibitions();
      
      // Process the exhibitions data and fetch stall counts
      final processedExhibitions = await Future.wait(exhibitions.map((exhibition) async {
        final startDate = exhibition['start_date'] != null 
          ? DateTime.parse(exhibition['start_date'])
          : DateTime.now();
        final endDate = exhibition['end_date'] != null 
          ? DateTime.parse(exhibition['end_date'])
          : DateTime.now();
        final formattedDate = '${_formatDate(startDate)} - ${_formatDate(endDate)}';
        
        final images = List<String>.from(exhibition['images'] ?? []);
        final imageUrl = images.isNotEmpty 
          ? _supabaseService.getPublicUrl('exhibition-images', images.first)
          : null;
        
        // Fetch actual stall count for this exhibition
        int availableStalls = 0;
        try {
          final stalls = await _supabaseService.getStallsByExhibition(exhibition['id']);
          availableStalls = stalls.where((stall) {
            final instances = stall['instances'] as List<dynamic>?;
            if (instances != null && instances.isNotEmpty) {
              return instances.any((instance) => instance['status'] == 'available');
            }
            return stall['status'] == 'available';
          }).length;
        } catch (e) {
          print('Error fetching stalls for exhibition ${exhibition['id']}: $e');
        }
        
        // Check if this exhibition is favorited by the current user
        bool isFavorite = false;
        try {
          final currentUser = _supabaseService.currentUser;
          if (currentUser != null) {
            isFavorite = await _supabaseService.isExhibitionFavorited(currentUser.id, exhibition['id']);
          }
        } catch (e) {
          print('Error checking favorite status: $e');
        }
        
        return {
          ...exhibition,
          'date': formattedDate,
          'image_url': imageUrl,
          'amenities': List<String>.from(exhibition['amenities'] ?? []),
          'venue_details': exhibition['venue_details'] ?? {},
          'isFavorite': isFavorite,
          'availableStalls': availableStalls,
          'priceRange': exhibition['price_range'] ?? null,
          'location': exhibition['city'] ?? 'Location not specified',
        };
      }));

      setState(() {
        _exhibitions = processedExhibitions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading exhibitions: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _searchExhibitions() async {
    if (_searchController.text.trim().isEmpty) {
      _loadExhibitions();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final exhibitions = await _supabaseService.searchExhibitions(_searchController.text.trim());
      
      // Process the exhibitions data and fetch stall counts
      final processedExhibitions = await Future.wait(exhibitions.map((exhibition) async {
        final startDate = exhibition['start_date'] != null 
          ? DateTime.parse(exhibition['start_date'])
          : DateTime.now();
        final endDate = exhibition['end_date'] != null 
          ? DateTime.parse(exhibition['end_date'])
          : DateTime.now();
        final formattedDate = '${_formatDate(startDate)} - ${_formatDate(endDate)}';
        
        final images = List<String>.from(exhibition['images'] ?? []);
        final imageUrl = images.isNotEmpty 
          ? _supabaseService.getPublicUrl('exhibition-images', images.first)
          : null;
        
        // Fetch actual stall count for this exhibition
        int availableStalls = 0;
        try {
          final stalls = await _supabaseService.getStallsByExhibition(exhibition['id']);
          availableStalls = stalls.where((stall) {
            final instances = stall['instances'] as List<dynamic>?;
            if (instances != null && instances.isNotEmpty) {
              return instances.any((instance) => instance['status'] == 'available');
            }
            return stall['status'] == 'available';
          }).length;
        } catch (e) {
          print('Error fetching stalls for exhibition ${exhibition['id']}: $e');
        }
        
        // Check if this exhibition is favorited by the current user
        bool isFavorite = false;
        try {
          final currentUser = _supabaseService.currentUser;
          if (currentUser != null) {
            isFavorite = await _supabaseService.isExhibitionFavorited(currentUser.id, exhibition['id']);
          }
        } catch (e) {
          print('Error checking favorite status: $e');
        }
        
        return {
          ...exhibition,
          'date': formattedDate,
          'image_url': imageUrl,
          'amenities': List<String>.from(exhibition['amenities'] ?? []),
          'venue_details': exhibition['venue_details'] ?? {},
          'isFavorite': isFavorite,
          'availableStalls': availableStalls,
          'priceRange': exhibition['price_range'] ?? null,
          'location': exhibition['city'] ?? 'Location not specified',
        };
      }).toList());

      setState(() {
        _exhibitions = processedExhibitions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching exhibitions: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _filterExhibitions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final exhibitions = await _supabaseService.filterExhibitions(
        categoryId: _selectedCategory == 'All' ? null : _selectedCategory,
        city: _selectedLocation == 'All' ? null : _selectedLocation,
      );
      
      // Process the exhibitions data and fetch stall counts
      final processedExhibitions = await Future.wait(exhibitions.map((exhibition) async {
        final startDate = exhibition['start_date'] != null 
          ? DateTime.parse(exhibition['start_date'])
          : DateTime.now();
        final endDate = exhibition['end_date'] != null 
          ? DateTime.parse(exhibition['end_date'])
          : DateTime.now();
        final formattedDate = '${_formatDate(startDate)} - ${_formatDate(endDate)}';
        
        final images = List<String>.from(exhibition['images'] ?? []);
        final imageUrl = images.isNotEmpty 
          ? _supabaseService.getPublicUrl('exhibition-images', images.first)
          : null;
        
        // Fetch actual stall count for this exhibition
        int availableStalls = 0;
        try {
          final stalls = await _supabaseService.getStallsByExhibition(exhibition['id']);
          availableStalls = stalls.where((stall) {
            final instances = stall['instances'] as List<dynamic>?;
            if (instances != null && instances.isNotEmpty) {
              return instances.any((instance) => instance['status'] == 'available');
            }
            return stall['status'] == 'available';
          }).length;
        } catch (e) {
          print('Error fetching stalls for exhibition ${exhibition['id']}: $e');
        }
        
        // Check if this exhibition is favorited by the current user
        bool isFavorite = false;
        try {
          final currentUser = _supabaseService.currentUser;
          if (currentUser != null) {
            isFavorite = await _supabaseService.isExhibitionFavorited(currentUser.id, exhibition['id']);
          }
        } catch (e) {
          print('Error checking favorite status: $e');
        }
        
        return {
          ...exhibition,
          'date': formattedDate,
          'image_url': imageUrl,
          'amenities': List<String>.from(exhibition['amenities'] ?? []),
          'venue_details': exhibition['venue_details'] ?? {},
          'isFavorite': isFavorite,
          'availableStalls': availableStalls,
          'priceRange': exhibition['price_range'] ?? null,
          'location': exhibition['city'] ?? 'Location not specified',
        };
      }).toList());

      setState(() {
        _exhibitions = processedExhibitions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error filtering exhibitions: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  void _toggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  Future<void> _toggleFavorite(int index) async {
    try {
      final exhibition = _exhibitions[index];
      final currentUser = _supabaseService.currentUser;
      
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to favorite exhibitions'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }
      
      await _supabaseService.toggleExhibitionFavorite(currentUser.id, exhibition['id']);
      
      // Update the local state
      setState(() {
        _exhibitions[index]['isFavorite'] = !_exhibitions[index]['isFavorite'];
      });
      
      // Show success message
      final message = _exhibitions[index]['isFavorite'] 
        ? 'Added to favorites' 
        : 'Removed from favorites';
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating favorite: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.explore,
                color: AppTheme.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              'Exhibitions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.white,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isGridView ? Icons.view_list : Icons.grid_view,
              color: AppTheme.white,
              size: 24,
            ),
            onPressed: _toggleView,
            tooltip: _isGridView ? 'List View' : 'Grid View',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search exhibitions...',
                    hintStyle: TextStyle(
                      color: AppTheme.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppTheme.white,
                      size: 24,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: AppTheme.white.withOpacity(0.7),
                      ),
                      onPressed: () {
                        _searchController.clear();
                        _loadExhibitions();
                      },
                      tooltip: 'Clear search',
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.white.withOpacity(0.2),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: AppTheme.white.withOpacity(0.2),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppTheme.white,
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: AppTheme.white.withOpacity(0.05),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  onChanged: (value) {
                    if (value.length >= 3) {
                      _searchExhibitions();
                    } else if (value.isEmpty) {
                      _loadExhibitions();
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Filter Chips
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          labelStyle: TextStyle(
                            color: AppTheme.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                             borderSide: BorderSide(
                               color: AppTheme.white.withOpacity(0.2),
                             ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                             borderSide: const BorderSide(
                               color: AppTheme.white,
                               width: 2,
                             ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          filled: true,
                          fillColor: AppTheme.white.withOpacity(0.05),
                        ),
                        dropdownColor: AppTheme.gradientBlack,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: 'All',
                            child: Text('All Categories', overflow: TextOverflow.ellipsis),
                          ),
                          ..._categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category['id'] as String,
                              child: Text(
                                (category['name'] as String).length > 15 
                                  ? '${(category['name'] as String).substring(0, 15)}...'
                                  : category['name'] as String,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                          });
                          _filterExhibitions();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedEventType,
                        decoration: InputDecoration(
                          labelText: 'Event Type',
                          labelStyle: TextStyle(
                            color: AppTheme.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                             borderSide: BorderSide(
                               color: AppTheme.white.withOpacity(0.2),
                             ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                             borderSide: const BorderSide(
                               color: AppTheme.white,
                               width: 2,
                             ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          filled: true,
                          fillColor: AppTheme.white.withOpacity(0.05),
                        ),
                        dropdownColor: AppTheme.gradientBlack,
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: 'All',
                            child: Text('All Types', overflow: TextOverflow.ellipsis),
                          ),
                          ..._eventTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type['id'] as String,
                              child: Text(
                                (type['name'] as String).length > 15 
                                  ? '${(type['name'] as String).substring(0, 15)}...'
                                  : type['name'] as String,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedEventType = value!;
                          });
                          _filterExhibitions();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedLocation,
                        decoration: InputDecoration(
                          labelText: 'Location',
                          labelStyle: TextStyle(
                            color: AppTheme.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                             borderSide: BorderSide(
                               color: AppTheme.white.withOpacity(0.2),
                             ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                             borderSide: const BorderSide(
                               color: AppTheme.white,
                               width: 2,
                             ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          filled: true,
                          fillColor: AppTheme.white.withOpacity(0.05),
                        ),
                        dropdownColor: AppTheme.gradientBlack,
                        isExpanded: true,
                        items: _cities.map((city) {
                          return DropdownMenuItem<String>(
                            value: city,
                            child: Text(
                              city.length > 15 ? '${city.substring(0, 15)}...' : city,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLocation = value!;
                          });
                          _filterExhibitions();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Exhibitions List
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _exhibitions.isEmpty
                    ? _buildEmptyState()
                    : _isGridView
                        ? _buildGridView()
                        : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 24,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppTheme.textMediumGray.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 18,
                width: 200,
                decoration: BoxDecoration(
                  color: AppTheme.textMediumGray.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 16,
                width: 150,
                decoration: BoxDecoration(
                  color: AppTheme.textMediumGray.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.event_busy,
                size: 64,
                color: AppTheme.primaryBlue,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No exhibitions found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDarkCharcoal,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Try adjusting your search or filters to find more exhibitions',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textMediumGray,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                _selectedCategory = 'All';
                _selectedEventType = 'All';
                _selectedLocation = 'All';
                _loadExhibitions();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reset Filters'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlue,
                foregroundColor: AppTheme.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _exhibitions.length,
      itemBuilder: (context, index) {
        final exhibition = _exhibitions[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: ExhibitionCard(
            exhibition: exhibition,
            isListView: true,
            onTap: () {
              // Navigation is handled within the ExhibitionCard
            },
            onFavorite: () => _toggleFavorite(index),
          ),
        );
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _exhibitions.length,
      itemBuilder: (context, index) {
        final exhibition = _exhibitions[index];
        return ExhibitionCard(
          exhibition: exhibition,
          isListView: false,
          onTap: () {
            // Navigation is handled within the ExhibitionCard
          },
          onFavorite: () => _toggleFavorite(index),
        );
      },
    );
  }
}
