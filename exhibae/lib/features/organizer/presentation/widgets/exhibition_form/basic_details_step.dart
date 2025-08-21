import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/supabase_service.dart';
import '../../../domain/models/exhibition_form_state.dart';

class BasicDetailsStep extends StatefulWidget {
  const BasicDetailsStep({super.key});

  @override
  State<BasicDetailsStep> createState() => _BasicDetailsStepState();
}

class _BasicDetailsStepState extends State<BasicDetailsStep> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _postalCodeController = TextEditingController();
  
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _eventTypes = [];
  List<Map<String, dynamic>> _venueTypes = [];
  List<Map<String, dynamic>> _states = [];
  List<Map<String, dynamic>> _cities = [];
  
  bool _isLoadingData = true;
  String? _error;
  String? _selectedStateId;
  
  // Edit states for each field
  bool _isEditingTitle = false;
  bool _isEditingDescription = false;
  bool _isEditingCategory = false;
  bool _isEditingEventType = false;
  bool _isEditingVenueType = false;
  bool _isEditingDates = false;
  bool _isEditingTimes = false;
  bool _isEditingAddress = false;
  bool _isEditingState = false;
  bool _isEditingCity = false;
  bool _isEditingPostalCode = false;
  bool _isEditingCountry = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadFormData();
    // Set default dates and times after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setDefaultDatesAndTimes();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  void _setDefaultDatesAndTimes() {
    final formState = Provider.of<ExhibitionFormState>(context, listen: false);
    final now = DateTime.now();
    final startDate = now.add(const Duration(days: 1));
    final endDate = now.add(const Duration(days: 3));
    final startTime = const TimeOfDay(hour: 11, minute: 0);
    final endTime = const TimeOfDay(hour: 19, minute: 0);
    
    formState.updateBasicInfo(
      startDate: startDate,
      endDate: endDate,
      startTime: startTime,
      endTime: endTime,
    );
  }

  void _loadFormData() {
    final formState = Provider.of<ExhibitionFormState>(context, listen: false);
    final formData = formState.formData;
    
    _titleController.text = formData.title;
    _descriptionController.text = formData.description;
    _addressController.text = formData.address;
    _postalCodeController.text = formData.postalCode ?? '';
    
    // Set default country to India if not already set
    if (formData.country.isEmpty) {
      formState.updateLocation(country: 'India');
    }
    
    // Load cities if state is already selected
    if (formData.state.isNotEmpty) {
      _loadCitiesForState(formData.state).then((cities) {
        if (mounted) {
          setState(() {
            _cities = cities;
          });
        }
      });
    }
  }

  // Helper method to toggle edit state
  void _toggleEditState(String fieldName) {
    setState(() {
      switch (fieldName) {
        case 'title':
          _isEditingTitle = !_isEditingTitle;
          break;
        case 'description':
          _isEditingDescription = !_isEditingDescription;
          break;
        case 'category':
          _isEditingCategory = !_isEditingCategory;
          break;
        case 'eventType':
          _isEditingEventType = !_isEditingEventType;
          break;
        case 'venueType':
          _isEditingVenueType = !_isEditingVenueType;
          break;
        case 'dates':
          _isEditingDates = !_isEditingDates;
          break;
        case 'times':
          _isEditingTimes = !_isEditingTimes;
          break;
        case 'address':
          _isEditingAddress = !_isEditingAddress;
          break;
        case 'state':
          _isEditingState = !_isEditingState;
          break;
        case 'city':
          _isEditingCity = !_isEditingCity;
          break;
        case 'postalCode':
          _isEditingPostalCode = !_isEditingPostalCode;
          break;
        case 'country':
          _isEditingCountry = !_isEditingCountry;
          break;
      }
    });
  }

  // Helper method to check if we're in edit mode (for existing exhibitions)
  bool _isEditMode() {
    final formState = Provider.of<ExhibitionFormState>(context, listen: false);
    return formState.isEditing;
  }

  // Widget for editable text field with edit icon
  Widget _buildEditableTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String fieldName,
    bool isEditing = false,
    bool isEditMode = false,
    Function(String)? onChanged,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isEditMode)
              IconButton(
                onPressed: () => _toggleEditState(fieldName),
                icon: Icon(
                  isEditing ? Icons.save : Icons.edit,
                  color: isEditing ? AppTheme.successGreen : AppTheme.primaryMaroon,
                  size: 20,
                ),
                tooltip: isEditing ? 'Save' : 'Edit',
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: controller,
            onChanged: onChanged,
            enabled: !isEditMode || isEditing,
            keyboardType: keyboardType,
            style: TextStyle(
              color: AppTheme.gradientBlack,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppTheme.gradientBlack.withOpacity(0.5),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  // Widget for editable dropdown field with edit icon
  Widget _buildEditableDropdownField({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    required String fieldName,
    bool isEditing = false,
    bool isEditMode = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isEditMode)
              IconButton(
                onPressed: () => _toggleEditState(fieldName),
                icon: Icon(
                  isEditing ? Icons.save : Icons.edit,
                  color: isEditing ? AppTheme.successGreen : AppTheme.primaryMaroon,
                  size: 20,
                ),
                tooltip: isEditing ? 'Save' : 'Edit',
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items,
            onChanged: (!isEditMode || isEditing) ? onChanged : null,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
            style: TextStyle(
              color: AppTheme.gradientBlack,
              fontSize: 16,
            ),
            dropdownColor: AppTheme.white,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: AppTheme.gradientBlack,
            ),
            isExpanded: true,
            menuMaxHeight: 200,
          ),
        ),
      ],
    );
  }

  // Widget for editable date/time display with edit icon
  Widget _buildEditableDateTimeDisplay({
    required String label,
    required String displayText,
    required VoidCallback onTap,
    required String fieldName,
    bool isEditing = false,
    bool isEditMode = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isEditMode)
              IconButton(
                onPressed: () => _toggleEditState(fieldName),
                icon: Icon(
                  isEditing ? Icons.save : Icons.edit,
                  color: isEditing ? AppTheme.successGreen : AppTheme.primaryMaroon,
                  size: 20,
                ),
                tooltip: isEditing ? 'Save' : 'Edit',
              ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: (!isEditMode || isEditing) ? onTap : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    displayText,
                    style: TextStyle(
                      color: AppTheme.gradientBlack,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (!isEditMode || isEditing)
                  Icon(
                    Icons.calendar_today,
                    color: AppTheme.gradientBlack.withOpacity(0.5),
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _loadData() async {
    try {
      final categoriesResponse = await _supabaseService.getExhibitionCategories();
      final eventTypesResponse = await _supabaseService.getEventTypes();
      final venueTypesResponse = await _supabaseService.getVenueTypes();
      
      // Load states from database
      final statesResponse = await _supabaseService.getStates();

      if (mounted) {
        setState(() {
          _categories = categoriesResponse;
          _eventTypes = eventTypesResponse;
          _venueTypes = venueTypesResponse;
          _states = statesResponse;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data: $e';
          _isLoadingData = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> _loadCitiesForState(String stateName) async {
    try {
      print('Looking for state: $stateName');
      print('Available states: ${_states.map((s) => s['name']).toList()}');
      
      // First find the state ID for the given state name
      final matchingState = _states.firstWhere(
        (state) => state['name'] == stateName,
        orElse: () => <String, dynamic>{},
      );
      
      if (matchingState.isNotEmpty) {
        final stateId = matchingState['id'] as String;
        print('Found state ID: $stateId for state: $stateName');
        // Use the more reliable getCitiesByState method with state ID
        final cities = await _supabaseService.getCitiesByState(stateId);
        print('Retrieved ${cities.length} cities for state ID: $stateId');
        return cities;
      } else {
        print('State not found: $stateName');
      }
      
      return [];
    } catch (e) {
      print('Error loading cities for state: $e');
      return [];
    }
  }

  void _updateForm() {
    final formState = Provider.of<ExhibitionFormState>(context, listen: false);
    
    formState.updateBasicInfo(
      title: _titleController.text,
      description: _descriptionController.text,
    );
    
    formState.updateLocation(
      address: _addressController.text,
      postalCode: _postalCodeController.text,
    );
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
                  'Basic Details',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter exhibition details and location information',
                  style: TextStyle(
                    color: AppTheme.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
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
            Column(
              children: [
                // Basic Information Section
                _buildSection(
                  'Basic Information',
                  Icons.info_outline,
                  [
                    _buildEditableTextField(
                      controller: _titleController,
                      label: 'Exhibition Title',
                      hint: 'Enter exhibition title',
                      fieldName: 'title',
                      isEditing: _isEditingTitle,
                      isEditMode: _isEditMode(),
                      onChanged: (_) => _updateForm(),
                    ),
                    const SizedBox(height: 16),
                    _buildEditableTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Enter exhibition description',
                      fieldName: 'description',
                      isEditing: _isEditingDescription,
                      isEditMode: _isEditMode(),
                      onChanged: (_) => _updateForm(),
                    ),
                    const SizedBox(height: 16),
                                         Consumer<ExhibitionFormState>(
                       builder: (context, formState, child) {
                         // Only show category value if it exists in the current categories list
                         String? categoryValue = formState.formData.categoryId;
                         if (categoryValue != null && !_categories.any((category) => category['id'] == categoryValue)) {
                           categoryValue = null; // Reset if category not in current list
                         }
                         
                         return _buildEditableDropdownField(
                      label: 'Category',
                           value: categoryValue,
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category['id'] as String,
                          child: Text(
                            category['name'] ?? '',
                            style: const TextStyle(color: AppTheme.gradientBlack),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        formState.updateBasicInfo(categoryId: value);
                           },
                      fieldName: 'category',
                      isEditing: _isEditingCategory,
                      isEditMode: _isEditMode(),
                         );
                      },
                    ),
                    const SizedBox(height: 16),
                                         Consumer<ExhibitionFormState>(
                       builder: (context, formState, child) {
                         // Only show event type value if it exists in the current event types list
                         String? eventTypeValue = formState.formData.eventTypeId;
                         if (eventTypeValue != null && !_eventTypes.any((eventType) => eventType['id'] == eventTypeValue)) {
                           eventTypeValue = null; // Reset if event type not in current list
                         }
                         
                         return _buildEditableDropdownField(
                      label: 'Event Type',
                           value: eventTypeValue,
                      items: _eventTypes.map((eventType) {
                        return DropdownMenuItem<String>(
                          value: eventType['id'] as String,
                          child: Text(
                            eventType['name'] ?? '',
                            style: const TextStyle(color: AppTheme.gradientBlack),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        formState.updateBasicInfo(eventTypeId: value);
                           },
                      fieldName: 'eventType',
                      isEditing: _isEditingEventType,
                      isEditMode: _isEditMode(),
                         );
                       },
                     ),
                    const SizedBox(height: 16),
                                         Consumer<ExhibitionFormState>(
                       builder: (context, formState, child) {
                         // Only show venue type value if it exists in the current venue types list
                         String? venueTypeValue = formState.formData.venueTypeId;
                         if (venueTypeValue != null && !_venueTypes.any((venueType) => venueType['id'] == venueTypeValue)) {
                           venueTypeValue = null; // Reset if venue type not in current list
                         }
                         
                         return _buildEditableDropdownField(
                           label: 'Venue Type',
                           value: venueTypeValue,
                           items: _venueTypes.map((venueType) {
                             return DropdownMenuItem<String>(
                               value: venueType['id'] as String,
                               child: Text(
                                 venueType['name'] ?? '',
                                 style: const TextStyle(color: AppTheme.gradientBlack),
                               ),
                             );
                           }).toList(),
                           onChanged: (value) {
                             formState.updateLocation(venueTypeId: value);
                           },
                      fieldName: 'venueType',
                      isEditing: _isEditingVenueType,
                      isEditMode: _isEditMode(),
                         );
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildEditableDateRangeField(),
                    const SizedBox(height: 16),
                    _buildEditableTimeFields(),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Location Section
                _buildSection(
                  'Location Information',
                  Icons.location_on,
                  [
                    _buildEditableTextField(
                      controller: _addressController,
                      label: 'Address',
                      hint: 'Enter venue address',
                      fieldName: 'address',
                      isEditing: _isEditingAddress,
                      isEditMode: _isEditMode(),
                      onChanged: (_) => _updateForm(),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildEditableTextField(
                            controller: _postalCodeController,
                            label: 'Postal Code',
                            hint: 'Enter postal code',
                            fieldName: 'postalCode',
                            isEditing: _isEditingPostalCode,
                            isEditMode: _isEditMode(),
                            onChanged: (_) => _updateForm(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Consumer<ExhibitionFormState>(
                            builder: (context, formState, child) {
                              return _buildEditableDropdownField(
                                label: 'Country',
                                value: formState.formData.country,
                                items: [
                                  DropdownMenuItem<String>(
                                    value: 'India',
                                    child: Text(
                                  'India',
                                      style: const TextStyle(color: AppTheme.gradientBlack),
                                  ),
                                ),
                              ],
                                onChanged: (value) {
                                  formState.updateLocation(country: value);
                                },
                      fieldName: 'country',
                      isEditing: _isEditingCountry,
                      isEditMode: _isEditMode(),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                                                              Consumer<ExhibitionFormState>(
                        builder: (context, formState, child) {
                          // Find the state ID that matches the current state name
                          String? stateValue;
                          if (formState.formData.state.isNotEmpty) {
                            final matchingState = _states.firstWhere(
                              (state) => state['name'] == formState.formData.state,
                              orElse: () => <String, dynamic>{},
                            );
                            stateValue = matchingState.isNotEmpty ? matchingState['id'] as String? : null;
                          }
                          
                          return _buildEditableDropdownField(
                            label: 'State',
                            value: stateValue,
                            items: _states.map((state) {
                              return DropdownMenuItem<String>(
                                value: state['id'] as String,
                                child: Text(
                                  state['name'] ?? '',
                                  style: const TextStyle(color: AppTheme.gradientBlack),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) async {
                              // Find the state name for the selected ID
                              final selectedState = _states.firstWhere(
                                (state) => state['id'] == value,
                                orElse: () => <String, dynamic>{},
                              );
                              final stateName = selectedState.isNotEmpty ? selectedState['name'] as String? : null;
                              
                              setState(() {
                                _selectedStateId = value;
                                _cities = []; // Clear cities when state changes
                              });
                              
                              if (stateName != null) {
                                // Load cities for selected state
                                print('Loading cities for state: $stateName');
                                final cities = await _loadCitiesForState(stateName);
                                print('Loaded ${cities.length} cities for state: $stateName');
                                if (mounted) {
                                  setState(() {
                                    _cities = cities;
                                  });
                                }
                              }
                              
                              formState.updateLocation(state: stateName);
                            },
                      fieldName: 'state',
                      isEditing: _isEditingState,
                      isEditMode: _isEditMode(),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                                                                  Consumer<ExhibitionFormState>(
                        builder: (context, formState, child) {
                          // Find the city ID that matches the current city name
                          String? cityValue;
                          if (formState.formData.city.isNotEmpty) {
                            final matchingCity = _cities.firstWhere(
                              (city) => city['name'] == formState.formData.city,
                              orElse: () => <String, dynamic>{},
                            );
                            cityValue = matchingCity.isNotEmpty ? matchingCity['id'] as String? : null;
                          }
                          
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'City',
                                      style: TextStyle(
                                        color: AppTheme.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  if (_isEditMode())
                                    IconButton(
                                      onPressed: () => _toggleEditState('city'),
                                      icon: Icon(
                                        _isEditingCity ? Icons.save : Icons.edit,
                                        color: _isEditingCity ? AppTheme.successGreen : AppTheme.primaryMaroon,
                                        size: 20,
                                      ),
                                      tooltip: _isEditingCity ? 'Save' : 'Edit',
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.white,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: cityValue,
                                  items: _cities.map((city) {
                                    return DropdownMenuItem<String>(
                                      value: city['id'] as String,
                                      child: Text(
                                        city['name'] ?? '',
                                        style: const TextStyle(color: AppTheme.gradientBlack),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (!_isEditMode() || _isEditingCity) && formState.formData.state.isNotEmpty
                                      ? (value) {
                                          // Find the city name for the selected ID
                                          final selectedCity = _cities.firstWhere(
                                            (city) => city['id'] == value,
                                            orElse: () => <String, dynamic>{},
                                          );
                                          final cityName = selectedCity.isNotEmpty ? selectedCity['name'] as String? : null;
                                          formState.updateLocation(city: cityName);
                                        }
                                      : null,
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.all(12),
                                    hintText: formState.formData.state.isEmpty 
                                        ? 'Please select a state first'
                                        : _cities.isEmpty 
                                            ? 'No cities available'
                                            : 'Select a city',
                                    hintStyle: TextStyle(
                                      color: AppTheme.textMediumGray,
                                      fontSize: 16,
                                    ),
                                  ),
                                  style: TextStyle(
                                    color: AppTheme.gradientBlack,
                                    fontSize: 16,
                                  ),
                                  dropdownColor: AppTheme.white,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down,
                                    color: AppTheme.gradientBlack,
                                  ),
                                  isExpanded: true,
                                  menuMaxHeight: 200,
                                ),
                              ),
                            ],
                          );
                      },
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
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
          Row(
            children: [
              Icon(icon, color: AppTheme.white, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: TextFormField(
            controller: controller,
            onChanged: onChanged,
            maxLines: maxLines,
            style: TextStyle(
              color: AppTheme.gradientBlack,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppTheme.gradientBlack.withOpacity(0.5),
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    String? value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items,
            onChanged: onChanged,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(12),
            ),
            style: TextStyle(
              color: AppTheme.gradientBlack,
              fontSize: 16,
            ),
            dropdownColor: AppTheme.white,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: AppTheme.gradientBlack,
            ),
            isExpanded: true,
            menuMaxHeight: 200,
          ),
        ),
      ],
    );
  }

  Widget _buildEditableDateRangeField() {
    return Consumer<ExhibitionFormState>(
      builder: (context, formState, child) {
        final startDate = formState.formData.startDate;
        final endDate = formState.formData.endDate;
        
        String displayText = 'Select date range';
        if (startDate != null && endDate != null) {
          displayText = '${_formatDate(startDate)} - ${_formatDate(endDate)}';
        }
        
        return _buildEditableDateTimeDisplay(
          label: 'Event Dates',
          displayText: displayText,
          fieldName: 'dates',
          isEditing: _isEditingDates,
          isEditMode: _isEditMode(),
          onTap: () async {
            final DateTimeRange? picked = await showDateRangePicker(
              context: context,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              initialDateRange: startDate != null && endDate != null
                  ? DateTimeRange(start: startDate, end: endDate)
                  : DateTimeRange(
                      start: DateTime.now().add(const Duration(days: 1)),
                      end: DateTime.now().add(const Duration(days: 3)),
                    ),
            );
            
            if (picked != null) {
              formState.updateBasicInfo(
                startDate: picked.start,
                endDate: picked.end,
              );
            }
          },
        );
      },
    );
  }

  Widget _buildDateRangeField() {
    return Consumer<ExhibitionFormState>(
      builder: (context, formState, child) {
        final startDate = formState.formData.startDate;
        final endDate = formState.formData.endDate;
        
        String displayText = 'Select date range';
        if (startDate != null && endDate != null) {
          displayText = '${_formatDate(startDate)} - ${_formatDate(endDate)}';
        }
        
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Event Dates',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () async {
              final DateTimeRange? picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDateRange: startDate != null && endDate != null
                        ? DateTimeRange(start: startDate, end: endDate)
                        : DateTimeRange(
                            start: DateTime.now().add(const Duration(days: 1)),
                            end: DateTime.now().add(const Duration(days: 3)),
                ),
              );
              
              if (picked != null) {
                formState.updateBasicInfo(
                  startDate: picked.start,
                  endDate: picked.end,
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: AppTheme.gradientBlack),
                  const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          displayText,
                    style: TextStyle(
                      color: AppTheme.gradientBlack,
                      fontSize: 16,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildEditableTimeFields() {
    return Consumer<ExhibitionFormState>(
      builder: (context, formState, child) {
        return Row(
          children: [
            Expanded(
              child: _buildEditableTimeField(
                label: 'Start Time',
                initialTime: formState.formData.startTime ?? const TimeOfDay(hour: 11, minute: 0),
                onChanged: (time) {
                  formState.updateBasicInfo(startTime: time);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildEditableTimeField(
                label: 'End Time',
                initialTime: formState.formData.endTime ?? const TimeOfDay(hour: 19, minute: 0),
                onChanged: (time) {
                  formState.updateBasicInfo(endTime: time);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEditableTimeField({
    required String label,
    required TimeOfDay initialTime,
    required Function(TimeOfDay?) onChanged,
  }) {
    return Consumer<ExhibitionFormState>(
      builder: (context, formState, child) {
        final currentTime = label == 'Start Time' 
            ? formState.formData.startTime ?? initialTime
            : formState.formData.endTime ?? initialTime;
        
        String displayText = 'Select time';
        if (currentTime != null) {
          displayText = '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}';
        }
        
        return _buildEditableDateTimeDisplay(
          label: label,
          displayText: displayText,
          fieldName: 'times',
          isEditing: _isEditingTimes,
          isEditMode: _isEditMode(),
          onTap: () async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: currentTime,
            );
            
            if (picked != null) {
              onChanged(picked);
            }
          },
        );
      },
    );
  }

  Widget _buildTimeFields() {
    return Consumer<ExhibitionFormState>(
      builder: (context, formState, child) {
    return Row(
      children: [
        Expanded(
          child: _buildTimeField(
            label: 'Start Time',
                initialTime: formState.formData.startTime ?? const TimeOfDay(hour: 11, minute: 0),
            onChanged: (time) {
              formState.updateBasicInfo(startTime: time);
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildTimeField(
            label: 'End Time',
                initialTime: formState.formData.endTime ?? const TimeOfDay(hour: 19, minute: 0),
            onChanged: (time) {
              formState.updateBasicInfo(endTime: time);
            },
          ),
        ),
      ],
        );
      },
    );
  }

  Widget _buildTimeField({
    required String label,
    required TimeOfDay initialTime,
    required Function(TimeOfDay?) onChanged,
  }) {
    return Consumer<ExhibitionFormState>(
      builder: (context, formState, child) {
        final currentTime = label == 'Start Time' 
            ? formState.formData.startTime ?? initialTime
            : formState.formData.endTime ?? initialTime;
        
        String displayText = 'Select time';
        if (currentTime != null) {
          displayText = '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}';
        }
        
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: InkWell(
            onTap: () async {
              final TimeOfDay? picked = await showTimePicker(
                context: context,
                    initialTime: currentTime,
              );
              
              if (picked != null) {
                onChanged(picked);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: AppTheme.gradientBlack),
                  const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          displayText,
                    style: TextStyle(
                      color: AppTheme.gradientBlack,
                      fontSize: 16,
                    ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
        );
      },
    );
  }
}
