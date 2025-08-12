import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/supabase_service.dart';
import '../../../domain/models/venue_form_state.dart';

class ReviewStep extends StatefulWidget {
  const ReviewStep({super.key});

  @override
  State<ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends State<ReviewStep> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  Map<String, dynamic>? _venueTypeData;
  Map<String, dynamic>? _measurementUnitData;
  List<Map<String, dynamic>> _selectedAmenities = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReferenceData();
  }

  Future<void> _loadReferenceData() async {
    try {
      final formState = context.read<VenueFormState>();
      final formData = formState.formData;

      // Load venue type data
      if (formData.venueTypeId != null) {
        final venueTypeResponse = await _supabaseService.client
            .from('venue_types')
            .select()
            .eq('id', formData.venueTypeId)
            .single();
        _venueTypeData = venueTypeResponse;
      }

      // Load measurement unit data
      if (formData.measurementUnitId != null) {
        final measurementUnitResponse = await _supabaseService.client
            .from('measurement_units')
            .select()
            .eq('id', formData.measurementUnitId)
            .single();
        _measurementUnitData = measurementUnitResponse;
      }

      // Load amenities data
      if (formData.amenities.isNotEmpty) {
        final amenitiesResponse = await _supabaseService.client
            .from('amenities')
            .select()
            .in_('id', formData.amenities);
        _selectedAmenities = List<Map<String, dynamic>>.from(amenitiesResponse);
      }

      if (mounted) {
        setState(() {
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Review',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Review your venue details before submitting',
            style: TextStyle(
              color: AppTheme.white.withOpacity(0.8),
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
                    'Error loading review data',
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
                    onPressed: _loadReferenceData,
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
          else
            Consumer<VenueFormState>(
              builder: (context, state, child) {
                final formData = state.formData;
                
                return Column(
                  children: [
                    // Basic Information Section
                    _buildSection(
                      'Basic Information',
                      Icons.info,
                      [
                        _buildInfoItem('Name', formData.name),
                        _buildInfoItem('Description', formData.description),
                        if (_venueTypeData != null)
                          _buildInfoItem('Venue Type', _venueTypeData!['name']),
                        _buildInfoItem('Capacity', '${formData.capacity} people'),
                        _buildInfoItem(
                          'Area',
                          '${formData.area}${_measurementUnitData?['symbol'] ?? ''}²',
                        ),
                        _buildInfoItem(
                          'Availability',
                          formData.isAvailable ? 'Available' : 'Not Available',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Location Section
                    _buildSection(
                      'Location',
                      Icons.location_on,
                      [
                        _buildInfoItem('Address', formData.address),
                        _buildInfoItem('City', formData.city),
                        _buildInfoItem('State', formData.state),
                        _buildInfoItem('Country', formData.country),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Media Section
                    _buildSection(
                      'Media',
                      Icons.image,
                      [
                        _buildInfoItem(
                          'Venue Images',
                          '${formData.images.length} images uploaded',
                        ),
                        _buildInfoItem(
                          'Floor Plan',
                          formData.floorPlan != null ? 'Uploaded' : 'Not uploaded',
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Amenities Section
                    _buildSection(
                      'Amenities',
                      Icons.star,
                      [
                        _buildInfoItem(
                          'Selected Amenities',
                          _selectedAmenities.isEmpty
                              ? 'No amenities selected'
                              : _selectedAmenities.map((a) => a['name']).join(', '),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.white.withOpacity(0.2),
          width: 1,
        ),
      ),
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
                  icon,
                  color: AppTheme.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
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
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
