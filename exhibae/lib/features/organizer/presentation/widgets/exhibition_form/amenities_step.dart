import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/supabase_service.dart';
import '../../../domain/models/exhibition_form_state.dart';

class AmenitiesStep extends StatefulWidget {
  const AmenitiesStep({super.key});

  @override
  State<AmenitiesStep> createState() => _AmenitiesStepState();
}

class _AmenitiesStepState extends State<AmenitiesStep> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  List<Map<String, dynamic>> _amenities = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAmenities();
  }

  Future<void> _loadAmenities() async {
    try {
      final amenities = await _supabaseService.getAmenities();

      if (mounted) {
        setState(() {
          _amenities = amenities;
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

  void _toggleAmenity(String amenityId) {
    final formState = Provider.of<ExhibitionFormState>(context, listen: false);
    final currentAmenities = List<String>.from(formState.formData.selectedAmenities);
    
    if (currentAmenities.contains(amenityId)) {
      currentAmenities.remove(amenityId);
    } else {
      currentAmenities.add(amenityId);
    }
    
    formState.updateAmenities(currentAmenities);
  }

  IconData _getAmenityIcon(String? iconName) {
    // Map common amenity names to icons
    switch (iconName?.toLowerCase()) {
      case 'wifi':
        return Icons.wifi;
      case 'parking':
        return Icons.local_parking;
      case 'food':
      case 'restaurant':
        return Icons.restaurant;
      case 'security':
        return Icons.security;
      case 'accessibility':
        return Icons.accessible;
      case 'power':
        return Icons.power;
      case 'lighting':
        return Icons.lightbulb;
      case 'sound':
      case 'audio':
        return Icons.volume_up;
      case 'stage':
        return Icons.event;
      case 'seating':
        return Icons.event_seat;
      case 'storage':
        return Icons.inventory;
      case 'cleaning':
        return Icons.cleaning_services;
      case 'transport':
        return Icons.directions_car;
      case 'medical':
        return Icons.medical_services;
      case 'information':
        return Icons.info;
      case 'registration':
        return Icons.app_registration;
      default:
        return Icons.check_circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Amenities',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the amenities available at your venue',
            style: TextStyle(
              color: AppTheme.white.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
              ),
            )
          else if (_error != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading amenities',
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
                      color: AppTheme.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadAmenities,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.white.withValues(alpha: 0.2),
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
          else
            Consumer<ExhibitionFormState>(
              builder: (context, state, child) {
                return Column(
                  children: [
                    // Popular Amenities
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Popular Amenities',
                            style: TextStyle(
                              color: AppTheme.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: _amenities
                                .take(6) // Show first 6 as popular
                                .map((amenity) => _buildAmenityChip(
                                  amenity,
                                  state.formData.selectedAmenities.contains(amenity['id']),
                                ))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // All Amenities
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'All Amenities',
                            style: TextStyle(
                              color: AppTheme.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _amenities.length,
                            itemBuilder: (context, index) {
                              final amenity = _amenities[index];
                              final isSelected = state.formData.selectedAmenities.contains(amenity['id']);
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.white.withValues(alpha: 0.2)
                                      : AppTheme.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppTheme.white.withValues(alpha: 0.4)
                                        : AppTheme.white.withValues(alpha: 0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _toggleAmenity(amenity['id']),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppTheme.white.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              _getAmenityIcon(amenity['icon']),
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
                                                  amenity['name'] ?? '',
                                                  style: const TextStyle(
                                                    color: AppTheme.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (amenity['description'] != null) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    amenity['description'],
                                                    style: TextStyle(
                                                      color: AppTheme.white.withValues(alpha: 0.8),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected
                                                  ? AppTheme.white
                                                  : AppTheme.white.withValues(alpha: 0.1),
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppTheme.white
                                                    : AppTheme.white.withValues(alpha: 0.2),
                                                width: 2,
                                              ),
                                            ),
                                            child: isSelected
                                                ? const Icon(
                                                    Icons.check,
                                                    color: AppTheme.gradientBlack,
                                                    size: 16,
                                                  )
                                                : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAmenityChip(Map<String, dynamic> amenity, bool isSelected) {
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) => _toggleAmenity(amenity['id']),
      backgroundColor: isSelected ? AppTheme.white : AppTheme.white.withValues(alpha: 0.1),
      selectedColor: AppTheme.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.white : AppTheme.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getAmenityIcon(amenity['icon']),
            color: isSelected ? AppTheme.gradientBlack : AppTheme.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            amenity['name'] ?? '',
            style: TextStyle(
              color: isSelected ? AppTheme.gradientBlack : AppTheme.white,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
