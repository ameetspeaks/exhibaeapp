import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import 'dart:math' as math;
import 'dart:async';

class StallSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> exhibition;

  const StallSelectionScreen({
    super.key,
    required this.exhibition,
  });

  @override
  State<StallSelectionScreen> createState() => _StallSelectionScreenState();
}

class _StallSelectionScreenState extends State<StallSelectionScreen> {
  String? _selectedStallId;
  Map<String, dynamic>? _selectedStall;
  double _zoomLevel = 1.0;
  bool _showGrid = true;
  bool _isLoading = false;
  List<Map<String, dynamic>> _stalls = [];
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  // Add variables for layout bounds
  Size _layoutBounds = Size.zero;
  Offset _layoutCenter = Offset.zero;
  
  // Add TransformationController for zoom functionality
  late TransformationController _transformationController;
  
  // Add stream subscription for real-time updates
  StreamSubscription<List<Map<String, dynamic>>>? _stallSubscription;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _transformationController.addListener(_onTransformationChanged);
    _loadStalls();
    _setupRealTimeUpdates();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh stalls when returning from other screens (e.g., application form)
    _loadStalls();
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _stallSubscription?.cancel();
    super.dispose();
  }

  void _onTransformationChanged() {
    // Update zoom level based on transformation
    final matrix = _transformationController.value;
    final scale = matrix.getMaxScaleOnAxis();
    if (scale != _zoomLevel) {
      setState(() {
        _zoomLevel = scale;
      });
    }
  }

  void _zoomIn() {
    _transformationController.value = Matrix4.identity()
      ..scale(_zoomLevel * 1.2);
  }

  void _zoomOut() {
    _transformationController.value = Matrix4.identity()
      ..scale(_zoomLevel * 0.8);
  }

  void _fitToScreen() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _zoomLevel = 1.0;
    });
  }

  Future<void> _loadStalls() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stalls = await _supabaseService.getStallsByExhibition(widget.exhibition['id']);
      _processStallsData(stalls);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Set default zoom to 100% after loading
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (MediaQuery.of(context).size.width < 600) {
            _fitAllStallsToScreen();
          } else {
            _fitToScreen();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading stalls: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  // Helper method to get status display name
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
        return AppTheme.primaryBlue;
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

  void _processStallsData(List<Map<String, dynamic>> stalls) {
    print('Processing ${stalls.length} stalls with instances');
    
    // Process stalls data to extract instances
    final processedStalls = <Map<String, dynamic>>[];
    
    for (final stall in stalls) {
      print('Processing stall: ${stall['name']} (ID: ${stall['id']})');
      print('Stall data: ${stall}');
      
      final instances = stall['instances'] as List<dynamic>?;
      if (instances != null && instances.isNotEmpty) {
        print('Stall ${stall['name']} has ${instances.length} instances');
        for (final instance in instances) {
          print('Processing instance: ${instance}');
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
          print('Processed instance ${instance['id']} with status: ${processedInstance['status']}');
          processedStalls.add(processedInstance);
        }
      } else {
        // Handle stalls without instances - create a default instance
        print('Stall ${stall['name']} has no instances, creating default instance');
        final defaultInstance = {
          ...stall,
          'instance_id': stall['id'], // Use stall ID as instance ID
          'position_x': stall['position_x']?.toDouble() ?? 0.0,
          'position_y': stall['position_y']?.toDouble() ?? 0.0,
          'rotation_angle': 0.0,
          'status': stall['status'] ?? 'available',
          'instance_number': stall['stall_number'] ?? 0,
          'instance_price': stall['price']?.toString() ?? '0',
          'original_price': stall['price']?.toString() ?? '0',
        };
        print('Created default instance for stall ${stall['name']} with status: ${defaultInstance['status']}');
        processedStalls.add(defaultInstance);
      }
    }

    print('Created ${processedStalls.length} processed stalls');
    
    // Ensure all stalls have valid positions by assigning default grid positions if needed
    for (int i = 0; i < processedStalls.length; i++) {
      final stall = processedStalls[i];
      if (stall['position_x'] == null || stall['position_x'] == 0.0) {
        // Assign a grid position if no position is set
        final row = i ~/ 5; // 5 stalls per row
        final col = i % 5;
        stall['position_x'] = col * 100.0; // 100px spacing between stalls
        stall['position_y'] = row * 100.0;
        print('Assigned grid position to stall ${stall['instance_number']}: ($col, $row) -> (${stall['position_x']}, ${stall['position_y']})');
      }
    }
    
    setState(() {
      _stalls = processedStalls;
      // Use mobile layout for small screens
      if (MediaQuery.of(context).size.width < 600) {
        _calculateMobileLayoutBounds();
      } else {
        _calculateLayoutBounds();
      }
    });
  }

  void _setupRealTimeUpdates() {
    print('Setting up real-time updates for exhibition: ${widget.exhibition['id']}');
    
    // Subscribe to real-time updates for stall instances
    _stallSubscription = _supabaseService
        .subscribeToStallInstances(widget.exhibition['id'])
        .listen((stallInstances) {
          print('=== REAL-TIME UPDATE RECEIVED ===');
          print('Received ${stallInstances.length} stall instances');
          
          // Debug: Print all received instances
          for (int i = 0; i < stallInstances.length; i++) {
            final instance = stallInstances[i];
            print('Instance $i: id=${instance['id']}, status=${instance['status']}, stall_id=${instance['stall_id']}');
          }
          
          // Debug: Print current stalls before update
          print('Current stalls before update:');
          for (int i = 0; i < _stalls.length; i++) {
            final stall = _stalls[i];
            print('  Stall $i: instance_id=${stall['instance_id']}, status=${stall['status']}, name=${stall['name']}');
          }
          
          // Update the stalls list with real-time data
          if (mounted) {
            setState(() {
              // Create a map for quick lookup of instance status by ID
              final statusMap = <String, String>{};
              for (final instance in stallInstances) {
                final instanceId = instance['id']?.toString();
                final status = instance['status']?.toString();
                if (instanceId != null && status != null) {
                  statusMap[instanceId] = status;
                  print('Instance $instanceId has status: $status');
                }
              }
              
              print('Status map created: $statusMap');
              
              // Update each stall's status based on real-time data
              int updatesCount = 0;
              for (int i = 0; i < _stalls.length; i++) {
                final stall = _stalls[i];
                final instanceId = stall['instance_id']?.toString();
                
                if (instanceId != null && statusMap.containsKey(instanceId)) {
                  final oldStatus = _stalls[i]['status'];
                  final newStatus = statusMap[instanceId]!;
                  
                  if (oldStatus != newStatus) {
                    _stalls[i]['status'] = newStatus;
                    print('✅ Updated stall $i (instance $instanceId) status: $oldStatus -> $newStatus');
                    updatesCount++;
                  } else {
                    print('⏭️  Stall $i (instance $instanceId) status unchanged: $oldStatus');
                  }
                } else {
                  print('❌ Stall $i: instance_id=$instanceId, not found in status map');
                }
              }
              
              print('Total stalls updated: $updatesCount');
            });
          }
        }, onError: (error) {
          print('❌ Error in real-time stall updates: $error');
        });
  }

  void _calculateLayoutBounds() {
    if (_stalls.isEmpty) {
      _layoutBounds = const Size(400, 300);
      _layoutCenter = const Offset(200, 150);
      return;
    }

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = -double.infinity;
    double maxY = -double.infinity;

    print('=== CALCULATING LAYOUT BOUNDS ===');
    for (final stall in _stalls) {
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

    _layoutBounds = Size(maxX - minX, maxY - minY);
    _layoutCenter = Offset(
      (maxX + minX) / 2,
      (maxY + minY) / 2,
    );

    print('Final layout bounds: ${_layoutBounds.width} × ${_layoutBounds.height}');
    print('Layout center: ${_layoutCenter.dx}, ${_layoutCenter.dy}');

    // Normalize stall positions to start from (0,0)
    for (final stall in _stalls) {
      final originalX = stall['position_x']?.toDouble() ?? 0.0;
      final originalY = stall['position_y']?.toDouble() ?? 0.0;
      
      stall['normalized_x'] = originalX - minX;
      stall['normalized_y'] = originalY - minY;
      
      final instanceNumber = stall['instance_number'] ?? 'unknown';
      print('Stall $instanceNumber: normalized position (${stall['normalized_x']}, ${stall['normalized_y']})');
    }
  }

        // Mobile-optimized layout calculation
    void _calculateMobileLayoutBounds() {
      if (_stalls.isEmpty) {
        _layoutBounds = const Size(400, 300);
        _layoutCenter = const Offset(200, 150);
        return;
      }

      // For mobile, arrange stalls in a fixed 3-column grid layout
      final screenSize = MediaQuery.of(context).size;
      final availableWidth = screenSize.width - 32; // Reduced margins for better space usage
      
      // Fixed 3 columns for better mobile layout
      final cols = 3;
      final stallCount = _stalls.length;
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
      _layoutBounds = Size(totalWidth, totalHeight);
      _layoutCenter = Offset(totalWidth / 2, totalHeight / 2);
      
      print('=== MOBILE LAYOUT CALCULATION ===');
      print('Screen size: ${screenSize.width} × ${screenSize.height}');
      print('Available width: $availableWidth');
      print('Grid: ${cols} × ${rows} (Fixed 3 columns)');
      print('Stall size: ${stallSize.round()} × ${stallSize.round()}');
      print('Spacing: $spacing');
      print('Total layout: ${totalWidth.round()} × ${totalHeight.round()}');
      
      // Assign grid positions to stalls
      for (int i = 0; i < _stalls.length; i++) {
        final stall = _stalls[i];
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

     void _centerView() {
     // This will center the view on the layout
     final screenSize = MediaQuery.of(context).size;
     final isSmallScreen = screenSize.width < 600;
     
     if (isSmallScreen) {
       // For mobile, center the layout and fit to width
       _fitAllStallsToScreen();
     } else {
       // For desktop, reset to center
       setState(() {
         _zoomLevel = 1.0;
       });
       _transformationController.value = Matrix4.identity()..scale(1.0);
     }
   }

     void _fitAllStallsToScreen() {
     if (_stalls.isEmpty) return;
     
     // Calculate the scale needed to fit all stalls
     final screenSize = MediaQuery.of(context).size;
     final isSmallScreen = screenSize.width < 600;
     
     if (isSmallScreen) {
       // For mobile, fit to width and allow vertical scrolling
       final availableWidth = screenSize.width - 32;
       final scale = availableWidth / _layoutBounds.width;
       final finalScale = math.min(scale, 1.0); // Don't scale up beyond 1.0
       
       print('Mobile fit: available width=$availableWidth, layout width=${_layoutBounds.width}, scale=$finalScale');
       
       setState(() {
         _zoomLevel = finalScale;
       });
       _transformationController.value = Matrix4.identity()..scale(finalScale);
     } else {
       // For desktop, fit both dimensions
       final availableWidth = screenSize.width - 64;
       final availableHeight = screenSize.height * 0.5;
       
       final scaleX = availableWidth / _layoutBounds.width;
       final scaleY = availableHeight / _layoutBounds.height;
       final scale = math.min(math.min(scaleX, scaleY), 1.0);
       
       print('Desktop fit: available=${availableWidth}×${availableHeight}, layout=${_layoutBounds.width}×${_layoutBounds.height}, scale=$scale');
       
       setState(() {
         _zoomLevel = scale;
       });
       _transformationController.value = Matrix4.identity()..scale(scale);
     }
   }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundLightGray,
      appBar: AppBar(
        backgroundColor: AppTheme.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.grid_on,
                color: AppTheme.primaryBlue,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.exhibition['title'] ?? 'Exhibition',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDarkCharcoal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Step 1 of 3: Choose Stall',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: AppTheme.textMediumGray,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showGrid ? Icons.grid_off : Icons.grid_on,
              color: AppTheme.primaryBlue,
            ),
            onPressed: () {
              setState(() {
                _showGrid = !_showGrid;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter section
          Container(
            padding: EdgeInsets.all(isSmallScreen ? 8 : 16),
            color: AppTheme.white,
            child: Column(
              children: [
                // Top Row - Zoom Controls and Grid Toggle
                Row(
                  children: [
                    // Zoom Controls
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundLightGray,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: isSmallScreen ? 36 : 44,
                            height: isSmallScreen ? 36 : 44,
                            child: IconButton(
                              icon: Icon(Icons.remove, size: isSmallScreen ? 16 : 20),
                              onPressed: () {
                                if (_zoomLevel > 0.5) {
                                  final newZoom = _zoomLevel - 0.1;
                                  setState(() {
                                    _zoomLevel = newZoom;
                                  });
                                  _transformationController.value = Matrix4.identity()..scale(newZoom);
                                }
                              },
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 6 : 8),
                            child: Text(
                              '${(_zoomLevel * 100).round()}%',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: isSmallScreen ? 10 : 12,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: isSmallScreen ? 36 : 44,
                            height: isSmallScreen ? 36 : 44,
                            child: IconButton(
                              icon: Icon(Icons.add, size: isSmallScreen ? 16 : 20),
                              onPressed: () {
                                if (_zoomLevel < 2.0) {
                                  final newZoom = _zoomLevel + 0.1;
                                  setState(() {
                                    _zoomLevel = newZoom;
                                  });
                                  _transformationController.value = Matrix4.identity()..scale(newZoom);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: isSmallScreen ? 6 : 8),
                    // Center View Button - Compact on small screens
                    if (!isSmallScreen) ...[
                      SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: _centerView,
                          icon: const Icon(Icons.center_focus_strong, size: 18),
                          label: const Text(
                            'Center',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: AppTheme.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    // Reset View Button - Compact on small screens
                    if (!isSmallScreen) ...[
                      SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: _fitToScreen,
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text(
                            'Reset',
                            style: TextStyle(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.textMediumGray,
                            foregroundColor: AppTheme.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Spacer(),
                    // Grid Toggle
                    SizedBox(
                      width: isSmallScreen ? 36 : 44,
                      height: isSmallScreen ? 36 : 44,
                      child: IconButton(
                        icon: Icon(
                          _showGrid ? Icons.grid_off : Icons.grid_on,
                          color: AppTheme.primaryBlue,
                          size: isSmallScreen ? 16 : 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _showGrid = !_showGrid;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                                 // Additional controls row for small screens
                 if (isSmallScreen) ...[
                   const SizedBox(height: 12),
                   Row(
                     children: [
                       Expanded(
                         child: SizedBox(
                           height: 40,
                           child: ElevatedButton.icon(
                             onPressed: _centerView,
                             icon: const Icon(Icons.center_focus_strong, size: 16),
                             label: const Text(
                               'Center View',
                               style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                             ),
                             style: ElevatedButton.styleFrom(
                               backgroundColor: AppTheme.backgroundLightGray,
                               foregroundColor: AppTheme.textDarkCharcoal,
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(8),
                               ),
                             ),
                           ),
                         ),
                       ),
                       const SizedBox(width: 12),
                       Expanded(
                         child: SizedBox(
                           height: 40,
                           child: ElevatedButton.icon(
                             onPressed: _fitAllStallsToScreen,
                             icon: const Icon(Icons.fit_screen, size: 16),
                             label: const Text(
                               'Show All Stalls',
                               style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                             ),
                             style: ElevatedButton.styleFrom(
                               backgroundColor: AppTheme.primaryBlue,
                               foregroundColor: AppTheme.white,
                               shape: RoundedRectangleBorder(
                                 borderRadius: BorderRadius.circular(8),
                               ),
                             ),
                           ),
                         ),
                       ),
                     ],
                   ),
                 ],
                SizedBox(height: isSmallScreen ? 8 : 12),
                // Legend - Responsive Layout
                _buildResponsiveLegend(isSmallScreen),
                                 // Layout Info (for debugging)
                 if (!_isLoading && _stalls.isNotEmpty)
                   Padding(
                     padding: EdgeInsets.only(top: isSmallScreen ? 4 : 8),
                     child: Column(
                       children: [
                         Text(
                           'Layout: ${_layoutBounds.width.round()} × ${_layoutBounds.height.round()} | Stalls: ${_stalls.length}',
                           style: TextStyle(
                             fontSize: isSmallScreen ? 8 : 12,
                             color: AppTheme.textMediumGray,
                           ),
                         ),
                                                   if (isSmallScreen) ...[
                            const SizedBox(height: 4),
                            Text(
                              '3-Column Grid Layout • ${_stalls.length} Stalls',
                              style: TextStyle(
                                fontSize: 9,
                                color: AppTheme.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tap a stall to view details and apply',
                              style: TextStyle(
                                fontSize: 8,
                                color: AppTheme.textMediumGray,
                              ),
                            ),
                          ],
                       ],
                     ),
                   ),
              ],
            ),
          ),
          
          // Main Layout Section
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                                     // Layout Header - Simplified for mobile
                   if (!isSmallScreen) ...[
                     Container(
                       padding: const EdgeInsets.all(20),
                       decoration: BoxDecoration(
                         color: AppTheme.primaryBlue.withOpacity(0.05),
                         borderRadius: const BorderRadius.only(
                           topLeft: Radius.circular(16),
                           topRight: Radius.circular(16),
                         ),
                       ),
                       child: Row(
                         children: [
                           Container(
                             padding: const EdgeInsets.all(8),
                             decoration: BoxDecoration(
                               color: AppTheme.primaryBlue.withOpacity(0.1),
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: Icon(
                               Icons.map,
                               color: AppTheme.primaryBlue,
                               size: 24,
                             ),
                           ),
                           const SizedBox(width: 16),
                           Expanded(
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   'All Stalls - ${_stalls.length} total',
                                   style: TextStyle(
                                     fontSize: 16,
                                     fontWeight: FontWeight.w600,
                                     color: AppTheme.textDarkCharcoal,
                                   ),
                                 ),
                                 const SizedBox(height: 4),
                                 Text(
                                   'Select an available stall to apply',
                                   style: TextStyle(
                                     fontSize: 14,
                                     color: AppTheme.textMediumGray,
                                   ),
                                 ),
                               ],
                             ),
                           ),
                           // Zoom Controls (only for desktop)
                           Row(
                             children: [
                               IconButton(
                                 onPressed: () => _zoomIn(),
                                 icon: const Icon(Icons.zoom_in),
                                 tooltip: 'Zoom In',
                               ),
                               IconButton(
                                 onPressed: () => _zoomOut(),
                                 icon: const Icon(Icons.zoom_out),
                                 tooltip: 'Zoom Out',
                               ),
                               IconButton(
                                 onPressed: () => _fitToScreen(),
                                 icon: const Icon(Icons.fit_screen),
                                 tooltip: 'Fit to Screen',
                               ),
                             ],
                           ),
                         ],
                       ),
                     ),
                   ],
                  
                  // Layout Content
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                            ),
                          )
                        : _stalls.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.grid_off,
                                      size: 64,
                                      color: AppTheme.textMediumGray,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No stalls available',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textDarkCharcoal,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Stalls will be added to the layout soon.',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppTheme.textMediumGray,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                                                                 child: InteractiveViewer(
                                   transformationController: _transformationController,
                                   minScale: isSmallScreen ? 0.3 : 0.5,
                                   maxScale: isSmallScreen ? 2.0 : 3.0,
                                   boundaryMargin: EdgeInsets.all(isSmallScreen ? 50 : 100),
                                   child: SizedBox(
                                     width: _layoutBounds.width,
                                     height: _layoutBounds.height,
                                     child: Stack(
                                       children: [
                                         // Grid Background
                                         if (_showGrid)
                                           CustomPaint(
                                             painter: GridPainter(),
                                             size: _layoutBounds,
                                           ),
                                         
                                         // Stalls
                                         ..._stalls.map((stall) => _buildResponsiveStall(stall)),
                                       ],
                                     ),
                                   ),
                                 ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // Mobile-Optimized Bottom Sheet
      bottomSheet: _selectedStall != null ? _buildMobileStallInfoPanel(isSmallScreen) : null,
    );
  }

  Widget _buildResponsiveGrid(bool isSmallScreen) {
    return CustomPaint(
      size: _layoutBounds,
      painter: GridPainter(),
    );
  }

     Widget _buildResponsiveStall(Map<String, dynamic> stall) {
     final isSelected = _selectedStallId == stall['instance_id'];
     final status = stall['status']?.toString() ?? 'available';
     final isAvailable = status == 'available';
     final instanceNumber = stall['instance_number'] ?? 'unknown';
     
     // Responsive stall dimensions based on screen size
     final screenSize = MediaQuery.of(context).size;
     final isSmallScreen = screenSize.width < 600;
     
           // For mobile, use calculated size from layout; for desktop, use fixed size
      double stallSize;
      if (isSmallScreen) {
        // Use the calculated stall size from mobile layout
        final availableWidth = screenSize.width - 32;
        final spacing = 20.0; // Match the spacing used in _calculateMobileLayoutBounds
        stallSize = (availableWidth - 2 * spacing) / 3; // 3 columns
      } else {
        stallSize = 40.0; // Fixed size for desktop
      }
     
     // Determine stall color based on status (matching web interface)
     Color stallColor;
     if (isSelected) {
       stallColor = AppTheme.primaryBlue;
     } else {
       stallColor = _getStatusColor(status).withOpacity(0.3);
     }
     
     final normalizedX = stall['normalized_x']?.toDouble() ?? stall['position_x']?.toDouble() ?? 0.0;
     final normalizedY = stall['normalized_y']?.toDouble() ?? stall['position_y']?.toDouble() ?? 0.0;
     
     print('Rendering stall $instanceNumber at position ($normalizedX, $normalizedY) with status: $status, size: ${stallSize.round()}');
     
     return Positioned(
       left: normalizedX,
       top: normalizedY,
      child: GestureDetector(
        onTap: () {
          // Only allow selection of available stalls
          if (isAvailable) {
            setState(() {
              _selectedStallId = stall['instance_id'];
              _selectedStall = stall;
            });
          }
        },
        child: Tooltip(
          message: '${stall['name']} - ${_getStatusDisplayName(status)}',
                           child: Container(
           width: stallSize,
           height: stallSize,
           decoration: BoxDecoration(
             color: stallColor,
             border: Border.all(
               color: isSelected ? AppTheme.primaryBlue : AppTheme.textMediumGray.withOpacity(0.3),
               width: isSelected ? 3 : 1,
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
                 '${stall['instance_number']}',
                 style: TextStyle(
                   color: isSelected ? AppTheme.white : AppTheme.textDarkCharcoal,
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

  Widget _buildResponsiveLegend(bool isSmallScreen) {
    if (isSmallScreen) {
      // Stacked layout for small screens
      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Available', AppTheme.successGreen, isSmallScreen),
              _buildLegendItem('Pending', AppTheme.warningOrange, isSmallScreen),
            ],
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Payment Pending', AppTheme.secondaryGold, isSmallScreen),
              _buildLegendItem('Payment Review', AppTheme.primaryBlue, isSmallScreen),
            ],
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Booked', AppTheme.errorRed, isSmallScreen),
              _buildLegendItem('Rejected', AppTheme.errorRed, isSmallScreen),
            ],
          ),
          SizedBox(height: isSmallScreen ? 4 : 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildLegendItem('Under Maintenance', AppTheme.textMediumGray, isSmallScreen),
              _buildLegendItem('Selected', AppTheme.primaryBlue, isSmallScreen),
            ],
          ),
        ],
      );
    } else {
      // Horizontal layout for larger screens
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildLegendItem('Available', AppTheme.successGreen, isSmallScreen),
          const SizedBox(width: 16),
          _buildLegendItem('Pending', AppTheme.warningOrange, isSmallScreen),
          const SizedBox(width: 16),
          _buildLegendItem('Payment Pending', AppTheme.secondaryGold, isSmallScreen),
          const SizedBox(width: 16),
          _buildLegendItem('Payment Review', AppTheme.primaryBlue, isSmallScreen),
          const SizedBox(width: 16),
          _buildLegendItem('Booked', AppTheme.errorRed, isSmallScreen),
          const SizedBox(width: 16),
          _buildLegendItem('Rejected', AppTheme.errorRed, isSmallScreen),
          const SizedBox(width: 16),
          _buildLegendItem('Under Maintenance', AppTheme.textMediumGray, isSmallScreen),
          const SizedBox(width: 16),
          _buildLegendItem('Selected', AppTheme.primaryBlue, isSmallScreen),
        ],
      );
    }
  }

  Widget _buildLegendItem(String label, Color color, bool isSmallScreen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isSmallScreen ? 8 : 12,
          height: isSmallScreen ? 8 : 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: isSmallScreen ? 3 : 4),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 8 : 12,
            color: AppTheme.textMediumGray,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileStallInfoPanel(bool isSmallScreen) {
    if (_selectedStall == null) return const SizedBox.shrink();
    
    return Container(
      height: isSmallScreen ? 280 : 320,
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMediumGray.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 8 : 12,
                  vertical: isSmallScreen ? 4 : 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Stall ${_selectedStall!['instance_number']}',
                  style: TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedStallId = null;
                      _selectedStall = null;
                    });
                  },
                  icon: const Icon(Icons.close, size: 20),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Stall Details - Responsive Layout
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Size and Price Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildDetailItem(
                          'Size',
                          '${_selectedStall!['length']} × ${_selectedStall!['width']} m',
                          isSmallScreen,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDetailItem(
                          'Price',
                          '₹${_selectedStall!['instance_price']?.toString() ?? '0'}',
                          isSmallScreen,
                          isPrice: true,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Price Details
                  _buildDetailRow(
                    Icons.attach_money,
                    '₹${_selectedStall!['instance_price']?.toString() ?? '0'}',
                    isSmallScreen,
                    isBold: true,
                  ),
                  
                  if (_selectedStall!['original_price'] != null && 
                      _selectedStall!['original_price'] != _selectedStall!['instance_price']) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      Icons.local_offer,
                      '₹${_selectedStall!['original_price']?.toString() ?? '0'} (Original)',
                      isSmallScreen,
                      isStrikethrough: true,
                    ),
                  ],
                  
                  const SizedBox(height: 16),
                  
                  // Position
                  _buildDetailRow(
                    Icons.location_on,
                    'Position: (${_selectedStall!['position_x']}, ${_selectedStall!['position_y']})',
                    isSmallScreen,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Instance Number
                  _buildDetailRow(
                    Icons.numbers,
                    'Instance #${_selectedStall!['instance_number']}',
                    isSmallScreen,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Amenities
                  if (_getStallAmenities(_selectedStall!).isNotEmpty) ...[
                    Text(
                      'Amenities:',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDarkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _getStallAmenities(_selectedStall!).take(4).map((amenity) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundLightGray,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            amenity,
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12,
                              color: AppTheme.textMediumGray,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    height: isSmallScreen ? 48 : 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, {
                          'selectedStall': _selectedStall,
                          'action': 'apply',
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        foregroundColor: AppTheme.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Apply for This Stall',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, bool isSmallScreen, {bool isPrice = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallScreen ? 10 : 12,
            color: AppTheme.textMediumGray,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: isPrice ? AppTheme.primaryBlue : AppTheme.textDarkCharcoal,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String text, bool isSmallScreen, {
    bool isBold = false,
    bool isStrikethrough = false,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryBlue,
          size: isSmallScreen ? 16 : 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: isSmallScreen ? 12 : 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: AppTheme.textDarkCharcoal,
              decoration: isStrikethrough ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ],
    );
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

// Grid Painter for responsive grid
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.textMediumGray.withOpacity(0.2)
      ..strokeWidth = 1;

    // Vertical lines
    for (double x = 0; x <= size.width; x += 20) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y <= size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
