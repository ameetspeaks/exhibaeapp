import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';

class StallLayoutScreen extends StatefulWidget {
  final String exhibitionId;

  const StallLayoutScreen({
    super.key,
    required this.exhibitionId,
  });

  @override
  State<StallLayoutScreen> createState() => _StallLayoutScreenState();
}

class _StallLayoutScreenState extends State<StallLayoutScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  List<Map<String, dynamic>> _stallInstances = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStallLayout();
  }

  Future<void> _loadStallLayout() async {
    try {
      final instances = await _supabaseService.getStallInstancesWithLayout(widget.exhibitionId);
      
      if (mounted) {
        setState(() {
          _stallInstances = instances;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.gradientBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Stall Layout',
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.arrow_back,
              color: AppTheme.white,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error loading layout',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: AppTheme.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStallLayout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.white.withOpacity(0.2),
                          foregroundColor: AppTheme.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Layout Container
                      Container(
                        width: double.infinity,
                        height: 600,
                        decoration: BoxDecoration(
                          color: AppTheme.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppTheme.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          children: _stallInstances.map((instance) {
                            final stall = instance['stall'] as Map<String, dynamic>?;
                            final positionX = (instance['position_x'] as num?)?.toDouble() ?? 0.0;
                            final positionY = (instance['position_y'] as num?)?.toDouble() ?? 0.0;
                            final length = (instance['length'] as num?)?.toDouble() ?? 0.0;
                            final width = (instance['width'] as num?)?.toDouble() ?? 0.0;
                            final status = instance['status'] as String? ?? 'available';
                            final instanceNumber = instance['instance_number'] as int? ?? 1;
                            final stallName = stall?['name'] as String? ?? 'Unknown';
                            final price = (stall?['price'] as num?)?.toDouble() ?? 0.0;
                            final unit = stall?['unit'] as Map<String, dynamic>?;
                            final unitSymbol = unit?['symbol'] as String? ?? '';

                            return Positioned(
                              left: positionX,
                              top: positionY,
                              child: Container(
                                width: length,
                                height: width,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(status),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: AppTheme.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      stallName,
                                      style: const TextStyle(
                                        color: AppTheme.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '#$instanceNumber',
                                      style: TextStyle(
                                        color: AppTheme.white.withOpacity(0.8),
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${price.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: AppTheme.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${length.toStringAsFixed(0)}×${width.toStringAsFixed(0)} $unitSymbol',
                                      style: TextStyle(
                                        color: AppTheme.white.withOpacity(0.7),
                                        fontSize: 9,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Legend
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status Legend',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 16,
                              runSpacing: 8,
                              children: [
                                _buildLegendItem('Available', _getStatusColor('available')),
                                _buildLegendItem('Booked', _getStatusColor('booked')),
                                _buildLegendItem('Reserved', _getStatusColor('reserved')),
                                _buildLegendItem('Pending', _getStatusColor('pending')),
                                _buildLegendItem('Under Maintenance', _getStatusColor('under_maintenance')),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Statistics
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Layout Statistics',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatItem(
                                    'Total Stalls',
                                    _stallInstances.length.toString(),
                                    Icons.grid_view,
                                  ),
                                ),
                                Expanded(
                                  child: _buildStatItem(
                                    'Available',
                                    _stallInstances
                                        .where((instance) => instance['status'] == 'available')
                                        .length
                                        .toString(),
                                    Icons.check_circle,
                                  ),
                                ),
                                Expanded(
                                  child: _buildStatItem(
                                    'Booked',
                                    _stallInstances
                                        .where((instance) => instance['status'] == 'booked')
                                        .length
                                        .toString(),
                                    Icons.bookmark,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green.withOpacity(0.8);
      case 'booked':
        return Colors.red.withOpacity(0.8);
      case 'reserved':
        return Colors.orange.withOpacity(0.8);
      case 'pending':
        return Colors.yellow.withOpacity(0.8);
      case 'under_maintenance':
        return Colors.grey.withOpacity(0.8);
      default:
        return Colors.blue.withOpacity(0.8);
    }
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: AppTheme.white,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
