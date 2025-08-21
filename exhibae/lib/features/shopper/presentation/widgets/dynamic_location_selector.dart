import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class DynamicLocationSelector extends StatefulWidget {
  final String selectedLocation;
  final List<String> availableCities;
  final Function(String) onLocationChanged;
  final bool showLabel;
  final bool isLoading;

  const DynamicLocationSelector({
    super.key,
    required this.selectedLocation,
    required this.availableCities,
    required this.onLocationChanged,
    this.showLabel = true,
    this.isLoading = false,
  });

  @override
  State<DynamicLocationSelector> createState() => _DynamicLocationSelectorState();
}

class _DynamicLocationSelectorState extends State<DynamicLocationSelector> {
  String _searchQuery = '';
  List<String> _filteredCities = [];

  @override
  void initState() {
    super.initState();
    _filteredCities = widget.availableCities.toSet().toList(); // Remove duplicates
  }

  @override
  void didUpdateWidget(DynamicLocationSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.availableCities != widget.availableCities) {
      _filterCities();
    }
  }

  void _filterCities() {
    // Remove duplicates from available cities first
    final uniqueCities = widget.availableCities.toSet().toList();
    
    if (_searchQuery.isEmpty) {
      setState(() {
        _filteredCities = uniqueCities;
      });
    } else {
      setState(() {
        _filteredCities = uniqueCities
            .where((city) => city.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
      });
    }
    
    // Ensure selected location is always in the list (but only if it's not already there)
    if (widget.selectedLocation.isNotEmpty && 
        !_filteredCities.contains(widget.selectedLocation) &&
        uniqueCities.contains(widget.selectedLocation)) {
      _filteredCities.insert(0, widget.selectedLocation);
    }
    
    // Debug print
    print('Search Query: $_searchQuery');
    print('Available Cities: ${widget.availableCities}');
    print('Unique Cities: $uniqueCities');
    print('Filtered Cities: $_filteredCities');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel) ...[
          Text(
            'Location',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryMaroon,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        
        // Location Dropdown with Search
        Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLightGray),
          ),
          child: DropdownButtonFormField<String>(
            menuMaxHeight: 300, // Limit dropdown height
            value: _filteredCities.contains(widget.selectedLocation) 
                ? widget.selectedLocation 
                : (_filteredCities.isNotEmpty ? _filteredCities.first : null),
            onChanged: widget.isLoading ? null : (value) {
              if (value != null) {
                widget.onLocationChanged(value);
              }
            },
            decoration: InputDecoration(
              hintText: widget.isLoading ? 'Loading cities...' : 'Select Location',
              hintStyle: TextStyle(
                color: AppTheme.textMediumGray,
                fontSize: 16,
                fontFamily: AppTheme.fontFamily,
              ),
              prefixIcon: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
                      ),
                    ),
                  )
                : Icon(
                    Icons.location_on_outlined,
                    color: AppTheme.primaryMaroon,
                    size: 20,
                  ),
              suffixIcon: Icon(
                Icons.search,
                color: AppTheme.primaryMaroon,
                size: 20,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: TextStyle(
              color: AppTheme.primaryMaroon,
              fontSize: 16,
              fontFamily: AppTheme.fontFamily,
            ),
            dropdownColor: AppTheme.white,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: AppTheme.primaryMaroon,
            ),
            isExpanded: true,
            items: [
              // Search field as first item
              DropdownMenuItem<String>(
                enabled: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                      _filterCities();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search cities...',
                      hintStyle: TextStyle(
                        color: AppTheme.textMediumGray,
                        fontSize: 14,
                        fontFamily: AppTheme.fontFamily,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.borderLightGray),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    style: TextStyle(
                      color: AppTheme.primaryMaroon,
                      fontSize: 14,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                ),
              ),
              // Divider
              DropdownMenuItem<String>(
                enabled: false,
                child: Divider(color: AppTheme.borderLightGray),
              ),
              // Filtered cities (ensure no duplicates)
              ..._filteredCities.toSet().map((location) {
                return DropdownMenuItem<String>(
                  value: location,
                  child: Text(
                    location,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: location == widget.selectedLocation
                          ? AppTheme.primaryMaroon
                          : AppTheme.textMediumGray,
                      fontSize: 16,
                      fontFamily: AppTheme.fontFamily,
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }
}
