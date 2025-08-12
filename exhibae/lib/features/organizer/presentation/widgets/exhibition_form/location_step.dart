import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/supabase_service.dart';
import '../../../domain/models/exhibition_form_state.dart';

class LocationStep extends StatefulWidget {
  const LocationStep({super.key});

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  List<Map<String, dynamic>> _venueTypes = [];
  bool _isLoadingData = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFormData();
    _loadVenueTypes();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _loadFormData() {
    final formState = Provider.of<ExhibitionFormState>(context, listen: false);
    _addressController.text = formState.formData.address;
    _cityController.text = formState.formData.city;
    _stateController.text = formState.formData.state;
    _countryController.text = formState.formData.country;
  }

  Future<void> _loadVenueTypes() async {
    try {
      final response = await _supabaseService.client
          .from('venue_types')
          .select()
          .order('name');

      if (mounted) {
        setState(() {
          _venueTypes = List<Map<String, dynamic>>.from(response);
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingData = false;
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
            'Location Details',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the venue details for your exhibition',
            style: TextStyle(
              color: AppTheme.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          
          // Venue Type Dropdown
          if (_isLoadingData)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
              ),
            )
          else if (_error != null)
            Center(
              child: Text(
                'Error loading venue types: $_error',
                style: TextStyle(
                  color: AppTheme.errorRed,
                  fontSize: 14,
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppTheme.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Consumer<ExhibitionFormState>(
                builder: (context, state, child) {
                  return DropdownButtonFormField<String>(
                    value: state.formData.venueTypeId,
                    items: _venueTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type['id'] as String,
                        child: Text(
                          type['name'] as String,
                          style: const TextStyle(color: AppTheme.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      state.updateLocation(venueTypeId: value);
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
          
          // Address Field
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
              controller: _addressController,
              style: const TextStyle(color: AppTheme.white),
              maxLines: 3,
              onChanged: (value) {
                Provider.of<ExhibitionFormState>(context, listen: false).updateLocation(
                  address: value,
                );
              },
              decoration: InputDecoration(
                labelText: 'Address',
                labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // City Field
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
              controller: _cityController,
              style: const TextStyle(color: AppTheme.white),
              onChanged: (value) {
                Provider.of<ExhibitionFormState>(context, listen: false).updateLocation(
                  city: value,
                );
              },
              decoration: InputDecoration(
                labelText: 'City',
                labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // State Field
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
              controller: _stateController,
              style: const TextStyle(color: AppTheme.white),
              onChanged: (value) {
                Provider.of<ExhibitionFormState>(context, listen: false).updateLocation(
                  state: value,
                );
              },
              decoration: InputDecoration(
                labelText: 'State',
                labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Country Field
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
              controller: _countryController,
              style: const TextStyle(color: AppTheme.white),
              onChanged: (value) {
                Provider.of<ExhibitionFormState>(context, listen: false).updateLocation(
                  country: value,
                );
              },
              decoration: InputDecoration(
                labelText: 'Country',
                labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Map Preview (Placeholder)
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.map,
                    size: 48,
                    color: AppTheme.white.withOpacity(0.6),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Map preview coming soon',
                    style: TextStyle(
                      color: AppTheme.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
