import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/models/venue_form_state.dart';

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

  @override
  void initState() {
    super.initState();
    _loadFormData();
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
    final formState = context.read<VenueFormState>();
    _addressController.text = formState.formData.address;
    _cityController.text = formState.formData.city;
    _stateController.text = formState.formData.state;
    _countryController.text = formState.formData.country;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the location details for your venue',
            style: TextStyle(
              color: AppTheme.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          
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
                context.read<VenueFormState>().updateLocation(
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
                context.read<VenueFormState>().updateLocation(
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
                context.read<VenueFormState>().updateLocation(
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
                context.read<VenueFormState>().updateLocation(
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
          const SizedBox(height: 24),
          
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
          const SizedBox(height: 16),
          
          // Location Tips
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: AppTheme.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Location Tips',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTipItem(
                  'Provide a complete and accurate address',
                  Icons.location_on,
                ),
                const SizedBox(height: 12),
                _buildTipItem(
                  'Include nearby landmarks for easy navigation',
                  Icons.place,
                ),
                const SizedBox(height: 12),
                _buildTipItem(
                  'Mention parking availability and access points',
                  Icons.local_parking,
                ),
                const SizedBox(height: 12),
                _buildTipItem(
                  'Add public transport information if available',
                  Icons.directions_bus,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
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
    );
  }
}
