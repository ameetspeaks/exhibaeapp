import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/models/stall_form_state.dart';

class LayoutStep extends StatefulWidget {
  const LayoutStep({super.key});

  @override
  State<LayoutStep> createState() => _LayoutStepState();
}

class _LayoutStepState extends State<LayoutStep> {
  final _instanceCountController = TextEditingController();
  final _rowCountController = TextEditingController();
  final _columnCountController = TextEditingController();
  final _spacingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _instanceCountController.text = '1';
    _rowCountController.text = '1';
    _columnCountController.text = '1';
    _spacingController.text = '1';
  }

  @override
  void dispose() {
    _instanceCountController.dispose();
    _rowCountController.dispose();
    _columnCountController.dispose();
    _spacingController.dispose();
    super.dispose();
  }

  void _generateLayout() {
    final formState = context.read<StallFormState>();
    final instanceCount = int.tryParse(_instanceCountController.text) ?? 1;
    final rows = int.tryParse(_rowCountController.text) ?? 1;
    final columns = int.tryParse(_columnCountController.text) ?? 1;
    final spacing = double.tryParse(_spacingController.text) ?? 1;

    // Clear existing instances
    formState.formData.instances.clear();

    // Calculate dimensions
    final stallWidth = formState.formData.width;
    final stallHeight = formState.formData.length;
    final totalWidth = (stallWidth * columns) + (spacing * (columns - 1));
    final totalHeight = (stallHeight * rows) + (spacing * (rows - 1));

    // Generate instances
    int instanceNumber = 1;
    for (int row = 0; row < rows && instanceNumber <= instanceCount; row++) {
      for (int col = 0; col < columns && instanceNumber <= instanceCount; col++) {
        final x = col * (stallWidth + spacing);
        final y = row * (stallHeight + spacing);

        formState.addStallInstance(
          instanceNumber: instanceNumber,
          positionX: x,
          positionY: y,
        );

        instanceNumber++;
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
            'Layout',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Configure the layout for your stall instances',
            style: TextStyle(
              color: AppTheme.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          
          // Layout Generator
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.white.withOpacity(0.1),
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
                  'Layout Generator',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Instance Count
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _instanceCountController,
                    style: const TextStyle(color: AppTheme.white),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: InputDecoration(
                      labelText: 'Number of Stalls',
                      labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Grid Configuration
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _rowCountController,
                          style: const TextStyle(color: AppTheme.white),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Rows',
                            labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TextField(
                          controller: _columnCountController,
                          style: const TextStyle(color: AppTheme.white),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Columns',
                            labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Spacing
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    controller: _spacingController,
                    style: const TextStyle(color: AppTheme.white),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Spacing between stalls',
                      labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Generate Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _generateLayout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.white,
                      foregroundColor: AppTheme.gradientBlack,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Generate Layout'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Layout Preview
          Consumer<StallFormState>(
            builder: (context, state, child) {
              final instances = state.formData.instances;
              if (instances.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.grid_off,
                        size: 48,
                        color: AppTheme.white.withOpacity(0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No stall instances yet',
                        style: TextStyle(
                          color: AppTheme.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Use the layout generator above to create stall instances',
                        style: TextStyle(
                          color: AppTheme.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.white.withOpacity(0.1),
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
                      'Layout Preview',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: AppTheme.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: InteractiveViewer(
                        boundaryMargin: const EdgeInsets.all(20),
                        minScale: 0.5,
                        maxScale: 4.0,
                        child: Stack(
                          children: instances.map((instance) {
                            return Positioned(
                              left: instance['position_x'].toDouble(),
                              top: instance['position_y'].toDouble(),
                              child: Transform.rotate(
                                angle: instance['rotation_angle'].toDouble(),
                                child: Container(
                                  width: state.formData.width,
                                  height: state.formData.length,
                                  decoration: BoxDecoration(
                                    color: AppTheme.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppTheme.white.withOpacity(0.4),
                                      width: 1,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '#${instance['instance_number']}',
                                      style: const TextStyle(
                                        color: AppTheme.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${instances.length} stall instances',
                      style: TextStyle(
                        color: AppTheme.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
