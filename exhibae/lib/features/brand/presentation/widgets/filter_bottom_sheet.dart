import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  RangeValues _priceRange = const RangeValues(0, 500000);
  RangeValues _distanceRange = const RangeValues(0, 100);
  List<String> _selectedCategories = [];
  List<String> _selectedDates = [];
  bool _onlyAvailableStalls = false;

  final List<String> _categories = [
    'Fashion',
    'Technology',
    'Food & Beverage',
    'Healthcare',
    'Automotive',
    'Education',
    'Real Estate',
    'Finance',
    'Entertainment',
    'Sports',
  ];

  final List<String> _dateOptions = [
    'This Week',
    'This Month',
    'Next 3 Months',
    'Next 6 Months',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppTheme.backgroundLightGray),
              ),
            ),
            child: Row(
              children: [
                const Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDarkCharcoal,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text(
                    'Clear All',
                    style: TextStyle(
                      color: AppTheme.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range
                  _buildSectionTitle('Date Range'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _dateOptions.map((date) {
                      final isSelected = _selectedDates.contains(date);
                      return FilterChip(
                        label: Text(date),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedDates.add(date);
                            } else {
                              _selectedDates.remove(date);
                            }
                          });
                        },
                        backgroundColor: AppTheme.backgroundLightGray,
                        selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.primaryBlue : AppTheme.textDarkCharcoal,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Categories
                  _buildSectionTitle('Categories'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                        backgroundColor: AppTheme.backgroundLightGray,
                        selectedColor: AppTheme.primaryBlue.withOpacity(0.2),
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.primaryBlue : AppTheme.textDarkCharcoal,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Distance
                  _buildSectionTitle('Distance (${_distanceRange.end.round()}km)'),
                  const SizedBox(height: 12),
                  RangeSlider(
                    values: _distanceRange,
                    min: 0,
                    max: 100,
                    divisions: 20,
                    labels: RangeLabels(
                      '${_distanceRange.start.round()}km',
                      '${_distanceRange.end.round()}km',
                    ),
                    onChanged: (RangeValues values) {
                      setState(() {
                        _distanceRange = values;
                      });
                    },
                    activeColor: AppTheme.primaryBlue,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Price Range
                  _buildSectionTitle('Price Range (₹${_priceRange.start.round().toStringAsFixed(0)} - ₹${_priceRange.end.round().toStringAsFixed(0)})'),
                  const SizedBox(height: 12),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 500000,
                    divisions: 50,
                    labels: RangeLabels(
                      '₹${_priceRange.start.round().toStringAsFixed(0)}',
                      '₹${_priceRange.end.round().toStringAsFixed(0)}',
                    ),
                    onChanged: (RangeValues values) {
                      setState(() {
                        _priceRange = values;
                      });
                    },
                    activeColor: AppTheme.primaryBlue,
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Only Available Stalls
                  Row(
                    children: [
                      Checkbox(
                        value: _onlyAvailableStalls,
                        onChanged: (value) {
                          setState(() {
                            _onlyAvailableStalls = value ?? false;
                          });
                        },
                        activeColor: AppTheme.primaryBlue,
                      ),
                      const Expanded(
                        child: Text(
                          'Only show available stalls',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textDarkCharcoal,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Action Buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppTheme.backgroundLightGray),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryBlue),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: AppTheme.primaryBlue),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _applyFilters,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: AppTheme.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppTheme.textDarkCharcoal,
      ),
    );
  }

  void _clearFilters() {
    setState(() {
      _selectedCategories.clear();
      _selectedDates.clear();
      _priceRange = const RangeValues(0, 500000);
      _distanceRange = const RangeValues(0, 100);
      _onlyAvailableStalls = false;
    });
  }

  void _applyFilters() {
    // TODO: Apply filters and close bottom sheet
    Navigator.pop(context);
  }
}
