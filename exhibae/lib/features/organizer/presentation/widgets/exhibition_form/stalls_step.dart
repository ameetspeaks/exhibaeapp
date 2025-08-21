import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'dart:math' as math;
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/supabase_service.dart';
import '../../../domain/models/exhibition_form_state.dart';

class StallsStep extends StatefulWidget {
  const StallsStep({super.key});

  @override
  State<StallsStep> createState() => _StallsStepState();
}

class _StallsStepState extends State<StallsStep> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  final Uuid _uuid = Uuid();
  
  List<Map<String, dynamic>> _measurementUnits = [];
  List<Map<String, dynamic>> _amenities = [];
  List<Map<String, dynamic>> _existingStallInstances = [];
  bool _isLoadingData = true;
  String? _error;
  
  // Layout bounds for existing stalls display
  Size _existingLayoutBounds = Size.zero;
  Offset _existingLayoutCenter = Offset.zero;

  @override
  void initState() {
    super.initState();
    _loadData();
    _loadExistingStallInstances();
  }

  Future<void> _loadData() async {
    try {
      // Get measurement units directly (don't try to create new ones)
        print('DEBUG: Fetching measurement units...');
        
        // Try direct query first to see if RLS is the issue
        try {
          final directResponse = await _supabaseService.client
              .from('measurement_units')
              .select('*');
          print('DEBUG: Direct query returned ${directResponse.length} units');
          for (var unit in directResponse) {
            print('DEBUG: Direct unit: ${unit['name']} - ${unit['symbol']} - ${unit['type']}');
          }
        } catch (e) {
          print('DEBUG: Direct query failed: $e');
        }
        
        // Get all measurement units (don't filter by type since we want to use whatever is available)
        final measurementUnitsResponse = await _supabaseService.getMeasurementUnits();
        print('DEBUG: Fetched ${measurementUnitsResponse.length} measurement units');
        
        // Use all available units
        final unitsToUse = measurementUnitsResponse;
       
      final amenitiesResponse = await _supabaseService.getAmenities();

      print('Measurement units loaded: ${measurementUnitsResponse.length}');
      print('Amenities loaded: ${amenitiesResponse.length}');
      
                                  // Debug: Print the measurement units to see what we got
       print('=== MEASUREMENT UNITS DEBUG ===');
        print('Units found: ${measurementUnitsResponse.length}');
        for (var unit in measurementUnitsResponse) {
         print('Unit: ${unit['name']} - ${unit['symbol']} - ${unit['type']} - ID: ${unit['id']}');
       }
       print('=== AMENITIES DEBUG ===');
       for (var amenity in amenitiesResponse) {
         print('Amenity: ${amenity['name']} - ID: ${amenity['id']}');
       }
       print('==============================');

                            // Use the units we found (either area units or all units)
        if (unitsToUse.isEmpty) {
          print('No measurement units found in database at all');
          // Don't create fallback units - let the user know they need to contact support
        } else {
          print('Using ${unitsToUse.length} measurement units');
      }

      if (mounted) {
        setState(() {
          _measurementUnits = unitsToUse;
          _amenities = amenitiesResponse;
          _isLoadingData = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _error = 'Failed to load measurement units and amenities. Please try again.';
          _isLoadingData = false;
        });
      }
    }
  }

  void _addStall() {
    final formState = Provider.of<ExhibitionFormState>(context, listen: false);
    final newStall = {
      'id': _uuid.v4(), // Use UUID for temporary identification
      'name': '',
      'length': null, // Allow null for empty input
      'width': null, // Allow null for empty input
      'unit_id': _measurementUnits.isNotEmpty ? _measurementUnits.first['id'] : null,
      'price': null, // Allow null for empty input
      'quantity': 1,
      'amenities': <String>[],
    };
    
    final updatedStalls = List<Map<String, dynamic>>.from(formState.formData.stalls);
    updatedStalls.add(newStall);
    formState.updateStalls(updatedStalls);
  }

  void _removeStall(int index) {
    final formState = Provider.of<ExhibitionFormState>(context, listen: false);
    final updatedStalls = List<Map<String, dynamic>>.from(formState.formData.stalls);
    updatedStalls.removeAt(index);
    formState.updateStalls(updatedStalls);
  }

  void _updateStall(int index, Map<String, dynamic> updatedStall) {
    final formState = Provider.of<ExhibitionFormState>(context, listen: false);
    final updatedStalls = List<Map<String, dynamic>>.from(formState.formData.stalls);
    updatedStalls[index] = updatedStall;
    formState.updateStalls(updatedStalls);
  }

  bool _canGenerateLayout(List<Map<String, dynamic>> stalls) {
    for (final stall in stalls) {
      if (stall['name']?.toString().isEmpty ?? true) return false;
      if (stall['length'] == null || stall['width'] == null) return false;
      if (stall['price'] == null) return false;
      if (stall['unit_id'] == null) return false;
    }
    return true;
  }

  Future<void> _generateLayout() async {
    try {
      final formState = Provider.of<ExhibitionFormState>(context, listen: false);
      final stalls = formState.formData.stalls;
      
      if (stalls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No stalls to generate layout for'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }

      // Show loading dialog
    showDialog(
      context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: AppTheme.white,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryMaroon),
                ),
                const SizedBox(height: 16),
                Text(
                  'Generating stall layout...',
                  style: TextStyle(
                    color: AppTheme.gradientBlack,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

                    // Generate layout locally since we don't have real stall IDs yet
       print('DEBUG: Generating layout for ${stalls.length} stalls');
       final layout = _generateLayoutLocally(stalls, formState.formData.id!);
       print('DEBUG: Generated layout with ${layout.length} instances');

      // Close loading dialog
      Navigator.of(context).pop();

      if (layout.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate layout'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }

             // Save layout to database
       print('DEBUG: About to save layout to database. Layout length: ${layout.length}');
       await _saveLayoutToDatabase(layout);
       print('DEBUG: Layout saved successfully');

               // Show layout preview dialog with data from database
        await _showLayoutPreviewDialog();

       // Show success message
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text('Stall layout generated successfully! ${layout.length} instances created.'),
           backgroundColor: Colors.green,
         ),
       );

    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating layout: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

           List<Map<String, dynamic>> _generateLayoutLocally(List<Map<String, dynamic>> stalls, String exhibitionId) {
      List<Map<String, dynamic>> layout = [];
      double currentX = 50.0;
      double currentY = 50.0;
      double maxHeightInRow = 0;
      double totalWidth = 800.0; // Assuming a standard layout width
      double spacing = 20.0;
      
      for (final stall in stalls) {
        final quantity = stall['quantity'] as int? ?? 1;
        final length = (stall['length'] as num?)?.toDouble() ?? 0.0;
        final width = (stall['width'] as num?)?.toDouble() ?? 0.0;
        
        for (int i = 0; i < quantity; i++) {
          // Check if we need to move to next row
          if (currentX + length > totalWidth - 50) {
            currentX = 50;
            currentY += maxHeightInRow + spacing;
            maxHeightInRow = 0;
          }
          
          layout.add({
            'stall_id': stall['id'], // Use stall id for mapping
            'exhibition_id': exhibitionId,
            'instance_number': i + 1,
            'position_x': currentX,
            'position_y': currentY,
            'rotation_angle': 0.0,
            'status': 'available',
            'price': stall['price'] ?? 0.0,
          });
          
          currentX += length + spacing;
          maxHeightInRow = maxHeightInRow < width ? width : maxHeightInRow;
        }
      }
      
      return layout;
    }

             Future<void> _saveLayoutToDatabase(List<Map<String, dynamic>> layout) async {
      try {
        print('DEBUG: Starting _saveLayoutToDatabase with ${layout.length} layout items');
        
        // First, create the stalls and get their IDs
    final formState = Provider.of<ExhibitionFormState>(context, listen: false);
    final stalls = formState.formData.stalls;
        final Map<String, String> stallIdMap = {}; // Maps temporary ID to real stall ID
        
        print('DEBUG: Processing ${stalls.length} stalls from form data');
        
        for (final stall in stalls) {
          final stallAmenities = stall['amenities'] as List<dynamic>? ?? [];
          final tempId = stall['id'] as String; // Temporary ID from form
          
          print('DEBUG: Processing stall with temp ID: $tempId, name: ${stall['name']}');
          
          // First, check if ANY stall with this name exists for this exhibition
          final existingStalls = await _supabaseService.client
              .from('stalls')
              .select('id, name')
              .eq('exhibition_id', formState.formData.id!)
              .eq('name', stall['name']);
          
          String? stallId;
          
          if (existingStalls.isNotEmpty) {
            // Use existing stall - just take the first one with this name
            stallId = existingStalls.first['id'] as String;
            print('DEBUG: Using existing stall with ID: $stallId for name: ${stall['name']}');
            
            // Update the existing stall with new data
            final updateData = {
              'length': stall['length'],
              'width': stall['width'],
              'price': stall['price'],
              'unit_id': stall['unit_id'],
              'quantity': stall['quantity'] ?? 1,
            };
            
            // Remove null values but keep quantity
            updateData.removeWhere((key, value) => value == null && key != 'quantity');
            // Ensure quantity is always set
            updateData['quantity'] = updateData['quantity'] ?? 1;
            
            if (updateData.isNotEmpty) {
              print('DEBUG: Update data: $updateData');
              print('DEBUG: Quantity value in update: ${updateData['quantity']}');
              await _supabaseService.client
                  .from('stalls')
                  .update(updateData)
                  .eq('id', stallId);
              print('DEBUG: Updated existing stall with new data');
            }
          } else {
            // Create new stall
            print('DEBUG: Creating new stall for name: ${stall['name']}');
            
            final insertData = {
              'name': stall['name'],
              'length': stall['length'],
              'width': stall['width'],
              'price': stall['price'],
              'unit_id': stall['unit_id'],
              'quantity': stall['quantity'] ?? 1,
              'exhibition_id': formState.formData.id!,
            };
            
            // Remove null values but keep quantity
            insertData.removeWhere((key, value) => value == null && key != 'quantity');
            // Ensure quantity is always set
            insertData['quantity'] = insertData['quantity'] ?? 1;
            
            print('DEBUG: Insert data: $insertData');
            print('DEBUG: Quantity value: ${insertData['quantity']}');
            
            try {
              final stallResponse = await _supabaseService.client
                  .from('stalls')
                  .insert(insertData)
                  .select()
                  .single();
              
              stallId = stallResponse['id'] as String;
              print('DEBUG: Created new stall with ID: $stallId');
            } catch (insertError) {
              print('DEBUG: Error inserting stall: $insertError');
              
              // If there's a duplicate key error, try to find the existing stall again
              if (insertError.toString().contains('duplicate key')) {
                print('DEBUG: Duplicate key error detected, trying to find existing stall');
                final existingStall = await _supabaseService.client
                    .from('stalls')
                    .select('id, name')
                    .eq('exhibition_id', formState.formData.id!)
                    .eq('name', stall['name'])
                    .maybeSingle();
                
                if (existingStall != null) {
                  stallId = existingStall['id'] as String;
                  print('DEBUG: Found existing stall with ID: $stallId after duplicate key error');
                } else {
                  throw Exception('Duplicate key error but could not find existing stall: $insertError');
                }
              } else {
                throw insertError;
              }
            }
          }
          
          if (stallId != null) {
            stallIdMap[tempId] = stallId; // Map temporary ID to real ID
            print('DEBUG: Mapped temp_id: $tempId to real stall_id: $stallId');
            
            // Create stall amenities (only if not already created)
            if (stallAmenities.isNotEmpty) {
              // Check if amenities already exist for this stall
              final existingAmenities = await _supabaseService.client
                  .from('stall_amenities')
                  .select('amenity_id')
                  .eq('stall_id', stallId);
              
              final existingAmenityIds = existingAmenities.map((a) => a['amenity_id'] as String).toList();
              final newAmenities = stallAmenities.where((id) => !existingAmenityIds.contains(id)).toList();
              
              if (newAmenities.isNotEmpty) {
                final amenityData = newAmenities.map((amenityId) => {
                  'stall_id': stallId,
                  'amenity_id': amenityId,
                }).toList();
                
                await _supabaseService.client
                    .from('stall_amenities')
                    .insert(amenityData);
              }
            }
          } else {
            print('DEBUG: ERROR - stallId is null for temp_id: $tempId');
            throw Exception('Failed to create or find stall for temp_id: $tempId');
          }
        }

        // Then create stall instances with layout positions
        print('DEBUG: Creating ${layout.length} stall instances');
        for (final instance in layout) {
          final tempStallId = instance['stall_id'] as String;
          final realStallId = stallIdMap[tempStallId];
          
          print('DEBUG: Processing instance - temp_stall_id: $tempStallId, real_stall_id: $realStallId');
          
          if (realStallId != null) {
            // Check if instance already exists
            final existingInstances = await _supabaseService.client
                .from('stall_instances')
                .select('id')
                .eq('stall_id', realStallId)
                .eq('instance_number', instance['instance_number']);
            
            if (existingInstances.isEmpty) {
              print('DEBUG: Creating new stall instance for stall_id: $realStallId, instance_number: ${instance['instance_number']}');
              await _supabaseService.client
                  .from('stall_instances')
                  .insert({
                    'stall_id': realStallId,
                    'exhibition_id': instance['exhibition_id'],
                    'instance_number': instance['instance_number'],
                    'position_x': instance['position_x'],
                    'position_y': instance['position_y'],
                    'rotation_angle': instance['rotation_angle'],
                    'status': instance['status'],
                    'price': instance['price'],
                    'original_price': instance['price'],
                  });
              print('DEBUG: Successfully created stall instance');
            } else {
              print('DEBUG: Stall instance already exists for stall_id: $realStallId, instance_number: ${instance['instance_number']}');
            }
          } else {
            print('DEBUG: ERROR - No real stall ID found for temp_stall_id: $tempStallId');
          }
        }
        print('DEBUG: Finished creating stall instances');
      } catch (e) {
        print('DEBUG: Error in _saveLayoutToDatabase: $e');
        throw Exception('Failed to save layout to database: $e');
      }
    }



  String _getUnitSymbol(String? unitId) {
    if (unitId == null) return '';
    final unit = _measurementUnits.firstWhere(
      (unit) => unit['id'] == unitId,
      orElse: () => {'symbol': ''},
    );
    return unit['symbol'] ?? '';
  }

       String _getAmenityNames(List<dynamic>? amenityIds) {
      if (amenityIds == null || amenityIds.isEmpty) return 'None';
      final names = amenityIds.map((id) {
        final amenity = _amenities.firstWhere(
          (amenity) => amenity['id'] == id,
          orElse: () => {'name': 'Unknown'},
        );
        return amenity['name'] ?? 'Unknown';
      }).toList();
      return names.join(', ');
    }

  // Show existing layout in full screen
  Future<void> _showExistingLayoutDialog() async {
    try {
      if (_existingStallInstances.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('No existing stall layout found'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        return;
      }

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ExistingStallLayoutScreen(
            stallInstances: _existingStallInstances,
            layoutBounds: _existingLayoutBounds,
          ),
        ),
      );
    } catch (e) {
      print('Error showing existing layout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading existing layout: $e'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
    }
  }

  Widget _buildExistingStallWidget(Map<String, dynamic> stallInstance, int index) {
    final positionX = (stallInstance['normalized_x'] as num?)?.toDouble() ?? 
                     (stallInstance['position_x'] as num).toDouble();
    final positionY = (stallInstance['normalized_y'] as num?)?.toDouble() ?? 
                     (stallInstance['position_y'] as num).toDouble();
    final instanceNumber = stallInstance['instance_number'] as int;
    final price = (stallInstance['instance_price'] as String?) ?? '0';
    final status = stallInstance['status'] as String? ?? 'available';
    final stallName = stallInstance['name'] as String? ?? 'Unknown';
    
    // Responsive stall dimensions based on screen size (exactly like brand screen)
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    // For mobile, use calculated size from layout; for desktop, use fixed size
    double stallSize;
    if (isSmallScreen) {
      // Use the calculated stall size from mobile layout
      final availableWidth = screenSize.width - 32;
      final spacing = 20.0; // Match the spacing used in _calculateMobileExistingLayoutBounds
      stallSize = (availableWidth - 2 * spacing) / 3; // 3 columns
    } else {
      stallSize = 40.0; // Fixed size for desktop
    }
    
    // Determine stall color based on status (matching brand screen)
    Color stallColor = _getStatusColor(status).withOpacity(0.3);
    
    print('Rendering existing stall $instanceNumber at position ($positionX, $positionY) with status: $status, size: ${stallSize.round()}');
    
    return Positioned(
      left: positionX,
      top: positionY,
      child: GestureDetector(
        onTap: () => _showExistingStallDetails(stallInstance, index),
        child: Tooltip(
          message: '$stallName - ${_getStatusDisplayName(status)}',
          child: Container(
            width: stallSize,
            height: stallSize,
            decoration: BoxDecoration(
              color: stallColor,
              border: Border.all(
                color: _getStatusColor(status),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 4),
              boxShadow: isSmallScreen ? [
                BoxShadow(
                  color: AppTheme.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Center(
              child: Text(
                '$instanceNumber',
                style: TextStyle(
                  color: AppTheme.textDarkCharcoal,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 18 : 10,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to get status display name (exactly like brand screen)
  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return 'Available';
      case 'pending':
        return 'Pending';
      case 'payment_pending':
        return 'Payment Pending';
      case 'payment_review':
        return 'Payment Review';
      case 'booked':
      case 'occupied':
        return 'Booked';
      case 'rejected':
        return 'Rejected';
      case 'maintenance':
      case 'under_maintenance':
        return 'Under Maintenance';
      default:
        return 'Unknown';
    }
  }

  // Helper method to get status color (exactly like brand screen)
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return AppTheme.successGreen;
      case 'pending':
        return AppTheme.warningOrange;
      case 'payment_pending':
        return AppTheme.secondaryGold;
      case 'payment_review':
        return AppTheme.primaryMaroon;
      case 'booked':
      case 'occupied':
        return AppTheme.errorRed;
      case 'rejected':
        return AppTheme.errorRed;
      case 'maintenance':
      case 'under_maintenance':
        return AppTheme.textMediumGray;
      default:
        return AppTheme.textMediumGray;
    }
  }

  // Helper method to build legend items
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textMediumGray,
          ),
        ),
      ],
    );
  }

  // Helper method to get unique stall names
  List<String> _getUniqueStallNames() {
    final Set<String> uniqueNames = {};
    for (final stall in _existingStallInstances) {
      final name = stall['name'] as String? ?? 'Unknown';
      uniqueNames.add(name);
    }
    return uniqueNames.toList()..sort();
  }

  void _showExistingStallDetails(Map<String, dynamic> stallInstance, int index) {
    final instanceNumber = stallInstance['instance_number'] as int;
    final price = (stallInstance['instance_price'] as String?) ?? '0';
    final originalPrice = (stallInstance['original_price'] as String?) ?? '0';
    final positionX = (stallInstance['position_x'] as num).toDouble();
    final positionY = (stallInstance['position_y'] as num).toDouble();
    final status = stallInstance['status'] as String? ?? 'available';
    final stallName = stallInstance['name'] as String? ?? 'Unknown';
    final stallDescription = ''; // Description field removed from stalls table
    final unit = stallInstance['unit'] as Map<String, dynamic>?;
    final unitSymbol = unit?['symbol'] as String? ?? '';
    final length = (stallInstance['length'] as num?)?.toDouble() ?? 0.0;
    final width = (stallInstance['width'] as num?)?.toDouble() ?? 0.0;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.gradientBlack,
                AppTheme.gradientPink,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getStatusColor(status).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with status
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.store,
                      color: _getStatusColor(status),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$stallName - Instance $instanceNumber',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getStatusColor(status),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stall Info
                      _buildDetailSection(
                        'Stall Details',
                        Icons.grid_on,
                        [
                          'Stall Name: $stallName',
                          'Instance Number: $instanceNumber',
                          'Dimensions: ${length}x${width} $unitSymbol',
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Pricing Info
                      _buildDetailSection(
                        'Pricing',
                        Icons.attach_money,
                        [
                          'Current Price: ₹$price',
                          if (originalPrice != price) 'Original Price: ₹$originalPrice (Discounted)',
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Position Info
                      _buildDetailSection(
                        'Position',
                        Icons.location_on,
                        [
                          'Coordinates: (${positionX.round()}, ${positionY.round()})',
                          'Layout Position: Instance #$index',
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Close button
              Container(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getStatusColor(status).withOpacity(0.2),
                    foregroundColor: _getStatusColor(status),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...details.map((detail) => Padding(
          padding: const EdgeInsets.only(left: 28, bottom: 4),
          child: Text(
            detail,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        )),
      ],
    );
  }

  // Load existing stall instances from database
  Future<void> _loadExistingStallInstances() async {
    try {
      final formState = Provider.of<ExhibitionFormState>(context, listen: false);
      if (formState.formData.id == null) return;

      print('DEBUG: Loading existing stall instances for exhibition: ${formState.formData.id}');
      
      // Fetch stalls with instances from database
      final stallsWithInstances = await _supabaseService.getStallsByExhibition(formState.formData.id!);
      
      if (stallsWithInstances.isNotEmpty) {
        print('DEBUG: Found ${stallsWithInstances.length} existing stalls with instances');
        
        // Process stalls data to extract instances (similar to brand stall selection screen)
        final processedStalls = <Map<String, dynamic>>[];
        
        for (final stall in stallsWithInstances) {
          print('DEBUG: Processing existing stall: ${stall['name']} (ID: ${stall['id']})');
          
          final instances = stall['instances'] as List<dynamic>?;
          if (instances != null && instances.isNotEmpty) {
            print('DEBUG: Stall ${stall['name']} has ${instances.length} instances');
            for (final instance in instances) {
              final processedInstance = {
                ...stall,
                'instance_id': instance['id'],
                'position_x': instance['position_x']?.toDouble() ?? 0.0,
                'position_y': instance['position_y']?.toDouble() ?? 0.0,
                'rotation_angle': instance['rotation_angle']?.toDouble() ?? 0.0,
                'status': instance['status'] ?? 'available',
                'instance_number': instance['instance_number'] ?? 0,
                'instance_price': instance['price']?.toString() ?? stall['price']?.toString(),
                'original_price': instance['original_price']?.toString() ?? stall['price']?.toString(),
              };
              processedStalls.add(processedInstance);
            }
          }
        }
        
        print('DEBUG: Processed ${processedStalls.length} existing stall instances');
        
        // Calculate layout bounds and normalize positions
        _calculateExistingLayoutBounds(processedStalls);
        
        // Store the existing stall instances for display
        if (mounted) {
          setState(() {
            _existingStallInstances = processedStalls;
          });
          
          // Update the form state with existing stalls data
          final formState = Provider.of<ExhibitionFormState>(context, listen: false);
          
          // Convert processed stalls to the format expected by form state
          final stallsForForm = <Map<String, dynamic>>[];
          final stallTypes = <String, Map<String, dynamic>>{};
          
          for (final stall in processedStalls) {
            final stallId = stall['id'] as String;
            if (!stallTypes.containsKey(stallId)) {
              // Create a stall type entry
              stallTypes[stallId] = {
                'id': stall['id'],
                'name': stall['name'],
                'length': stall['length'],
                'width': stall['width'],
                'unit_id': stall['unit_id'],
                'price': stall['price'],
                'quantity': 1, // Will be incremented
                'amenities': stall['amenities'] ?? [],
              };
            } else {
              // Increment quantity for existing stall type
              stallTypes[stallId]!['quantity'] = (stallTypes[stallId]!['quantity'] as int) + 1;
            }
          }
          
          // Convert to list format
          stallsForForm.addAll(stallTypes.values);
          
          // Update form state
          formState.updateStalls(stallsForForm);
          print('DEBUG: Updated form state with ${stallsForForm.length} stall types');
        }
      } else {
        print('DEBUG: No existing stalls found for this exhibition');
      }
    } catch (e) {
      print('DEBUG: Error loading existing stall instances: $e');
    }
  }

  // Calculate layout bounds for existing stalls (exactly like brand stall selection screen)
  void _calculateExistingLayoutBounds(List<Map<String, dynamic>> stalls) {
    if (stalls.isEmpty) {
      _existingLayoutBounds = const Size(400, 300);
      _existingLayoutCenter = const Offset(200, 150);
      return;
    }

    // For mobile, arrange stalls in a fixed 3-column grid layout (like brand screen)
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    if (isSmallScreen) {
      _calculateMobileExistingLayoutBounds(stalls);
    } else {
      _calculateDesktopExistingLayoutBounds(stalls);
    }
  }

  // Mobile-optimized layout calculation (exactly like brand screen)
  void _calculateMobileExistingLayoutBounds(List<Map<String, dynamic>> stalls) {
    final screenSize = MediaQuery.of(context).size;
    final availableWidth = screenSize.width - 32; // Reduced margins for better space usage
    
    // Fixed 3 columns for better mobile layout
    final cols = 3;
    final stallCount = stalls.length;
    final rows = (stallCount / cols).ceil().toInt();
    
    // Calculate optimal stall size based on available width
    final spacing = 20.0; // Reduced spacing for better fit
    final stallSize = (availableWidth - (cols - 1) * spacing) / cols;
    
    // Calculate total layout dimensions
    final totalWidth = cols * stallSize + (cols - 1) * spacing;
    final totalHeight = rows * stallSize + (rows - 1) * spacing;
    
    // Center the layout horizontally
    final startX = (availableWidth - totalWidth) / 2;
    final startY = 16.0; // Reduced top margin
    
    // Set layout bounds to actual content size (not screen size)
    _existingLayoutBounds = Size(totalWidth, totalHeight);
    _existingLayoutCenter = Offset(totalWidth / 2, totalHeight / 2);
    
    print('=== MOBILE EXISTING LAYOUT CALCULATION ===');
    print('Screen size: ${screenSize.width} × ${screenSize.height}');
    print('Available width: $availableWidth');
    print('Grid: ${cols} × ${rows} (Fixed 3 columns)');
    print('Stall size: ${stallSize.round()} × ${stallSize.round()}');
    print('Spacing: $spacing');
    print('Total layout: ${totalWidth.round()} × ${totalHeight.round()}');
    
    // Assign grid positions to stalls
    for (int i = 0; i < stalls.length; i++) {
      final stall = stalls[i];
      final row = i ~/ cols;
      final col = i % cols;
      
      final x = startX + col * (stallSize + spacing);
      final y = startY + row * (stallSize + spacing);
      
      stall['normalized_x'] = x;
      stall['normalized_y'] = y;
      
      final instanceNumber = stall['instance_number'] ?? 'unknown';
      print('Stall $instanceNumber: grid position ($col, $row) -> (${x.round()}, ${y.round()})');
    }
  }

  // Desktop layout calculation (exactly like brand screen)
  void _calculateDesktopExistingLayoutBounds(List<Map<String, dynamic>> stalls) {
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    print('=== CALCULATING DESKTOP EXISTING LAYOUT BOUNDS ===');
    
    // Ensure all stalls have valid positions by assigning default grid positions if needed
    for (int i = 0; i < stalls.length; i++) {
      final stall = stalls[i];
      if (stall['position_x'] == null || stall['position_x'] == 0.0) {
        // Assign a grid position if no position is set
        final row = i ~/ 5; // 5 stalls per row
        final col = i % 5;
        stall['position_x'] = col * 100.0; // 100px spacing between stalls
        stall['position_y'] = row * 100.0;
        print('Assigned grid position to stall ${stall['instance_number']}: ($col, $row) -> (${stall['position_x']}, ${stall['position_y']})');
      }
    }
    
    for (final stall in stalls) {
      final x = stall['position_x']?.toDouble() ?? 0.0;
      final y = stall['position_y']?.toDouble() ?? 0.0;
      final instanceNumber = stall['instance_number'] ?? 'unknown';
      
      print('Stall $instanceNumber: position_x=$x, position_y=$y');
      
      minX = math.min(minX, x);
      minY = math.min(minY, y);
      maxX = math.max(maxX, x);
      maxY = math.max(maxY, y);
    }

    print('Raw bounds: minX=$minX, minY=$minY, maxX=$maxX, maxY=$maxY');

    // Add padding around the stalls
    const padding = 50.0;
    minX -= padding;
    minY -= padding;
    maxX += padding;
    maxY += padding;

    _existingLayoutBounds = Size(maxX - minX, maxY - minY);
    _existingLayoutCenter = Offset(
      (maxX + minX) / 2,
      (maxY + minY) / 2,
    );

    print('Final layout bounds: ${_existingLayoutBounds.width} × ${_existingLayoutBounds.height}');
    print('Layout center: ${_existingLayoutCenter.dx}, ${_existingLayoutCenter.dy}');

    // Normalize stall positions to start from (0,0)
    for (final stall in stalls) {
      final originalX = stall['position_x']?.toDouble() ?? 0.0;
      final originalY = stall['position_y']?.toDouble() ?? 0.0;
      
      stall['normalized_x'] = originalX - minX;
      stall['normalized_y'] = originalY - minY;
      
      final instanceNumber = stall['instance_number'] ?? 'unknown';
      print('Stall $instanceNumber: normalized position (${stall['normalized_x']}, ${stall['normalized_y']})');
    }
  }

       Future<void> _showLayoutPreviewDialog() async {
     try {
       // Fetch stall instances from database with layout information
       final formState = Provider.of<ExhibitionFormState>(context, listen: false);
       final stallInstances = await _supabaseService.getStallInstancesWithLayout(formState.formData.id!);
       
       if (!mounted) return;
       
       showDialog(
         context: context,
         builder: (context) => Dialog(
           backgroundColor: AppTheme.white,
           child: Container(
             width: MediaQuery.of(context).size.width * 0.95,
             height: MediaQuery.of(context).size.height * 0.9,
             padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                 // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stall Layout Preview',
                        style: TextStyle(
                          color: AppTheme.gradientBlack,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${stallInstances.length} stalls generated successfully',
                        style: TextStyle(
                          color: AppTheme.gradientBlack.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: AppTheme.gradientBlack),
                ),
              ],
            ),
            const SizedBox(height: 16),
                 
                 // Legend
                 Container(
                   padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                     color: AppTheme.primaryMaroon.withOpacity(0.05),
                     borderRadius: BorderRadius.circular(8),
                     border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.2)),
                   ),
                   child: Row(
                        children: [
                       Container(
                         width: 16,
                         height: 16,
                         decoration: BoxDecoration(
                           color: AppTheme.primaryMaroon.withOpacity(0.3),
                           borderRadius: BorderRadius.circular(4),
                           border: Border.all(color: AppTheme.primaryMaroon),
                         ),
                       ),
                       const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Available Stalls',
                              style: TextStyle(
                                color: AppTheme.gradientBlack,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Flexible(
                            child: Text(
                              'Tap stalls to view details',
                              style: TextStyle(
                                color: AppTheme.gradientBlack.withOpacity(0.6),
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                     ],
                   ),
                 ),
                 const SizedBox(height: 16),
                 
                 // Layout Display
                 Expanded(
                   child: Container(
                     decoration: BoxDecoration(
                       color: AppTheme.white,
                       borderRadius: BorderRadius.circular(12),
                       border: Border.all(color: AppTheme.gradientBlack.withOpacity(0.2)),
                       boxShadow: [
                         BoxShadow(
                           color: AppTheme.black.withOpacity(0.1),
                           blurRadius: 10,
                           offset: const Offset(0, 2),
                         ),
                       ],
                     ),
                     child: ClipRRect(
                       borderRadius: BorderRadius.circular(12),
                       child: InteractiveViewer(
                         minScale: 0.5,
                         maxScale: 3.0,
                         boundaryMargin: const EdgeInsets.all(50),
                         child: SizedBox(
                           width: math.min(800, MediaQuery.of(context).size.width - 80),
                           height: math.min(600, MediaQuery.of(context).size.height * 0.6),
                           child: Stack(
                             children: [
                               // Grid Background
                               CustomPaint(
                                 painter: GridPainter(),
                                 size: Size(
                                   math.min(800, MediaQuery.of(context).size.width - 80),
                                   math.min(600, MediaQuery.of(context).size.height * 0.6),
                                 ),
                               ),
                               
                               // Stalls
                               ...stallInstances.asMap().entries.map((entry) {
                                 final index = entry.key;
                                 final stall = entry.value;
                                 return _buildStallWidget(stall, index);
                  }).toList(),
                             ],
                           ),
                         ),
                       ),
                ),
              ),
            ),
            const SizedBox(height: 16),
                 
                 // Footer
                 Column(
                   children: [
                     Text(
                       'Total Stalls: ${stallInstances.length}',
                       style: TextStyle(
                         color: AppTheme.gradientBlack,
                         fontSize: 16,
                         fontWeight: FontWeight.w600,
                       ),
                     ),
                     const SizedBox(height: 12),
                     SizedBox(
                       width: double.infinity,
                       child: ElevatedButton(
                         onPressed: () {
                           Navigator.of(context).pop();
                           // Proceed to next step
                           WidgetsBinding.instance.addPostFrameCallback((_) {
                             final formState = Provider.of<ExhibitionFormState>(context, listen: false);
                             formState.nextStep();
                           });
                         },
                         style: ElevatedButton.styleFrom(
                           backgroundColor: AppTheme.primaryMaroon,
                           foregroundColor: AppTheme.white,
                           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(8),
                           ),
                         ),
                         child: const Text('Continue to Next Step'),
                       ),
                     ),
                   ],
                 ),
               ],
             ),
           ),
         ),
       );
     } catch (e) {
       print('Error showing layout preview: $e');
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(
           content: Text('Error loading layout preview: $e'),
           backgroundColor: AppTheme.errorRed,
         ),
       );
     }
   }

   Widget _buildStallWidget(Map<String, dynamic> stallInstance, int index) {
     final positionX = (stallInstance['position_x'] as num).toDouble();
     final positionY = (stallInstance['position_y'] as num).toDouble();
     final instanceNumber = stallInstance['instance_number'] as int;
     final price = (stallInstance['price'] as num).toDouble();
     final status = stallInstance['status'] as String? ?? 'available';
     final stall = stallInstance['stall'] as Map<String, dynamic>?;
     final stallName = stall?['name'] as String? ?? 'Unknown';
     
     return Positioned(
       left: positionX,
       top: positionY,
       child: GestureDetector(
         onTap: () => _showStallDetails(stallInstance, index),
         child: Tooltip(
           message: '$stallName - Instance $instanceNumber - ₹${price.toStringAsFixed(0)}',
           child: Container(
             width: 60,
             height: 40,
             decoration: BoxDecoration(
               color: AppTheme.primaryMaroon.withOpacity(0.3),
               border: Border.all(
                 color: AppTheme.primaryMaroon,
                 width: 2,
               ),
               borderRadius: BorderRadius.circular(6),
               boxShadow: [
                 BoxShadow(
                   color: AppTheme.black.withOpacity(0.1),
                   blurRadius: 4,
                   offset: const Offset(0, 2),
                 ),
               ],
             ),
             child: Center(
               child: Text(
                 '$instanceNumber',
                 style: TextStyle(
                   color: AppTheme.white,
                   fontWeight: FontWeight.bold,
                   fontSize: 14,
                 ),
               ),
             ),
           ),
         ),
       ),
     );
   }

   void _showStallDetails(Map<String, dynamic> stallInstance, int index) {
     final instanceId = stallInstance['id'] as String?;
     final instanceNumber = stallInstance['instance_number'] as int;
     final price = (stallInstance['price'] as num).toDouble();
     final positionX = (stallInstance['position_x'] as num).toDouble();
     final positionY = (stallInstance['position_y'] as num).toDouble();
     final status = stallInstance['status'] as String? ?? 'available';
     final stall = stallInstance['stall'] as Map<String, dynamic>?;
     final stallName = stall?['name'] as String? ?? 'Unknown';
     final unit = stall?['unit'] as Map<String, dynamic>?;
     final unitSymbol = unit?['symbol'] as String? ?? '';
     final length = (stall?['length'] as num?)?.toDouble() ?? 0.0;
     final width = (stall?['width'] as num?)?.toDouble() ?? 0.0;
     
     // Controllers for editing
     final priceController = TextEditingController(text: price.toString());
     final statusController = TextEditingController(text: status);
     
     showDialog(
       context: context,
       builder: (context) => StatefulBuilder(
         builder: (context, setDialogState) {
           return AlertDialog(
             backgroundColor: AppTheme.white,
             title: Row(
               children: [
                 Expanded(
                   child: Text(
                     '$stallName - Instance $instanceNumber',
                     style: TextStyle(
                       color: AppTheme.gradientBlack,
                       fontSize: 18,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                 ),
                 IconButton(
                   onPressed: () => Navigator.of(context).pop(),
                   icon: Icon(Icons.close, color: AppTheme.gradientBlack),
                 ),
               ],
             ),
             content: SingleChildScrollView(
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   // Read-only information
                   _buildDetailRow('Stall Name', stallName),
                   _buildDetailRow('Instance Number', '$instanceNumber'),
                   _buildDetailRow('Dimensions', '${length}x${width} $unitSymbol'),
                   _buildDetailRow('Position', '(${positionX.round()}, ${positionY.round()})'),
                   
                   const SizedBox(height: 16),
                   
                   // Editable fields
                   Text(
                     'Editable Properties',
                     style: TextStyle(
                       color: AppTheme.gradientBlack,
                       fontSize: 16,
                       fontWeight: FontWeight.w600,
                     ),
                   ),
                   const SizedBox(height: 12),
                   
                   // Price field
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         'Price (₹):',
                         style: TextStyle(
                           color: AppTheme.gradientBlack.withOpacity(0.7),
                           fontSize: 14,
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                       const SizedBox(height: 4),
                       Container(
                         decoration: BoxDecoration(
                           color: AppTheme.white,
                           borderRadius: BorderRadius.circular(8),
                           border: Border.all(color: AppTheme.gradientBlack.withOpacity(0.2)),
                         ),
                         child: TextFormField(
                           controller: priceController,
                           keyboardType: TextInputType.number,
                           style: TextStyle(
                             color: AppTheme.gradientBlack,
                             fontSize: 16,
                           ),
                           decoration: InputDecoration(
                             border: InputBorder.none,
                             contentPadding: const EdgeInsets.all(12),
                             hintText: 'Enter price',
                           ),
                         ),
                       ),
                     ],
                   ),
                   
                   const SizedBox(height: 16),
                   
                   // Status dropdown
                   Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         'Status:',
                         style: TextStyle(
                           color: AppTheme.gradientBlack.withOpacity(0.7),
                           fontSize: 14,
                           fontWeight: FontWeight.w500,
                         ),
                       ),
                       const SizedBox(height: 4),
                       Container(
                         decoration: BoxDecoration(
                           color: AppTheme.white,
                           borderRadius: BorderRadius.circular(8),
                           border: Border.all(color: AppTheme.gradientBlack.withOpacity(0.2)),
                         ),
                         child: DropdownButtonFormField<String>(
                           value: statusController.text,
                           items: [
                             'available',
                             'pending',
                             'payment_pending',
                             'payment_review',
                             'booked',
                             'occupied',
                             'rejected',
                             'maintenance',
                             'under_maintenance',
                           ].map((status) => DropdownMenuItem<String>(
                             value: status,
                             child: Text(
                               status.replaceAll('_', ' ').toUpperCase(),
                               style: TextStyle(
                                 color: AppTheme.gradientBlack,
                                 fontSize: 14,
                               ),
                             ),
                           )).toList(),
                           onChanged: (value) {
                             if (value != null) {
                               statusController.text = value;
                               setDialogState(() {});
                             }
                           },
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
                         ),
                       ),
                     ],
                   ),
                 ],
               ),
             ),
                            actions: [
                 // Delete button
                 TextButton(
                   onPressed: () async {
                     // Show confirmation dialog
                     final shouldDelete = await showDialog<bool>(
                       context: context,
                       builder: (context) => AlertDialog(
                         backgroundColor: AppTheme.white,
                         title: Text(
                           'Delete Stall Instance',
                           style: TextStyle(
                             color: AppTheme.errorRed,
                             fontSize: 18,
                             fontWeight: FontWeight.bold,
                           ),
                         ),
                         content: Text(
                           'Are you sure you want to delete this stall instance? This action cannot be undone.',
                           style: TextStyle(
                             color: AppTheme.gradientBlack,
                             fontSize: 16,
                           ),
                         ),
                         actions: [
                           TextButton(
                             onPressed: () => Navigator.of(context).pop(false),
                             child: Text(
                               'Cancel',
                               style: TextStyle(color: AppTheme.textMediumGray),
                             ),
                           ),
                           ElevatedButton(
                             onPressed: () => Navigator.of(context).pop(true),
                             style: ElevatedButton.styleFrom(
                               backgroundColor: AppTheme.errorRed,
                               foregroundColor: AppTheme.white,
                             ),
                             child: Text('Delete'),
                           ),
                         ],
                       ),
                     );
                     
                     if (shouldDelete == true && instanceId != null) {
                       try {
                         // Delete the stall instance from database
                         await _supabaseService.client
                             .from('stall_instances')
                             .delete()
                             .eq('id', instanceId);
                         
                         // Remove from local data
                         setState(() {
                           // Remove the instance from the layout preview data
                           // This will be handled by refreshing the layout
                         });
                         
                         Navigator.of(context).pop(); // Close the edit dialog
                         
                         // Refresh the layout preview
                         await _showLayoutPreviewDialog();
                         
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                             content: Text('Stall instance deleted successfully'),
                             backgroundColor: AppTheme.successGreen,
                           ),
                         );
                       } catch (e) {
                         print('Error deleting stall instance: $e');
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                             content: Text('Error deleting stall instance: $e'),
                             backgroundColor: AppTheme.errorRed,
                           ),
                         );
                       }
                     }
                   },
                   child: Text(
                     'Delete',
                     style: TextStyle(color: AppTheme.errorRed),
                   ),
                 ),
                 // Cancel button
                 TextButton(
                   onPressed: () => Navigator.of(context).pop(),
                   child: Text(
                     'Cancel',
                     style: TextStyle(color: AppTheme.textMediumGray),
                   ),
                 ),
                 // Save button
                 ElevatedButton(
                   onPressed: () async {
                     try {
                       // Validate price
                       final newPrice = double.tryParse(priceController.text);
                       if (newPrice == null || newPrice < 0) {
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                             content: Text('Please enter a valid price'),
                             backgroundColor: AppTheme.errorRed,
                           ),
                         );
                         return;
                       }
                       
                       // Update the stall instance
                       if (instanceId != null) {
                         await _supabaseService.client
                             .from('stall_instances')
                             .update({
                               'price': newPrice,
                               'status': statusController.text,
                             })
                             .eq('id', instanceId);
                         
                         // Update the local data
                         stallInstance['price'] = newPrice;
                         stallInstance['status'] = statusController.text;
                         
                         // Refresh the layout preview
                         setState(() {});
                         
                         Navigator.of(context).pop();
                         
                         ScaffoldMessenger.of(context).showSnackBar(
                           SnackBar(
                             content: Text('Stall instance updated successfully'),
                             backgroundColor: AppTheme.successGreen,
                           ),
                         );
                       }
                     } catch (e) {
                       print('Error updating stall instance: $e');
                       ScaffoldMessenger.of(context).showSnackBar(
                         SnackBar(
                           content: Text('Error updating stall instance: $e'),
                           backgroundColor: AppTheme.errorRed,
                         ),
                       );
                     }
                   },
                   style: ElevatedButton.styleFrom(
                     backgroundColor: AppTheme.primaryMaroon,
                     foregroundColor: AppTheme.white,
                   ),
                   child: Text('Save Changes'),
                 ),
               ],
           );
         },
       ),
     );
   }

   Widget _buildDetailRow(String label, String value) {
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 4),
       child: Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           SizedBox(
             width: 100,
             child: Text(
               '$label:',
               style: TextStyle(
                 color: AppTheme.gradientBlack.withOpacity(0.7),
                 fontSize: 14,
                 fontWeight: FontWeight.w500,
               ),
             ),
           ),
           Expanded(
             child: Text(
               value,
               style: TextStyle(
                 color: AppTheme.gradientBlack,
                 fontSize: 14,
                 fontWeight: FontWeight.w600,
               ),
             ),
           ),
         ],
       ),
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
                  'Stall Configuration',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Configure stalls for your exhibition',
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
             Consumer<ExhibitionFormState>(
               builder: (context, state, child) {
                 return Column(
                   children: [
                     // Check if measurement units are available
                     if (_measurementUnits.isEmpty)
                       Container(
                         padding: const EdgeInsets.all(16),
                         margin: const EdgeInsets.only(bottom: 16),
                         decoration: BoxDecoration(
                           color: AppTheme.errorRed.withOpacity(0.1),
                           borderRadius: BorderRadius.circular(12),
                           border: Border.all(
                             color: AppTheme.errorRed.withOpacity(0.3),
                             width: 1,
                           ),
                         ),
                          child: Column(
                            children: [
                              Text(
                                'No measurement units available in database.',
                           style: TextStyle(
                             color: AppTheme.errorRed,
                             fontSize: 14,
                                  fontWeight: FontWeight.w600,
                           ),
                           textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please add measurement units to the database or contact support.',
                                style: TextStyle(
                                  color: AppTheme.errorRed.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                         ),
                       ),
                     
                                           // Show existing layout button if there are existing stall instances
                      if (_existingStallInstances.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(20),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.primaryMaroon.withOpacity(0.1),
                                AppTheme.successGreen.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.successGreen.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.successGreen.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.check_circle,
                                      color: AppTheme.successGreen,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Existing Stall Layout Found!',
                                          style: TextStyle(
                                            color: AppTheme.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${_existingStallInstances.length} stall instances already configured',
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
                              const SizedBox(height: 16),
                              Text(
                                'This exhibition already has a complete stall layout with ${_existingStallInstances.length} instances. You can view the existing layout or create new stalls to replace them.',
                                style: TextStyle(
                                  color: AppTheme.white.withOpacity(0.9),
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _showExistingLayoutDialog,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.successGreen,
                                        foregroundColor: AppTheme.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        elevation: 4,
                                      ),
                                      icon: const Icon(Icons.visibility, size: 20),
                                      label: const Text(
                                        'View Existing Layout',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        // Clear existing instances and allow creating new ones
                                        setState(() {
                                          _existingStallInstances = [];
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Existing layout cleared. You can now create new stalls.'),
                                            backgroundColor: AppTheme.successGreen,
                                            duration: const Duration(seconds: 3),
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.white.withOpacity(0.2),
                                        foregroundColor: AppTheme.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        side: BorderSide(
                                          color: AppTheme.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      icon: const Icon(Icons.add, size: 20),
                                      label: const Text(
                                        'Create New Stalls',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      // Stalls List
                      if (state.formData.stalls.isNotEmpty) ...[
                        ...state.formData.stalls.asMap().entries.map((entry) {
                          final index = entry.key;
                          final stall = entry.value;
                          return _buildStallCard(index, stall);
                        }).toList(),
                        const SizedBox(height: 20),
                      ],
                     
                                           // Add Stall Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _measurementUnits.isNotEmpty ? _addStall : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.white.withOpacity(0.2),
                            foregroundColor: AppTheme.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Stall Type'),
                        ),
                      ),
                      
                      // Show helpful message when no stalls are added
                      if (state.formData.stalls.isEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryMaroon.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.primaryMaroon.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryMaroon.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.info_outline,
                                  color: AppTheme.primaryMaroon,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'No Stalls Added',
                                      style: TextStyle(
                                        color: AppTheme.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'You can save this exhibition as a draft and add stalls later. The exhibition will remain in draft status until stalls are configured.',
                                      style: TextStyle(
                                        color: AppTheme.white.withOpacity(0.8),
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                                             // Generate Layout Button (only show if stalls exist and no existing instances)
                       if (state.formData.stalls.isNotEmpty && _existingStallInstances.isEmpty) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _canGenerateLayout(state.formData.stalls) ? _generateLayout : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _canGenerateLayout(state.formData.stalls) 
                                  ? AppTheme.primaryMaroon 
                                  : AppTheme.primaryMaroon.withOpacity(0.3),
                              foregroundColor: AppTheme.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.grid_view),
                            label: Text(_canGenerateLayout(state.formData.stalls) 
                                 ? 'Generate & Save Layout' 
                                 : 'Complete stall details to generate layout'),
                          ),
                        ),
                        if (!_canGenerateLayout(state.formData.stalls)) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryMaroon.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3)),
                            ),
                            child: Text(
                               'Please fill in all stall details (name, dimensions, price, unit) to generate and save layout',
                              style: TextStyle(
                                color: AppTheme.primaryMaroon,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ],
                   ],
                 );
               },
             ),
        ],
      ),
    );
  }

  Widget _buildStallCard(int index, Map<String, dynamic> stall) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.white.withOpacity(0.2),
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
                Expanded(
                  child: Text(
                    'Stall ${index + 1}',
                    style: TextStyle(
                      color: AppTheme.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeStall(index),
                  icon: Icon(
                    Icons.delete,
                    color: AppTheme.errorRed,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stall Name
            _buildTextField(
              label: 'Stall Name',
              hint: 'e.g., Standard Booth, Premium Booth',
              value: stall['name'] ?? '',
              onChanged: (value) {
                final updatedStall = Map<String, dynamic>.from(stall);
                updatedStall['name'] = value;
                _updateStall(index, updatedStall);
              },
            ),
            const SizedBox(height: 16),
            
            // Dimensions Row
            Row(
              children: [
                                 Expanded(
                   child: _buildNumberField(
                     label: 'Length',
                     value: stall['length']?.toString() ?? '',
                     onChanged: (value) {
                       final updatedStall = Map<String, dynamic>.from(stall);
                       updatedStall['length'] = value.isEmpty ? null : double.tryParse(value);
                       _updateStall(index, updatedStall);
                     },
                   ),
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: _buildNumberField(
                     label: 'Width',
                     value: stall['width']?.toString() ?? '',
                     onChanged: (value) {
                       final updatedStall = Map<String, dynamic>.from(stall);
                       updatedStall['width'] = value.isEmpty ? null : double.tryParse(value);
                       _updateStall(index, updatedStall);
                     },
                   ),
                 ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDropdownField(
                    label: 'Unit',
                    value: stall['unit_id'],
                    items: _measurementUnits.map((unit) {
                      return DropdownMenuItem<String>(
                        value: unit['id'] as String,
                        child: Text(
                          '${unit['symbol']} (${unit['name']})',
                          style: const TextStyle(color: AppTheme.gradientBlack, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      final updatedStall = Map<String, dynamic>.from(stall);
                      updatedStall['unit_id'] = value;
                      _updateStall(index, updatedStall);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Price and Quantity Row
            Row(
              children: [
                                 Expanded(
                   child: _buildNumberField(
                     label: 'Price (₹)',
                     value: stall['price']?.toString() ?? '',
                     onChanged: (value) {
                       final updatedStall = Map<String, dynamic>.from(stall);
                       updatedStall['price'] = value.isEmpty ? null : double.tryParse(value);
                       _updateStall(index, updatedStall);
                     },
                   ),
                 ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildNumberField(
                    label: 'Quantity',
                    value: (stall['quantity'] ?? 1).toString(),
                    onChanged: (value) {
                      final updatedStall = Map<String, dynamic>.from(stall);
                      updatedStall['quantity'] = int.tryParse(value) ?? 1;
                      _updateStall(index, updatedStall);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
                         // Amenities Selection
             Container(
               padding: const EdgeInsets.all(12),
               decoration: BoxDecoration(
                 color: AppTheme.white.withOpacity(0.05),
                 borderRadius: BorderRadius.circular(8),
                 border: Border.all(color: AppTheme.white.withOpacity(0.1)),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Row(
                     children: [
                       Icon(Icons.checklist, color: AppTheme.white, size: 16),
                       const SizedBox(width: 8),
                       Text(
                         'Stall-Specific Amenities',
                         style: TextStyle(
                           color: AppTheme.white,
                           fontSize: 14,
                           fontWeight: FontWeight.w600,
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 8),
                   Text(
                     'Select amenities available for this stall type:',
                     style: TextStyle(
                       color: AppTheme.white.withOpacity(0.7),
                       fontSize: 12,
                     ),
                   ),
                   const SizedBox(height: 8),
                   Wrap(
                     spacing: 6,
                     runSpacing: 6,
                     children: _amenities.map((amenity) {
                       final isSelected = (stall['amenities'] as List<dynamic>?)?.contains(amenity['id']) ?? false;
                       return FilterChip(
                         selected: isSelected,
                         onSelected: (selected) {
                           final updatedStall = Map<String, dynamic>.from(stall);
                           final amenities = List<String>.from(stall['amenities'] ?? []);
                           if (selected) {
                             amenities.add(amenity['id']);
                           } else {
                             amenities.remove(amenity['id']);
                           }
                           updatedStall['amenities'] = amenities;
                           _updateStall(index, updatedStall);
                         },
                         backgroundColor: AppTheme.white.withOpacity(0.1),
                         selectedColor: AppTheme.primaryMaroon.withOpacity(0.3),
                         side: BorderSide(
                           color: isSelected ? AppTheme.primaryMaroon : AppTheme.white.withOpacity(0.3),
                           width: 1,
                         ),
                         label: Text(
                           amenity['name'] ?? '',
                           style: TextStyle(
                             color: isSelected ? AppTheme.white : AppTheme.white.withOpacity(0.8),
                             fontSize: 11,
                             fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                           ),
                         ),
                       );
                     }).toList(),
                   ),
                 ],
               ),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required String value,
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
            initialValue: value,
            onChanged: onChanged,
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

  Widget _buildNumberField({
    required String label,
    required String value,
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
            initialValue: value,
            onChanged: onChanged,
            keyboardType: TextInputType.number,
            style: TextStyle(
              color: AppTheme.gradientBlack,
              fontSize: 16,
            ),
            decoration: InputDecoration(
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
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
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
 }

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.gradientBlack.withOpacity(0.1)
      ..strokeWidth = 1;

    // Draw vertical lines
    for (double x = 0; x <= size.width; x += 50) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y <= size.height; y += 50) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Full-screen existing stall layout screen
class ExistingStallLayoutScreen extends StatefulWidget {
  final List<Map<String, dynamic>> stallInstances;
  final Size layoutBounds;

  const ExistingStallLayoutScreen({
    super.key,
    required this.stallInstances,
    required this.layoutBounds,
  });

  @override
  State<ExistingStallLayoutScreen> createState() => _ExistingStallLayoutScreenState();
}

class _ExistingStallLayoutScreenState extends State<ExistingStallLayoutScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gradientBlack,
      appBar: AppBar(
        backgroundColor: AppTheme.gradientBlack,
        foregroundColor: AppTheme.white,
        title: Text(
          'Existing Stall Layout',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Proceed to next step
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final formState = Provider.of<ExhibitionFormState>(context, listen: false);
                formState.nextStep();
              });
            },
            icon: Icon(Icons.check, color: AppTheme.successGreen),
            tooltip: 'Continue to Next Step',
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Info
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.successGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.grid_view,
                    color: AppTheme.successGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.stallInstances.length} Stall Instances',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Layout: ${widget.layoutBounds.width.round()} × ${widget.layoutBounds.height.round()}',
                        style: TextStyle(
                          color: AppTheme.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Layout Display (exactly like brand screen)
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.white.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.black.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: InteractiveViewer(
                  minScale: 0.3,
                  maxScale: 2.0,
                  boundaryMargin: const EdgeInsets.all(50),
                  child: SizedBox(
                    width: widget.layoutBounds.width,
                    height: widget.layoutBounds.height,
                    child: Stack(
                      children: [
                        // Grid Background
                        CustomPaint(
                          painter: GridPainter(),
                          size: widget.layoutBounds,
                        ),
                        
                        // Existing Stalls
                        ...widget.stallInstances.asMap().entries.map((entry) {
                          final index = entry.key;
                          final stall = entry.value;
                          return _buildExistingStallWidget(stall, index);
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Compact Legend at Bottom
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Legend
                Row(
                  children: [
                    Icon(Icons.legend_toggle, color: AppTheme.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Status:',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCompactLegendItem('Available', AppTheme.successGreen),
                      _buildCompactLegendItem('Pending', AppTheme.warningOrange),
                      _buildCompactLegendItem('Payment Pending', AppTheme.secondaryGold),
                      _buildCompactLegendItem('Payment Review', AppTheme.primaryMaroon),
                      _buildCompactLegendItem('Booked', AppTheme.errorRed),
                      _buildCompactLegendItem('Rejected', AppTheme.errorRed),
                      _buildCompactLegendItem('Under Maintenance', AppTheme.textMediumGray),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                // Stall Types
                Row(
                  children: [
                    Icon(Icons.category, color: AppTheme.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Types (${_getUniqueStallNames().length}):',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _getUniqueStallNames().map((stallName) {
                      final count = widget.stallInstances.where((stall) => stall['name'] == stallName).length;
                      return _buildCompactLegendItem('$stallName ($count)', AppTheme.primaryMaroon);
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 8),
                // Help text
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryMaroon.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppTheme.primaryMaroon.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app, color: AppTheme.primaryMaroon, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Tap stalls • Pinch to zoom • Drag to pan',
                        style: TextStyle(
                          color: AppTheme.primaryMaroon,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
                     // Footer
           Container(
             padding: const EdgeInsets.all(16),
             child: Column(
               children: [
                 // Total stalls info
                 Text(
                   'Total Stalls: ${widget.stallInstances.length}',
                   style: TextStyle(
                     color: AppTheme.white,
                     fontSize: 16,
                     fontWeight: FontWeight.w600,
                   ),
                 ),
                 const SizedBox(height: 12),
                 // Continue button
                 SizedBox(
                   width: double.infinity,
                   child: ElevatedButton.icon(
                     onPressed: () {
                       Navigator.of(context).pop();
                       // Proceed to next step
                       WidgetsBinding.instance.addPostFrameCallback((_) {
                         final formState = Provider.of<ExhibitionFormState>(context, listen: false);
                         formState.nextStep();
                       });
                     },
                     style: ElevatedButton.styleFrom(
                       backgroundColor: AppTheme.successGreen,
                       foregroundColor: AppTheme.white,
                       padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                       shape: RoundedRectangleBorder(
                         borderRadius: BorderRadius.circular(8),
                       ),
                     ),
                     icon: const Icon(Icons.arrow_forward, size: 18),
                     label: const Text('Continue to Next Step'),
                   ),
                 ),
               ],
             ),
           ),
        ],
      ),
    );
  }

     Widget _buildExistingStallWidget(Map<String, dynamic> stallInstance, int index) {
     final positionX = (stallInstance['normalized_x'] as num?)?.toDouble() ?? 
                      (stallInstance['position_x'] as num).toDouble();
     final positionY = (stallInstance['normalized_y'] as num?)?.toDouble() ?? 
                      (stallInstance['position_y'] as num).toDouble();
     final instanceNumber = stallInstance['instance_number'] as int;
     final price = (stallInstance['instance_price'] as String?) ?? '0';
     final status = stallInstance['status'] as String? ?? 'available';
     final stallName = stallInstance['name'] as String? ?? 'Unknown';
     
     // Responsive stall dimensions based on screen size (exactly like brand screen)
     final screenSize = MediaQuery.of(context).size;
     final isSmallScreen = screenSize.width < 600;
     
     // For mobile, use calculated size from layout; for desktop, use fixed size
     double stallSize;
     if (isSmallScreen) {
       // Use the calculated stall size from mobile layout
       final availableWidth = screenSize.width - 32;
       final spacing = 20.0; // Match the spacing used in _calculateMobileExistingLayoutBounds
       stallSize = (availableWidth - 2 * spacing) / 3; // 3 columns
     } else {
       stallSize = 40.0; // Fixed size for desktop
     }
     
     // Determine stall color based on status (matching brand screen)
     Color stallColor = _getStatusColor(status).withOpacity(0.3);
     
     print('Rendering existing stall $instanceNumber at position ($positionX, $positionY) with status: $status, size: ${stallSize.round()}');
     
     return Positioned(
       left: positionX,
       top: positionY,
       child: GestureDetector(
         onTap: () => _showExistingStallDetails(stallInstance, index),
         onLongPress: () {
           showModalBottomSheet(
             context: context,
             backgroundColor: AppTheme.white,
             shape: RoundedRectangleBorder(
               borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
             ),
             builder: (context) => Container(
               padding: const EdgeInsets.all(20),
               child: Column(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   Text(
                     '$stallName - Instance $instanceNumber',
                     style: TextStyle(
                       color: AppTheme.gradientBlack,
                       fontSize: 18,
                       fontWeight: FontWeight.bold,
                     ),
                   ),
                   const SizedBox(height: 20),
                   Row(
                     children: [
                       Expanded(
                         child: ElevatedButton.icon(
                           onPressed: () {
                             Navigator.of(context).pop();
                             _editStallInstance(stallInstance, index);
                           },
                           style: ElevatedButton.styleFrom(
                             backgroundColor: AppTheme.primaryMaroon,
                             foregroundColor: AppTheme.white,
                             padding: const EdgeInsets.symmetric(vertical: 12),
                             shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(8),
                             ),
                           ),
                           icon: Icon(Icons.edit, size: 20),
                           label: Text('Edit'),
                         ),
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: ElevatedButton.icon(
                           onPressed: () {
                             Navigator.of(context).pop();
                             _deleteStallInstance(stallInstance, index);
                           },
                           style: ElevatedButton.styleFrom(
                             backgroundColor: AppTheme.errorRed,
                             foregroundColor: AppTheme.white,
                             padding: const EdgeInsets.symmetric(vertical: 12),
                             shape: RoundedRectangleBorder(
                               borderRadius: BorderRadius.circular(8),
                             ),
                           ),
                           icon: Icon(Icons.delete, size: 20),
                           label: Text('Delete'),
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 12),
                   SizedBox(
                     width: double.infinity,
                     child: TextButton(
                       onPressed: () => Navigator.of(context).pop(),
                       child: Text(
                         'Cancel',
                         style: TextStyle(color: AppTheme.textMediumGray),
                       ),
                     ),
                   ),
                 ],
               ),
             ),
           );
         },
         child: Tooltip(
           message: '$stallName - ${_getStatusDisplayName(status)} (Long press for options)',
           child: Container(
             width: stallSize,
             height: stallSize,
             decoration: BoxDecoration(
               color: stallColor,
               border: Border.all(
                 color: _getStatusColor(status),
                 width: 1,
               ),
               borderRadius: BorderRadius.circular(isSmallScreen ? 12 : 4),
               boxShadow: isSmallScreen ? [
                 BoxShadow(
                   color: AppTheme.black.withOpacity(0.1),
                   blurRadius: 8,
                   offset: const Offset(0, 2),
                 ),
               ] : null,
             ),
             child: Center(
               child: Text(
                 '$instanceNumber',
                 style: TextStyle(
                   color: AppTheme.textDarkCharcoal,
                   fontWeight: FontWeight.bold,
                   fontSize: isSmallScreen ? 18 : 10,
                 ),
               ),
             ),
           ),
         ),
       ),
     );
   }

     // Helper method to get status display name (exactly like brand screen)
   String _getStatusDisplayName(String status) {
     switch (status.toLowerCase()) {
       case 'available':
         return 'Available';
       case 'pending':
         return 'Pending';
       case 'payment_pending':
         return 'Payment Pending';
       case 'payment_review':
         return 'Payment Review';
       case 'booked':
       case 'occupied':
         return 'Booked';
       case 'rejected':
         return 'Rejected';
       case 'maintenance':
       case 'under_maintenance':
         return 'Under Maintenance';
       default:
         return 'Unknown';
     }
   }

   // Helper method to get status color
   Color _getStatusColor(String status) {
     switch (status.toLowerCase()) {
       case 'available':
         return AppTheme.successGreen;
       case 'pending':
         return AppTheme.warningOrange;
       case 'payment_pending':
         return AppTheme.secondaryGold;
       case 'payment_review':
         return AppTheme.primaryMaroon;
       case 'booked':
       case 'occupied':
         return AppTheme.errorRed;
       case 'rejected':
         return AppTheme.errorRed;
       case 'maintenance':
       case 'under_maintenance':
         return AppTheme.textMediumGray;
       default:
         return AppTheme.textMediumGray;
     }
   }

  // Helper method to build legend items
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  // Helper method to build compact legend items for bottom legend
  Widget _buildCompactLegendItem(String label, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get unique stall names
  List<String> _getUniqueStallNames() {
    final Set<String> uniqueNames = {};
    for (final stall in widget.stallInstances) {
      final name = stall['name'] as String? ?? 'Unknown';
      uniqueNames.add(name);
    }
    return uniqueNames.toList()..sort();
  }

  void _showExistingStallDetails(Map<String, dynamic> stallInstance, int index) {
    final instanceId = stallInstance['instance_id'] as String?;
    final instanceNumber = stallInstance['instance_number'] as int;
    final price = (stallInstance['instance_price'] as String?) ?? '0';
    final originalPrice = (stallInstance['original_price'] as String?) ?? '0';
    final positionX = (stallInstance['position_x'] as num).toDouble();
    final positionY = (stallInstance['position_y'] as num).toDouble();
    final status = stallInstance['status'] as String? ?? 'available';
    final stallName = stallInstance['name'] as String? ?? 'Unknown';
    final unit = stallInstance['unit'] as Map<String, dynamic>?;
    final unitSymbol = unit?['symbol'] as String? ?? '';
    final length = (stallInstance['length'] as num?)?.toDouble() ?? 0.0;
    final width = (stallInstance['width'] as num?)?.toDouble() ?? 0.0;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.gradientBlack,
                AppTheme.gradientPink,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _getStatusColor(status).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with status
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.store,
                      color: _getStatusColor(status),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$stallName - Instance $instanceNumber',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getStatusColor(status),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stall Info
                      _buildDetailSection(
                        'Stall Details',
                        Icons.grid_on,
                        [
                          'Stall Name: $stallName',
                          'Instance Number: $instanceNumber',
                          'Dimensions: ${length}x${width} $unitSymbol',
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Pricing Info
                      _buildDetailSection(
                        'Pricing',
                        Icons.attach_money,
                        [
                          'Current Price: ₹$price',
                          if (originalPrice != price) 'Original Price: ₹$originalPrice (Discounted)',
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Position Info
                      _buildDetailSection(
                        'Position',
                        Icons.location_on,
                        [
                          'Coordinates: (${positionX.round()}, ${positionY.round()})',
                          'Layout Position: Instance #$index',
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Close button
              Container(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getStatusColor(status).withOpacity(0.2),
                    foregroundColor: _getStatusColor(status),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, IconData icon, List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...details.map((detail) => Padding(
          padding: const EdgeInsets.only(left: 28, bottom: 4),
          child: Text(
            detail,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        )),
      ],
    );
  }

  // Method to edit stall instance
  Future<void> _editStallInstance(Map<String, dynamic> stallInstance, int index) async {
    final instanceId = stallInstance['instance_id'] as String?;
    final instanceNumber = stallInstance['instance_number'] as int;
    final price = (stallInstance['instance_price'] as String?) ?? '0';
    final status = stallInstance['status'] as String? ?? 'available';
    final stallName = stallInstance['name'] as String? ?? 'Unknown';
    
    // Controllers for editing
    final priceController = TextEditingController(text: price);
    final statusController = TextEditingController(text: status);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.white,
            title: Text(
              'Edit $stallName - Instance $instanceNumber',
              style: TextStyle(
                color: AppTheme.gradientBlack,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price (₹):',
                        style: TextStyle(
                          color: AppTheme.gradientBlack.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.gradientBlack.withOpacity(0.2)),
                        ),
                        child: TextFormField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            color: AppTheme.gradientBlack,
                            fontSize: 16,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(12),
                            hintText: 'Enter price',
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Status dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status:',
                        style: TextStyle(
                          color: AppTheme.gradientBlack.withOpacity(0.7),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.gradientBlack.withOpacity(0.2)),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: statusController.text,
                          items: [
                            'available',
                            'pending',
                            'payment_pending',
                            'payment_review',
                            'booked',
                            'occupied',
                            'rejected',
                            'maintenance',
                            'under_maintenance',
                          ].map((status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(
                              status.replaceAll('_', ' ').toUpperCase(),
                              style: TextStyle(
                                color: AppTheme.gradientBlack,
                                fontSize: 14,
                              ),
                            ),
                          )).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              statusController.text = value;
                              setDialogState(() {});
                            }
                          },
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
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.textMediumGray),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Validate price
                    final newPrice = double.tryParse(priceController.text);
                    if (newPrice == null || newPrice < 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Please enter a valid price'),
                          backgroundColor: AppTheme.errorRed,
                        ),
                      );
                      return;
                    }
                    
                    // Update the stall instance
                    if (instanceId != null) {
                      await SupabaseService.instance.client
                          .from('stall_instances')
                          .update({
                            'price': newPrice,
                            'status': statusController.text,
                          })
                          .eq('id', instanceId);
                      
                      // Update the local data
                      stallInstance['instance_price'] = newPrice.toString();
                      stallInstance['status'] = statusController.text;
                      
                      // Refresh the screen
                      setState(() {});
                      
                      Navigator.of(context).pop();
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Stall instance updated successfully'),
                          backgroundColor: AppTheme.successGreen,
                        ),
                      );
                    }
                  } catch (e) {
                    print('Error updating stall instance: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating stall instance: $e'),
                        backgroundColor: AppTheme.errorRed,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMaroon,
                  foregroundColor: AppTheme.white,
                ),
                child: Text('Save Changes'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Method to delete stall instance
  Future<void> _deleteStallInstance(Map<String, dynamic> stallInstance, int index) async {
    final instanceId = stallInstance['instance_id'] as String?;
    final instanceNumber = stallInstance['instance_number'] as int;
    final stallName = stallInstance['name'] as String? ?? 'Unknown';
    
    // Show confirmation dialog
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.white,
        title: Text(
          'Delete Stall Instance',
          style: TextStyle(
            color: AppTheme.errorRed,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$stallName - Instance $instanceNumber"? This action cannot be undone.',
          style: TextStyle(
            color: AppTheme.gradientBlack,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(color: AppTheme.textMediumGray),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorRed,
              foregroundColor: AppTheme.white,
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );
    
    if (shouldDelete == true && instanceId != null) {
      try {
        // Delete the stall instance from database
        await SupabaseService.instance.client
            .from('stall_instances')
            .delete()
            .eq('id', instanceId);
        
        // Refresh the screen
        setState(() {
          // Remove the instance from the list
          widget.stallInstances.removeAt(index);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Stall instance deleted successfully'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      } catch (e) {
        print('Error deleting stall instance: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting stall instance: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }
}
