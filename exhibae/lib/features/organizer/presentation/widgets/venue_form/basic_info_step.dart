import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/supabase_service.dart';
import '../../../domain/models/venue_form_state.dart';

class BasicInfoStep extends StatefulWidget {
  const BasicInfoStep({super.key});

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  final _areaController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  List<Map<String, dynamic>> _venueTypes = [];
  List<Map<String, dynamic>> _measurementUnits = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFormData();
    _loadDropdownData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  void _loadFormData() {
    final formState = context.read<VenueFormState>();
    _nameController.text = formState.formData.name;
    _descriptionController.text = formState.formData.description;
    _capacityController.text = formState.formData.capacity > 0
        ? formState.formData.capacity.toString()
        : '';
    _areaController.text = formState.formData.area > 0
        ? formState.formData.area.toString()
        : '';
  }

  Future<void> _loadDropdownData() async {
    try {
      final venueTypesResponse = await _supabaseService.client
          .from('venue_types')
          .select()
          .order('name');
      
      final measurementUnitsResponse = await _supabaseService.client
          .from('measurement_units')
          .select()
          .order('name');

      if (mounted) {
        setState(() {
          _venueTypes = List<Map<String, dynamic>>.from(venueTypesResponse);
          _measurementUnits = List<Map<String, dynamic>>.from(measurementUnitsResponse);
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
            'Basic Information',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the basic details about your venue',
            style: TextStyle(
              color: AppTheme.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          
          // Name Field
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
              controller: _nameController,
              style: const TextStyle(color: AppTheme.white),
              onChanged: (value) {
                context.read<VenueFormState>().updateBasicInfo(
                  name: value,
                );
              },
              decoration: InputDecoration(
                labelText: 'Venue Name',
                labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Description Field
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
              controller: _descriptionController,
              style: const TextStyle(color: AppTheme.white),
              maxLines: 5,
              onChanged: (value) {
                context.read<VenueFormState>().updateBasicInfo(
                  description: value,
                );
              },
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Venue Type Dropdown
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
              ),
            )
          else if (_error != null)
            Center(
              child: Text(
                'Error loading data: $_error',
                style: TextStyle(
                  color: AppTheme.errorRed,
                  fontSize: 14,
                ),
              ),
            )
          else ...[
            Container(
              decoration: BoxDecoration(
                color: AppTheme.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Consumer<VenueFormState>(
                builder: (context, state, child) {
                  return DropdownButtonFormField<String>(
                    value: state.formData.venueTypeId,
                    items: _venueTypes.map((type) {
                      return DropdownMenuItem(
                        value: type['id'],
                        child: Text(
                          type['name'],
                          style: const TextStyle(color: AppTheme.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      state.updateBasicInfo(venueTypeId: value);
                    },
                    dropdownColor: AppTheme.gradientBlack,
                    style: const TextStyle(color: AppTheme.white),
                    decoration: InputDecoration(
                      labelText: 'Venue Type',
                      labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Capacity Field
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
                controller: _capacityController,
                style: const TextStyle(color: AppTheme.white),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                onChanged: (value) {
                  context.read<VenueFormState>().updateBasicInfo(
                    capacity: int.tryParse(value),
                  );
                },
                decoration: InputDecoration(
                  labelText: 'Capacity (people)',
                  labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                  prefixIcon: Icon(
                    Icons.people,
                    color: AppTheme.white.withOpacity(0.8),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Area and Measurement Unit
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: TextField(
                      controller: _areaController,
                      style: const TextStyle(color: AppTheme.white),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onChanged: (value) {
                        context.read<VenueFormState>().updateBasicInfo(
                          area: double.tryParse(value),
                        );
                      },
                      decoration: InputDecoration(
                        labelText: 'Area',
                        labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                        prefixIcon: Icon(
                          Icons.square_foot,
                          color: AppTheme.white.withOpacity(0.8),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Consumer<VenueFormState>(
                      builder: (context, state, child) {
                        return DropdownButtonFormField<String>(
                          value: state.formData.measurementUnitId,
                          items: _measurementUnits.map((unit) {
                            return DropdownMenuItem(
                              value: unit['id'],
                              child: Text(
                                unit['symbol'],
                                style: const TextStyle(color: AppTheme.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            state.updateBasicInfo(measurementUnitId: value);
                          },
                          dropdownColor: AppTheme.gradientBlack,
                          style: const TextStyle(color: AppTheme.white),
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Availability Toggle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Consumer<VenueFormState>(
                builder: (context, state, child) {
                  return Row(
                    children: [
                      Icon(
                        Icons.event_available,
                        color: AppTheme.white.withOpacity(0.8),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Venue Availability',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'Toggle if this venue is available for booking',
                              style: TextStyle(
                                color: AppTheme.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: state.formData.isAvailable,
                        onChanged: (value) {
                          state.updateBasicInfo(isAvailable: value);
                        },
                        activeColor: AppTheme.white,
                        activeTrackColor: Colors.green.withOpacity(0.5),
                        inactiveThumbColor: AppTheme.white.withOpacity(0.6),
                        inactiveTrackColor: AppTheme.white.withOpacity(0.1),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
