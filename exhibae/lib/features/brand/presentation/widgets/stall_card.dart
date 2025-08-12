import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class StallCard extends StatelessWidget {
  final Map<String, dynamic> stall;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onShowLayout;

  const StallCard({
    super.key,
    required this.stall,
    this.isSelected = false,
    required this.onSelect,
    required this.onShowLayout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? AppTheme.primaryBlue : AppTheme.backgroundLightGray,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Stall Size Badge
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                _getStallSize(stall),
                style: const TextStyle(
                  color: AppTheme.primaryBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Price Section
            Row(
              children: [
                Icon(
                  Icons.attach_money,
                  color: AppTheme.secondaryGold,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _getStallPrice(stall),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDarkCharcoal,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 6),
            
            // Availability Section
            Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  color: AppTheme.primaryBlue,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${_getAvailableInstanceCount(stall)} of ${_getTotalInstanceCount(stall)} available',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.textMediumGray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Amenities Section (if available) - Limited to 2 amenities
            if (_getStallAmenities(stall).isNotEmpty) ...[
              const Text(
                'Amenities:',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textDarkCharcoal,
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 3,
                runSpacing: 3,
                children: _getStallAmenities(stall).take(2).map((amenity) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundLightGray,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: AppTheme.textMediumGray.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      amenity,
                      style: const TextStyle(
                        fontSize: 8,
                        color: AppTheme.textMediumGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
            
            const Spacer(),
            
            // Show Layout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onShowLayout,
                icon: Icon(
                  Icons.grid_view,
                  size: 14,
                  color: AppTheme.white,
                ),
                label: Text(
                  'Show Layout',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isSelected ? AppTheme.secondaryGold : AppTheme.primaryBlue,
                  foregroundColor: AppTheme.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  elevation: 1,
                ),
              ),
            ),
            
            // Selection Status (if selected)
            if (isSelected) ...[
              const SizedBox(height: 4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'Selected',
                  style: TextStyle(
                    fontSize: 8,
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStallSize(Map<String, dynamic> stall) {
    final length = stall['length']?.toString() ?? '0';
    final width = stall['width']?.toString() ?? '0';
    final unit = stall['unit'] is Map<String, dynamic> 
        ? (stall['unit']['symbol'] ?? 'm')
        : 'm';
    return '${length} × ${width} ${unit}';
  }

  String _getStallPrice(Map<String, dynamic> stall) {
    final price = stall['price']?.toString() ?? '0';
    return '₹$price';
  }

  int _getAvailableInstanceCount(Map<String, dynamic> stall) {
    final instances = stall['instances'] as List<dynamic>?;
    if (instances == null) return 0;
    
    return instances.where((instance) => 
      instance['status'] == 'available'
    ).length;
  }

  int _getTotalInstanceCount(Map<String, dynamic> stall) {
    final instances = stall['instances'] as List<dynamic>?;
    if (instances == null) return 0;
    
    return instances.length;
  }

  List<String> _getStallAmenities(Map<String, dynamic> stall) {
    final amenities = stall['amenities'];
    if (amenities is List) {
      return amenities.where((item) {
        if (item is Map<String, dynamic>) {
          final amenity = item['amenity'];
          return amenity is Map<String, dynamic> && amenity['name'] != null;
        }
        return false;
      }).map((item) {
        final amenity = item['amenity'] as Map<String, dynamic>;
        return amenity['name']?.toString() ?? '';
      }).where((name) => name.isNotEmpty).toList();
    }
    return [];
  }
}
