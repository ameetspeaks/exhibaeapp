import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/supabase_service.dart';
import '../../../domain/models/stall_form_state.dart';

class DimensionsStep extends StatefulWidget {
  const DimensionsStep({super.key});

  @override
  State<DimensionsStep> createState() => _DimensionsStepState();
}

class _DimensionsStepState extends State<DimensionsStep> {
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService.instance;
  
  List<Map<String, dynamic>> _measurementUnits = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFormData();
    _loadMeasurementUnits();
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _loadFormData() {
    final formState = context.read<StallFormState>();
    _lengthController.text = formState.formData.length > 0
        ? formState.formData.length.toString()
        : '';
    _widthController.text = formState.formData.width > 0
        ? formState.formData.width.toString()
        : '';
    _heightController.text = formState.formData.height > 0
        ? formState.formData.height.toString()
        : '';
  }

  Future<void> _loadMeasurementUnits() async {
    try {
      final response = await _supabaseService.client
          .from('measurement_units')
          .select()
          .order('name');

      if (mounted) {
        setState(() {
          _measurementUnits = List<Map<String, dynamic>>.from(response);
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dimensions',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set the dimensions for your stall',
            style: TextStyle(
              color: AppTheme.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          
          // Measurement Unit Dropdown
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.white),
              ),
            )
          else if (_error != null)
            Center(
              child: Text(
                'Error loading measurement units: $_error',
                style: TextStyle(
                  color: AppTheme.errorRed,
                  fontSize: 14,
                ),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppTheme.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Consumer<StallFormState>(
                builder: (context, state, child) {
                  return DropdownButtonFormField<String>(
                    value: state.formData.measurementUnitId,
                    items: _measurementUnits.map((unit) {
                      return DropdownMenuItem(
                        value: unit['id'],
                        child: Text(
                          '${unit['name']} (${unit['symbol']})',
                          style: const TextStyle(color: AppTheme.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      state.updateDimensions(measurementUnitId: value);
                    },
                    dropdownColor: AppTheme.gradientBlack,
                    style: const TextStyle(color: AppTheme.white),
                    decoration: InputDecoration(
                      labelText: 'Measurement Unit',
                      labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                      prefixIcon: Icon(
                        Icons.straighten,
                        color: AppTheme.white.withOpacity(0.8),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          
          // Length Field
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
              controller: _lengthController,
              style: const TextStyle(color: AppTheme.white),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (value) {
                context.read<StallFormState>().updateDimensions(
                  length: double.tryParse(value) ?? 0,
                );
              },
              decoration: InputDecoration(
                labelText: 'Length',
                labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                prefixIcon: Icon(
                  Icons.straighten,
                  color: AppTheme.white.withOpacity(0.8),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Width Field
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
              controller: _widthController,
              style: const TextStyle(color: AppTheme.white),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (value) {
                context.read<StallFormState>().updateDimensions(
                  width: double.tryParse(value) ?? 0,
                );
              },
              decoration: InputDecoration(
                labelText: 'Width',
                labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                prefixIcon: Icon(
                  Icons.straighten,
                  color: AppTheme.white.withOpacity(0.8),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Height Field
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
              controller: _heightController,
              style: const TextStyle(color: AppTheme.white),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (value) {
                context.read<StallFormState>().updateDimensions(
                  height: double.tryParse(value) ?? 0,
                );
              },
              decoration: InputDecoration(
                labelText: 'Height',
                labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                prefixIcon: Icon(
                  Icons.straighten,
                  color: AppTheme.white.withOpacity(0.8),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Dimensions Preview
          Consumer<StallFormState>(
            builder: (context, state, child) {
              final formData = state.formData;
              final unit = _measurementUnits.firstWhere(
                (u) => u['id'] == formData.measurementUnitId,
                orElse: () => {'symbol': ''},
              );
              final symbol = unit['symbol'] ?? '';
              
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
                    Row(
                      children: [
                        Icon(
                          Icons.preview,
                          color: AppTheme.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Dimensions Preview',
                          style: TextStyle(
                            color: AppTheme.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppTheme.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Icon(
                                  Icons.grid_on,
                                  size: 48,
                                  color: AppTheme.white.withOpacity(0.6),
                                ),
                              ),
                              if (formData.length > 0 && formData.width > 0)
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 8,
                                  child: Text(
                                    '${formData.length}$symbol × ${formData.width}$symbol',
                                    style: const TextStyle(
                                      color: AppTheme.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Length: ${formData.length}$symbol',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Width: ${formData.width}$symbol',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Height: ${formData.height}$symbol',
                              style: TextStyle(
                                color: AppTheme.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Area: ${(formData.length * formData.width).toStringAsFixed(2)}$symbol²',
                              style: const TextStyle(
                                color: AppTheme.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
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
