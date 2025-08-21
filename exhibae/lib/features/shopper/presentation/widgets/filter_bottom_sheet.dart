import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';

class FilterBottomSheet extends StatefulWidget {
  final String selectedCategory;
  final String selectedLocation;
  final String selectedDateRange;
  final Function(String, String, String) onApply;

  const FilterBottomSheet({
    super.key,
    required this.selectedCategory,
    required this.selectedLocation,
    required this.selectedDateRange,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  late String _selectedCategory;
  late String _selectedLocation;
  late String _selectedDateRange;
  List<String> _availableCities = ['All', 'Gautam Buddha Nagar'];
  bool _isLoadingCities = true;

  static const List<String> categories = [
    'All',
    'Fashion',
    'Technology',
    'Art',
    'Food',
    'Business',
    'Education',
    'Entertainment',
    'Sports',
    'Other',
  ];

  static const List<String> dateRanges = [
    'All',
    'Today',
    'This Week',
    'This Month',
    'Next Month',
    'Next 3 Months',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
    _selectedLocation = widget.selectedLocation;
    _selectedDateRange = widget.selectedDateRange;
    _loadCities();
  }

  Future<void> _loadCities() async {
    try {
      // Load cities that have exhibitions from exhibitions table
      final citiesData = await _supabaseService.client
          .from('exhibitions')
          .select('city')
          .eq('status', 'approved')
          .not('city', 'is', null);

      final cities = citiesData
          .map((item) => item['city'] as String)
          .where((city) => city.isNotEmpty)
          .toSet()
          .toList()
        ..sort();

      setState(() {
        _availableCities = ['All', 'Gautam Buddha Nagar', ...cities];
        _isLoadingCities = false;
      });
    } catch (e) {
      // If loading cities fails, use default list
      setState(() {
        _availableCities = ['All', 'Gautam Buddha Nagar'];
        _isLoadingCities = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Filter Exhibitions',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.primaryMaroon,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(
                  Icons.close,
                  color: AppTheme.primaryMaroon,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Category Filter
          _buildFilterSection(
            title: 'Category',
            options: categories,
            selectedValue: _selectedCategory,
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
              });
            },
          ),
          const SizedBox(height: 24),
          
          // Location Filter
          _buildFilterSection(
            title: 'Location',
            options: _availableCities,
            selectedValue: _selectedLocation,
            onChanged: (value) {
              setState(() {
                _selectedLocation = value;
              });
            },
          ),
          const SizedBox(height: 24),
          
          // Date Range Filter
          _buildFilterSection(
            title: 'Date Range',
            options: dateRanges,
            selectedValue: _selectedDateRange,
            onChanged: (value) {
              setState(() {
                _selectedDateRange = value;
              });
            },
          ),
          const SizedBox(height: 32),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetFilters,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryMaroon,
                    side: BorderSide(color: AppTheme.primaryMaroon),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Reset',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryMaroon,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFilterSection({
    required String title,
    required List<String> options,
    required String selectedValue,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppTheme.primaryMaroon,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = option == selectedValue;
            return GestureDetector(
              onTap: () => onChanged(option),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryMaroon : AppTheme.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryMaroon : AppTheme.borderLightGray,
                    width: 1.5,
                  ),
                ),
                child: Text(
                  option,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected ? Colors.white : AppTheme.primaryMaroon,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }



  void _resetFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedLocation = 'All';
      _selectedDateRange = 'All';
    });
  }

  void _applyFilters() {
    widget.onApply(_selectedCategory, _selectedLocation, _selectedDateRange);
  }
}
