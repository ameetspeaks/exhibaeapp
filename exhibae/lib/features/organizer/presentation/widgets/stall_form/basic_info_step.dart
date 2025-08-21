import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../domain/models/stall_form_state.dart';

class BasicInfoStep extends StatefulWidget {
  const BasicInfoStep({super.key});

  @override
  State<BasicInfoStep> createState() => _BasicInfoStepState();
}

class _BasicInfoStepState extends State<BasicInfoStep> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFormData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _loadFormData() {
    final formState = context.read<StallFormState>();
    _nameController.text = formState.formData.name;
    _priceController.text = formState.formData.price > 0
        ? formState.formData.price.toString()
        : '';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the basic details about your stall',
            style: TextStyle(
              color: AppTheme.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          
          // Name Field
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
              controller: _nameController,
              style: const TextStyle(color: AppTheme.white),
              onChanged: (value) {
                context.read<StallFormState>().updateBasicInfo(
                  name: value,
                );
              },
              decoration: InputDecoration(
                labelText: 'Stall Name',
                labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 16),
          

          
          // Price Field
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
              controller: _priceController,
              style: const TextStyle(color: AppTheme.white),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (value) {
                context.read<StallFormState>().updateBasicInfo(
                  price: double.tryParse(value) ?? 0,
                );
              },
              decoration: InputDecoration(
                labelText: 'Price (₹)',
                labelStyle: TextStyle(color: AppTheme.white.withOpacity(0.8)),
                prefixIcon: Icon(
                  Icons.currency_rupee,
                  color: AppTheme.white.withOpacity(0.8),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Pricing Tips
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
                  'Set competitive prices based on stall size and location',
                  Icons.trending_up,
                ),
                const SizedBox(height: 12),
                _buildTipItem(
                  'Consider offering early bird discounts',
                  Icons.timer,
                ),
                const SizedBox(height: 12),
                _buildTipItem(
                  'Factor in amenities and additional services',
                  Icons.add_circle,
                ),
                const SizedBox(height: 12),
                _buildTipItem(
                  'Be transparent about any additional charges',
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
