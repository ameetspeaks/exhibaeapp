import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/supabase_service.dart';
import '../../../domain/models/exhibition_form_state.dart';

class BasicInfoStep extends StatefulWidget {
  const BasicInfoStep({super.key});

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _eventTypes = [];
  bool _isLoadingData = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFormData();
    _loadDropdownData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadFormData() {
    final formState = Provider.of<ExhibitionFormState>(context, listen: false);
    _titleController.text = formState.formData.title;
    _descriptionController.text = formState.formData.description;
  }

  Future<void> _loadDropdownData() async {
    try {
      final categoriesResponse = await _supabaseService.client
          .from('exhibition_categories')
          .select()
          .order('name');
      
      final eventTypesResponse = await _supabaseService.client
          .from('event_types')
          .select()
          .order('name');

      if (mounted) {
        setState(() {
          _categories = List<Map<String, dynamic>>.from(categoriesResponse);
          _eventTypes = List<Map<String, dynamic>>.from(eventTypesResponse);
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
                  'Basic Information',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter the basic details about your exhibition',
                  style: TextStyle(
                    color: AppTheme.white.withOpacity(0.8),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Title Field
          _buildFormField(
            label: 'Exhibition Title',
            hint: 'Enter exhibition title',
            controller: _titleController,
            onChanged: (value) {
              Provider.of<ExhibitionFormState>(context, listen: false).updateBasicInfo(
                title: value,
              );
            },
          ),
          const SizedBox(height: 20),
          
          // Description Field
          _buildFormField(
            label: 'Description',
            hint: 'Enter exhibition description',
            controller: _descriptionController,
            maxLines: 4,
            onChanged: (value) {
              Provider.of<ExhibitionFormState>(context, listen: false).updateBasicInfo(
                description: value,
              );
            },
          ),
          const SizedBox(height: 20),
          
          // Category and Event Type Row - Fixed overflow
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
          else ...[
            // Responsive layout for Category and Event Type
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 600) {
                  // Wide screen - side by side
                  return Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField(
                          label: 'Category',
                          hint: 'Select category',
                          value: Provider.of<ExhibitionFormState>(context).formData.categoryId,
                          items: _categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category['id'] as String,
                              child: Text(
                                category['name'] as String,
                                style: const TextStyle(color: AppTheme.gradientBlack, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            Provider.of<ExhibitionFormState>(context, listen: false).updateBasicInfo(categoryId: value);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDropdownField(
                          label: 'Event Type',
                          hint: 'Select event type',
                          value: Provider.of<ExhibitionFormState>(context).formData.eventTypeId,
                          items: _eventTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type['id'] as String,
                              child: Text(
                                type['name'] as String,
                                style: const TextStyle(color: AppTheme.gradientBlack, fontSize: 16),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            Provider.of<ExhibitionFormState>(context, listen: false).updateBasicInfo(eventTypeId: value);
                          },
                        ),
                      ),
                    ],
                  );
                } else {
                  // Narrow screen - stacked
                  return Column(
                    children: [
                      _buildDropdownField(
                        label: 'Category',
                        hint: 'Select category',
                        value: Provider.of<ExhibitionFormState>(context).formData.categoryId,
                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category['id'] as String,
                            child: Text(
                              category['name'] as String,
                              style: const TextStyle(color: AppTheme.gradientBlack, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          Provider.of<ExhibitionFormState>(context, listen: false).updateBasicInfo(categoryId: value);
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildDropdownField(
                        label: 'Event Type',
                        hint: 'Select event type',
                        value: Provider.of<ExhibitionFormState>(context).formData.eventTypeId,
                        items: _eventTypes.map((type) {
                          return DropdownMenuItem<String>(
                            value: type['id'] as String,
                            child: Text(
                              type['name'] as String,
                              style: const TextStyle(color: AppTheme.gradientBlack, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          Provider.of<ExhibitionFormState>(context, listen: false).updateBasicInfo(eventTypeId: value);
                        },
                      ),
                    ],
                  );
                }
              },
            ),
            const SizedBox(height: 20),
          ],
          
          // Date Range Section - Fixed calendar view
          Consumer<ExhibitionFormState>(
            builder: (context, state, child) {
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final dateRange = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                        initialDateRange: state.formData.startDate != null && state.formData.endDate != null
                            ? DateTimeRange(
                                start: state.formData.startDate!,
                                end: state.formData.endDate!,
                              )
                            : null,
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: ColorScheme.light(
                                primary: AppTheme.gradientBlack,
                                onPrimary: AppTheme.white,
                                surface: AppTheme.white,
                                onSurface: AppTheme.gradientBlack,
                                brightness: Brightness.light,
                              ),
                              dialogBackgroundColor: AppTheme.white,
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppTheme.gradientBlack,
                                ),
                              ),
                              elevatedButtonTheme: ElevatedButtonThemeData(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.gradientBlack,
                                  foregroundColor: AppTheme.white,
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (dateRange != null) {
                        state.updateBasicInfo(
                          startDate: dateRange.start,
                          endDate: dateRange.end,
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: AppTheme.gradientBlack,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Exhibition Dates',
                                style: TextStyle(
                                  color: AppTheme.gradientBlack,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.gradientBlack.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppTheme.gradientBlack.withOpacity(0.1),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Start Date',
                                        style: TextStyle(
                                          color: AppTheme.gradientBlack.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        state.formData.startDate != null
                                            ? _formatDate(state.formData.startDate!)
                                            : 'Not set',
                                        style: TextStyle(
                                          color: AppTheme.gradientBlack,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 40,
                                  color: AppTheme.gradientBlack.withOpacity(0.2),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'End Date',
                                        style: TextStyle(
                                          color: AppTheme.gradientBlack.withOpacity(0.7),
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        state.formData.endDate != null
                                            ? _formatDate(state.formData.endDate!)
                                            : 'Not set',
                                        style: TextStyle(
                                          color: AppTheme.gradientBlack,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap to select exhibition dates',
                            style: TextStyle(
                              color: AppTheme.gradientBlack.withOpacity(0.6),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          
          // Time and Application Deadline Section
          Consumer<ExhibitionFormState>(
            builder: (context, state, child) {
              return Column(
                children: [
                  // Time Selection
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: AppTheme.gradientBlack,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Exhibition Times',
                                style: TextStyle(
                                  color: AppTheme.gradientBlack,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimeField(
                                  label: 'Start Time',
                                  time: state.formData.startTime,
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: state.formData.startTime,
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: ColorScheme.light(
                                              primary: AppTheme.gradientBlack,
                                              onPrimary: AppTheme.white,
                                              surface: AppTheme.white,
                                              onSurface: AppTheme.gradientBlack,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (time != null) {
                                      state.updateBasicInfo(startTime: time);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildTimeField(
                                  label: 'End Time',
                                  time: state.formData.endTime,
                                  onTap: () async {
                                    final time = await showTimePicker(
                                      context: context,
                                      initialTime: state.formData.endTime,
                                      builder: (context, child) {
                                        return Theme(
                                          data: Theme.of(context).copyWith(
                                            colorScheme: ColorScheme.light(
                                              primary: AppTheme.gradientBlack,
                                              onPrimary: AppTheme.white,
                                              surface: AppTheme.white,
                                              onSurface: AppTheme.gradientBlack,
                                            ),
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );
                                    if (time != null) {
                                      state.updateBasicInfo(endTime: time);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Application Deadline
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.white.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate: state.formData.startDate ?? DateTime.now().add(const Duration(days: 365)),
                            initialDate: state.formData.applicationDeadline ?? DateTime.now().add(const Duration(days: 30)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: AppTheme.gradientBlack,
                                    onPrimary: AppTheme.white,
                                    surface: AppTheme.white,
                                    onSurface: AppTheme.gradientBlack,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (date != null) {
                            state.updateBasicInfo(applicationDeadline: date);
                          }
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.event_note,
                                    color: AppTheme.gradientBlack,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Application Deadline',
                                    style: TextStyle(
                                      color: AppTheme.gradientBlack,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                state.formData.applicationDeadline != null
                                    ? _formatDate(state.formData.applicationDeadline!)
                                    : 'Not set',
                                style: TextStyle(
                                  color: AppTheme.gradientBlack.withOpacity(0.7),
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to set application deadline',
                                style: TextStyle(
                                  color: AppTheme.gradientBlack.withOpacity(0.6),
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildTimeField({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.gradientBlack.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.gradientBlack.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: AppTheme.gradientBlack.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: AppTheme.gradientBlack,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
