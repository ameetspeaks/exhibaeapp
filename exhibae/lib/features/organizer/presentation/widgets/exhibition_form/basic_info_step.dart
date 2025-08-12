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
  final _expectedVisitorsController = TextEditingController();
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
    _expectedVisitorsController.dispose();
    super.dispose();
  }

  void _loadFormData() {
    final formState = Provider.of<ExhibitionFormState>(context, listen: false);
    _titleController.text = formState.formData.title;
    _descriptionController.text = formState.formData.description;
    _expectedVisitorsController.text = formState.formData.expectedVisitors?.toString() ?? '';
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
            'Enter the basic details about your exhibition',
            style: TextStyle(
              color: AppTheme.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          
          // Title Field
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
              controller: _titleController,
              style: const TextStyle(color: AppTheme.white),
              onChanged: (value) {
                Provider.of<ExhibitionFormState>(context, listen: false).updateBasicInfo(
                  title: value,
                );
              },
              decoration: InputDecoration(
                labelText: 'Exhibition Title',
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
                Provider.of<ExhibitionFormState>(context, listen: false).updateBasicInfo(
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
          
          // Category Dropdown
          if (_isLoadingData)
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
              child: Consumer<ExhibitionFormState>(
                builder: (context, state, child) {
                  return DropdownButtonFormField<String>(
                    value: state.formData.categoryId,
                    items: _categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category['id'] as String,
                        child: Text(
                          category['name'] as String,
                          style: const TextStyle(color: AppTheme.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      state.updateBasicInfo(categoryId: value);
                    },
                    dropdownColor: AppTheme.gradientBlack,
                    style: const TextStyle(color: AppTheme.white),
                    decoration: InputDecoration(
                      labelText: 'Category',
                      labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            
            // Event Type Dropdown
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
                    value: state.formData.eventTypeId,
                    items: _eventTypes.map((type) {
                      return DropdownMenuItem<String>(
                        value: type['id'] as String,
                        child: Text(
                          type['name'] as String,
                          style: const TextStyle(color: AppTheme.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      state.updateBasicInfo(eventTypeId: value);
                    },
                    dropdownColor: AppTheme.gradientBlack,
                    style: const TextStyle(color: AppTheme.white),
                    decoration: InputDecoration(
                      labelText: 'Event Type',
                      labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Date Range
          Consumer<ExhibitionFormState>(
            builder: (context, state, child) {
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.white.withOpacity(0.2),
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
                              colorScheme: ColorScheme.dark(
                                primary: AppTheme.white,
                                onPrimary: AppTheme.gradientBlack,
                                surface: AppTheme.gradientBlack,
                                onSurface: AppTheme.white,
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
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Exhibition Dates',
                            style: TextStyle(
                              color: AppTheme.white.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: AppTheme.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                state.formData.startDate != null && state.formData.endDate != null
                                    ? '${_formatDate(state.formData.startDate!)} - ${_formatDate(state.formData.endDate!)}'
                                    : 'Select dates',
                                style: const TextStyle(
                                  color: AppTheme.white,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          
          // Expected Visitors Field
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
              controller: _expectedVisitorsController,
              style: const TextStyle(color: AppTheme.white),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                Provider.of<ExhibitionFormState>(context, listen: false).updateBasicInfo(
                  expectedVisitors: int.tryParse(value),
                );
              },
              decoration: InputDecoration(
                labelText: 'Expected Visitors',
                labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
