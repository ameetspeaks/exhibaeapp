import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import '../widgets/exhibition_card.dart';

class FavoriteExhibitionsScreen extends StatefulWidget {
  const FavoriteExhibitionsScreen({super.key});

  @override
  State<FavoriteExhibitionsScreen> createState() => _FavoriteExhibitionsScreenState();
}

class _FavoriteExhibitionsScreenState extends State<FavoriteExhibitionsScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _favoriteExhibitions = [];
  List<Map<String, dynamic>> _filteredExhibitions = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFavoriteExhibitions();
    _searchController.addListener(_filterExhibitions);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteExhibitions() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final favorites = await _supabaseService.getExhibitionFavorites(currentUser.id);
      
      if (mounted) {
        setState(() {
          _favoriteExhibitions = favorites;
          _filteredExhibitions = favorites;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load favorite exhibitions: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _filterExhibitions() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredExhibitions = _favoriteExhibitions;
      } else {
        _filteredExhibitions = _favoriteExhibitions.where((exhibition) {
          final exhibitionData = exhibition['exhibition'] as Map<String, dynamic>?;
          if (exhibitionData == null) return false;
          
          final title = (exhibitionData['title'] ?? '').toString().toLowerCase();
          final city = (exhibitionData['city'] ?? '').toString().toLowerCase();
          final state = (exhibitionData['state'] ?? '').toString().toLowerCase();
          
          return title.contains(query) || 
                 city.contains(query) || 
                 state.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _removeFromFavorites(String exhibitionId) async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      await _supabaseService.toggleExhibitionFavorite(
        currentUser.id,
        exhibitionId,
      );

      // Refresh the list
      await _loadFavoriteExhibitions();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove from favorites: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Exhibitions'),
        backgroundColor: AppTheme.primaryMaroon,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search favorite exhibitions...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.borderLightGray),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.borderLightGray),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryMaroon),
                ),
                filled: true,
                fillColor: AppTheme.backgroundPeach,
              ),
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppTheme.errorRed,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.errorRed,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadFavoriteExhibitions,
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
                                Icon(
                                  Icons.favorite_border,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _isSearching ? 'No matching exhibitions' : 'No favorite exhibitions',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isSearching 
                                      ? 'Try adjusting your search terms'
                                      : 'Start exploring exhibitions and add them to your favorites',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredExhibitions.length,
                            itemBuilder: (context, index) {
                              final exhibition = _filteredExhibitions[index];
                              return _buildExhibitionCard(exhibition);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildExhibitionCard(Map<String, dynamic> exhibition) {
    final exhibitionData = exhibition['exhibition'] as Map<String, dynamic>?;
    if (exhibitionData == null) return const SizedBox.shrink();

    // Prepare the exhibition data for the ExhibitionCard widget
    final cardData = Map<String, dynamic>.from(exhibitionData);
    cardData['isFavorite'] = true; // Mark as favorite since it's in favorites list

    return ExhibitionCard(
      exhibition: cardData,
      isListView: true,
      onTap: () {
        // Navigate to exhibition details
        Navigator.pushNamed(
          context,
          '/exhibition-details',
          arguments: {'exhibition': exhibitionData},
        );
      },
      onFavorite: () => _removeFromFavorites(exhibitionData['id']),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
