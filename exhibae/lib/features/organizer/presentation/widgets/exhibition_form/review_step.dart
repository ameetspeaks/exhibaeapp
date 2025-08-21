import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/supabase_service.dart';
import '../../../domain/models/exhibition_form_state.dart';

class ReviewStep extends StatefulWidget {
  const ReviewStep({super.key});

  @override
  State<ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends State<ReviewStep> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  Map<String, dynamic>? _categoryData;
  Map<String, dynamic>? _eventTypeData;
  Map<String, dynamic>? _venueTypeData;
  List<Map<String, dynamic>> _selectedAmenities = [];
  List<Map<String, dynamic>> _measurementUnits = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReferenceData();
  }

  Future<void> _loadReferenceData() async {
    try {
      final formState = Provider.of<ExhibitionFormState>(context, listen: false);
      final formData = formState.formData;

      // Load category data
      if (formData.categoryId != null) {
        final categoryResponse = await _supabaseService.client
            .from('exhibition_categories')
            .select()
            .eq('id', formData.categoryId ?? '')
            .single();
        _categoryData = categoryResponse;
      }

      // Load event type data
      if (formData.eventTypeId != null) {
        final eventTypeResponse = await _supabaseService.client
            .from('event_types')
            .select()
            .eq('id', formData.eventTypeId ?? '')
            .single();
        _eventTypeData = eventTypeResponse;
      }

      // Load venue type data
      if (formData.venueTypeId != null) {
        final venueTypeResponse = await _supabaseService.client
            .from('venue_types')
            .select()
            .eq('id', formData.venueTypeId ?? '')
            .single();
        _venueTypeData = venueTypeResponse;
      }

      // Load measurement units
      final measurementUnitsResponse = await _supabaseService.client
          .from('measurement_units')
          .select()
          .eq('type', 'area');
      _measurementUnits = List<Map<String, dynamic>>.from(measurementUnitsResponse);

      // Load amenities data
      if (formData.selectedAmenities.isNotEmpty) {
        final amenitiesResponse = await _supabaseService.client
            .from('amenities')
            .select()
            .inFilter('id', formData.selectedAmenities);
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
            'Review your exhibition details before submitting',
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
                      color: AppTheme.white.withValues(alpha: 0.7),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadReferenceData,
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
                final formData = state.formData;
                
                return Column(
                  children: [
                    // Basic Information Section
                    _buildSection(
                      'Basic Information',
                      Icons.info,
                      [
                        _buildInfoItem('Title', formData.title),
                        _buildInfoItem('Description', formData.description),
                        if (_categoryData != null)
                          _buildInfoItem('Category', _categoryData!['name']),
                        if (_eventTypeData != null)
                          _buildInfoItem('Event Type', _eventTypeData!['name']),
                        _buildInfoItem(
                          'Dates',
                          formData.startDate != null && formData.endDate != null
                              ? '${_formatDate(formData.startDate!)} - ${_formatDate(formData.endDate!)}'
                              : 'Not set',
                        ),
                        if (formData.startTime != null)
                          _buildInfoItem(
                            'Start Time',
                            '${formData.startTime!.hour.toString().padLeft(2, '0')}:${formData.startTime!.minute.toString().padLeft(2, '0')}',
                          ),
                        if (formData.endTime != null)
                          _buildInfoItem(
                            'End Time',
                            '${formData.endTime!.hour.toString().padLeft(2, '0')}:${formData.endTime!.minute.toString().padLeft(2, '0')}',
                          ),
                        if (formData.applicationDeadline != null)
                          _buildInfoItem(
                            'Application Deadline',
                            _formatDate(formData.applicationDeadline!),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Location Section
                    _buildSection(
                      'Location',
                      Icons.location_on,
                      [
                        if (_venueTypeData != null)
                          _buildInfoItem('Venue Type', _venueTypeData!['name']),
                        _buildInfoItem('Address', formData.address),
                        _buildInfoItem('City', formData.city),
                        _buildInfoItem('State', formData.state),
                        _buildInfoItem('Country', formData.country),
                        if (formData.postalCode != null)
                          _buildInfoItem('Postal Code', formData.postalCode!),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Stalls Section
                    _buildSection(
                      'Stalls',
                      Icons.store,
                      [
                        _buildInfoItem(
                          'Number of Stall Types',
                          formData.stalls.length.toString(),
                        ),
                        ...formData.stalls.asMap().entries.map((entry) {
                          final index = entry.key;
                          final stall = entry.value;
                          final unit = _measurementUnits.firstWhere(
                            (u) => u['id'] == stall['unit_id'],
                            orElse: () => {'name': 'Unknown', 'symbol': ''},
                          );
                          return _buildInfoItem(
                            'Stall ${index + 1}',
                            '${stall['name']} - ${stall['length']} × ${stall['width']} ${unit['symbol']} - ₹${stall['price']} - Qty: ${stall['quantity']}',
                          );
                        }).toList(),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Gallery Section
                    _buildSection(
                      'Gallery & Images',
                      Icons.image,
                      [
                        _buildInfoItem(
                          'Cover Images',
                          '${_getImagesByType(formData.galleryImages, 'cover').length} images',
                        ),
                        _buildInfoItem(
                          'Exhibition Images',
                          '${_getImagesByType(formData.galleryImages, 'exhibition').length} images',
                        ),
                        _buildInfoItem(
                          'Layout Images',
                          '${_getImagesByType(formData.galleryImages, 'layout').length} images',
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
                    const SizedBox(height: 24),

                    // Approval Section
                    _buildApprovalSection(),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getImagesByType(List<Map<String, dynamic>> images, String type) {
    return images.where((image) => image['image_type'] == type).toList();
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.white.withValues(alpha: 0.1),
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
              color: AppTheme.white.withValues(alpha: 0.8),
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildApprovalSection() {
    return Container(
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
                child: const Icon(
                  Icons.approval,
                  color: AppTheme.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Submit for Approval',
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'By submitting this exhibition for approval, you acknowledge that:',
            style: TextStyle(
              color: AppTheme.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          _buildApprovalItem(
            'All information provided is accurate and complete',
            Icons.check_circle,
          ),
          _buildApprovalItem(
            'The exhibition will be reviewed by a manager/admin',
            Icons.admin_panel_settings,
          ),
          _buildApprovalItem(
            'Approval may take 24-48 hours',
            Icons.schedule,
          ),
          _buildApprovalItem(
            'You will be notified once approved or rejected',
            Icons.notifications,
          ),
          const SizedBox(height: 20),
          Consumer<ExhibitionFormState>(
            builder: (context, state, child) {
              return Container(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: state.formData.isValid
                      ? () async {
                          // This will be handled by the main form screen
                          // The button in the main screen will call submitForApproval
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: state.formData.isValid
                        ? AppTheme.white.withOpacity(0.2)
                        : AppTheme.white.withOpacity(0.1),
                    foregroundColor: AppTheme.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.send),
                  label: Text(
                    state.formData.isValid
                        ? 'Submit for Approval'
                        : 'Complete Required Fields',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppTheme.white.withOpacity(0.6),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppTheme.white.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
