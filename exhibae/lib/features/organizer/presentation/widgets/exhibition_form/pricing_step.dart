import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/services/supabase_service.dart';
import '../../../domain/models/exhibition_form_state.dart';

class PricingStep extends StatefulWidget {
  const PricingStep({super.key});

  @override
  State<PricingStep> createState() => _PricingStepState();
}

class _PricingStepState extends State<PricingStep> {
  final _priceController = TextEditingController();
  final SupabaseService _supabaseService = SupabaseService.instance;
  List<Map<String, dynamic>> _measurementUnits = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMeasurementUnits();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFormData();
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _loadFormData() {
    if (!mounted) return;
    final formState = Provider.of<ExhibitionFormState>(context, listen: false);
    if (_priceController.text.isEmpty) {
      _priceController.text = formState.formData.stallStartingPrice?.toString() ?? '';
    }
  }

  Future<void> _loadMeasurementUnits() async {
    try {
      final response = await _supabaseService.getMeasurementUnits();

      if (mounted) {
        setState(() {
          _measurementUnits = response;
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
            'Pricing',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Set up pricing details for your exhibition stalls',
            style: TextStyle(
              color: AppTheme.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          
          // Pricing Card
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
                  'Stall Pricing',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Set the starting price for stalls at your exhibition',
                  style: TextStyle(
                    color: AppTheme.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Starting Price Field
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Consumer<ExhibitionFormState>(
                    builder: (context, state, _) {
                      return TextField(
                        controller: _priceController,
                        style: const TextStyle(color: AppTheme.white),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        onChanged: (value) {
                          state.updatePricing(
                            stallStartingPrice: double.tryParse(value),
                          );
                        },
                        decoration: InputDecoration(
                          labelText: 'Starting Price (₹)',
                          labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                          prefixIcon: Icon(
                            Icons.currency_rupee,
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
                    child: Consumer<ExhibitionFormState>(
                      builder: (context, state, child) {
                        return DropdownButtonFormField<String>(
                          value: state.formData.measurementUnitId,
                          items: _measurementUnits.map((unit) {
                            return DropdownMenuItem<String>(
                              value: unit['id'] as String,
                              child: Text(
                                '${unit['name'] as String} (${unit['symbol'] as String})',
                                style: const TextStyle(color: AppTheme.white),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            state.updatePricing(measurementUnitId: value);
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
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Pricing Tips Card
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
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb,
                      color: AppTheme.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pricing Tips',
                      style: TextStyle(
                        color: AppTheme.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTipItem(
                  'Research market rates in your area for similar exhibitions',
                  Icons.search,
                ),
                const SizedBox(height: 12),
                _buildTipItem(
                  'Consider offering early bird discounts to attract vendors',
                  Icons.timer,
                ),
                const SizedBox(height: 12),
                _buildTipItem(
                  'Factor in additional services and amenities in your pricing',
                  Icons.add_circle,
                ),
                const SizedBox(height: 12),
                _buildTipItem(
                  'Be transparent about any additional charges or fees',
                  Icons.visibility,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: AppTheme.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppTheme.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
