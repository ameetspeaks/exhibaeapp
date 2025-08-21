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
  final _postalCodeController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  List<Map<String, dynamic>> _venueTypes = [];
  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _cities = [];
  bool _isLoadingData = true;
  String? _error;
  String? _selectedStateId;

  @override
  void initState() {
    super.initState();
    _loadFormData();
    _loadVenueTypes();
    _loadStates();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _loadFormData() {
    final formState = Provider.of<ExhibitionFormState>(context, listen: false);
    _addressController.text = formState.formData.address;
    _postalCodeController.text = formState.formData.postalCode ?? '';
    
    // Handle state and city from existing form data
    if (formState.formData.state != null && formState.formData.state!.isNotEmpty) {
      // Find the state by name and set the selected state ID
      final existingState = _states.firstWhere(
        (state) => state['name'] == formState.formData.state,
        orElse: () => {},
      );
      if (existingState.isNotEmpty) {
        _selectedStateId = existingState['id'];
        // Load cities for this state
        _loadCities(_selectedStateId!);
      }
    }
    
    if (formState.formData.city != null && formState.formData.city!.isNotEmpty) {
      // Note: City will be set after cities are loaded
      // This will be handled in the _loadCities callback
    }
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
        });
      }
    } catch (e) {
      print('Error loading venue types: $e');
    }
  }

  Future<void> _loadStates() async {
    try {
      final response = await _supabaseService.client
          .from('states')
          .select('id, name, state_code')
          .order('name');

      if (mounted) {
        setState(() {
          _states = List<Map<String, dynamic>>.from(response);
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

  Future<void> _loadCities(String stateId) async {
    try {
      final response = await _supabaseService.client
          .from('cities')
          .select('id, name, is_major, population')
          .eq('state_id', stateId)
          .order('is_major', ascending: false)
          .order('name');

      if (mounted) {
        setState(() {
          _cities = List<Map<String, dynamic>>.from(response);
        });
        
        // If we have existing city data, try to set it
        _setExistingCity();
      }
    } catch (e) {
      print('Error loading cities: $e');
    }
  }

  void _setExistingCity() {
    final formState = Provider.of<ExhibitionFormState>(context, listen: false);
    if (formState.formData.city != null && formState.formData.city!.isNotEmpty) {
      // Find the city by name in the loaded cities
      final existingCity = _cities.firstWhere(
        (city) => city['name'] == formState.formData.city,
        orElse: () => {},
      );
      if (existingCity.isNotEmpty) {
        // Update the form state with the city name
        Provider.of<ExhibitionFormState>(context, listen: false).updateLocation(
          city: existingCity['name'],
        );
      }
    }
  }

  void _onStateChanged(String? stateId) {
    setState(() {
      _selectedStateId = stateId;
      _cities = []; // Clear cities when state changes
    });
    
    if (stateId != null) {
      _loadCities(stateId);
      // Update form state
      final state = _states.firstWhere((s) => s['id'] == stateId);
      Provider.of<ExhibitionFormState>(context, listen: false).updateLocation(
        state: state['name'],
      );
    } else {
      Provider.of<ExhibitionFormState>(context, listen: false).updateLocation(
        state: null,
      );
    }
  }

  void _onCityChanged(String? cityId) {
    if (cityId != null) {
      final city = _cities.firstWhere((c) => c['id'] == cityId);
      Provider.of<ExhibitionFormState>(context, listen: false).updateLocation(
        city: city['name'],
      );
    } else {
      Provider.of<ExhibitionFormState>(context, listen: false).updateLocation(
        city: null,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.white.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location Details',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the venue details for your exhibition',
                  style: TextStyle(
                    color: AppTheme.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
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
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.errorRed.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Error loading data: $_error',
                  style: TextStyle(
                    color: AppTheme.errorRed,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            _buildDropdownField(
              label: 'Venue Type',
              hint: 'Select venue type',
              value: Provider.of<ExhibitionFormState>(context).formData.venueTypeId,
              items: _venueTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type['id'] as String,
                  child: Text(
                    type['name'] as String,
                    style: const TextStyle(color: AppTheme.gradientBlack, fontSize: 16),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                Provider.of<ExhibitionFormState>(context, listen: false).updateLocation(
                  venueTypeId: value,
                );
              },
            ),
          const SizedBox(height: 20),
          
          // Address Field
          _buildFormField(
            label: 'Address',
            hint: 'Enter venue address',
            controller: _addressController,
            onChanged: (value) {
              Provider.of<ExhibitionFormState>(context, listen: false).updateLocation(
                address: value,
              );
            },
          ),
          const SizedBox(height: 20),
          
          // Postal Code Field
          _buildFormField(
            label: 'Postal Code',
            hint: 'Enter postal code',
            controller: _postalCodeController,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              Provider.of<ExhibitionFormState>(context, listen: false).updateLocation(
                postalCode: value,
              );
            },
          ),
          const SizedBox(height: 20),
          
          // City and State Row
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                // Wide screen - side by side
                return Row(
                  children: [
                    Expanded(
                      child: _buildDropdownField(
                        label: 'State',
                        hint: 'Select state',
                        value: _selectedStateId,
                        items: _states.map((state) {
                          return DropdownMenuItem<String>(
                            value: state['id'] as String,
                            child: Text(
                              '${state['name']} (${state['state_code']})',
                              style: const TextStyle(color: AppTheme.gradientBlack, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: _onStateChanged,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDropdownField(
                            label: 'City',
                            hint: _selectedStateId != null ? 'Select city' : 'Select state first',
                            value: null, // We'll handle city selection separately
                            items: _cities.map((city) {
                              final isMajor = city['is_major'] == true;
                              final population = city['population'];
                              String displayText = city['name'] as String;
                              
                              if (isMajor && population != null) {
                                displayText += ' (Major City)';
                              }
                              
                              return DropdownMenuItem<String>(
                                value: city['id'] as String,
                                child: Row(
                                  children: [
                                    if (isMajor)
                                      Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        displayText,
                                        style: const TextStyle(color: AppTheme.gradientBlack, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: _selectedStateId != null ? _onCityChanged : (value) {},
                          ),
                          // Show loading indicator or message for cities
                          if (_selectedStateId != null && _cities.isEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.white.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.white.withOpacity(0.2),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Loading cities...',
                                    style: TextStyle(
                                      color: AppTheme.white.withOpacity(0.8),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              } else {
                // Narrow screen - stacked
                return Column(
                  children: [
                    _buildDropdownField(
                      label: 'State',
                      hint: 'Select state',
                      value: _selectedStateId,
                      items: _states.map((state) {
                        return DropdownMenuItem<String>(
                          value: state['id'] as String,
                          child: Text(
                            '${state['name']} (${state['state_code']})',
                            style: const TextStyle(color: AppTheme.gradientBlack, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _onStateChanged,
                    ),
                    const SizedBox(height: 20),
                    _buildDropdownField(
                      label: 'City',
                      hint: _selectedStateId != null ? 'Select city' : 'Select state first',
                      value: null, // We'll handle city selection separately
                      items: _cities.map((city) {
                        final isMajor = city['is_major'] == true;
                        final population = city['population'];
                        String displayText = city['name'] as String;
                        
                        if (isMajor && population != null) {
                          displayText += ' (Major City)';
                        }
                        
                        return DropdownMenuItem<String>(
                          value: city['id'] as String,
                          child: Row(
                            children: [
                              if (isMajor)
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: Colors.amber,
                                ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  displayText,
                                  style: const TextStyle(color: AppTheme.gradientBlack, fontSize: 16),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: _selectedStateId != null ? _onCityChanged : (value) {},
                    ),
                    const SizedBox(height: 20),
                    // Country Display (Always India)
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.white.withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Country',
                              style: TextStyle(
                                color: AppTheme.gradientBlack.withOpacity(0.7),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  Icons.flag,
                                  color: AppTheme.primaryMaroon,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'India',
                                  style: TextStyle(
                                    color: AppTheme.gradientBlack,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Show loading indicator or message for cities
                    if (_selectedStateId != null && _cities.isEmpty)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppTheme.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Loading cities...',
                              style: TextStyle(
                                color: AppTheme.white.withOpacity(0.8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 20),
          

        ],
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
    required Function(String) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: TextStyle(
          color: AppTheme.gradientBlack,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: AppTheme.gradientBlack.withOpacity(0.7),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: AppTheme.gradientBlack.withOpacity(0.5),
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          filled: true,
          fillColor: Colors.transparent,
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        items: items,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(
            color: AppTheme.gradientBlack.withOpacity(0.7),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: AppTheme.gradientBlack.withOpacity(0.5),
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          filled: true,
          fillColor: Colors.transparent,
        ),
        style: TextStyle(
          color: AppTheme.gradientBlack,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        dropdownColor: AppTheme.white,
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: AppTheme.gradientBlack.withOpacity(0.7),
          size: 24,
        ),
        isExpanded: true,
        menuMaxHeight: 300,
      ),
    );
  }
}
