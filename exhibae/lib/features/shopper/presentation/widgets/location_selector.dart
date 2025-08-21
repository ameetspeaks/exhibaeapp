import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class LocationSelector extends StatelessWidget {
  final String selectedLocation;
  final Function(String) onLocationChanged;
  final bool showLabel;

  const LocationSelector({
    super.key,
    required this.selectedLocation,
    required this.onLocationChanged,
    this.showLabel = true,
  });

  static const List<String> locations = [
    'All Locations',
    'Gautam Buddha Nagar',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(
            'Location',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryMaroon,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppTheme.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLightGray),
          ),
                       child: DropdownButtonFormField<String>(
               value: selectedLocation,
               onChanged: (value) {
                 if (value != null) {
                   onLocationChanged(value);
                 }
               },
               decoration: InputDecoration(
                 hintText: 'Select Location',
                 hintStyle: TextStyle(
                   color: AppTheme.textMediumGray,
                   fontSize: 16,
                   fontFamily: AppTheme.fontFamily,
                 ),
                 prefixIcon: Icon(
                   Icons.location_on_outlined,
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
               isExpanded: true, // This prevents overflow
               items: locations.map((location) {
                 return DropdownMenuItem<String>(
                   value: location,
                   child: Text(
                     location,
                     overflow: TextOverflow.ellipsis, // Handle long text
                     style: TextStyle(
                       color: location == selectedLocation 
                           ? AppTheme.primaryMaroon 
                           : AppTheme.textMediumGray,
                       fontSize: 16,
                       fontFamily: AppTheme.fontFamily,
                     ),
                   ),
                 );
               }).toList(),
             ),
        ),
      ],
    );
  }
}
