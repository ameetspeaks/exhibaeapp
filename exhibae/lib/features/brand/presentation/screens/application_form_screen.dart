import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';

class ApplicationFormScreen extends StatefulWidget {
  final Map<String, dynamic> exhibition;
  final Map<String, dynamic>? selectedStall;

  const ApplicationFormScreen({
    super.key,
    required this.exhibition,
    this.selectedStall,
  });

  @override
  State<ApplicationFormScreen> createState() => _ApplicationFormScreenState();
}

class _ApplicationFormScreenState extends State<ApplicationFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedStallType = '';
  bool _isLoading = false;
  bool _acceptTerms = true; // Set to true by default as requested
  final SupabaseService _supabaseService = SupabaseService.instance;

  final List<String> _stallTypes = [
    'Standard Stall (3m x 3m)',
    'Premium Stall (4m x 4m)',
    'Deluxe Stall (6m x 4m)',
    'Custom Stall',
  ];

  List<String> get _dynamicStallTypes {
    if (widget.selectedStall != null) {
      final length = widget.selectedStall!['length'];
      final width = widget.selectedStall!['width'];
      if (length != null && width != null) {
        return ['${length}m × ${width}m Stall'];
      }
    }
    return _stallTypes;
  }

  @override
  void initState() {
    super.initState();
    if (widget.selectedStall != null) {
      // Don't set _selectedStallType to instance_id - it should be a stall type string
      // _selectedStallType = widget.selectedStall!['instance_id']?.toString() ?? '';
      
      // Auto-set stall type based on selected stall dimensions
      final length = widget.selectedStall!['length'];
      final width = widget.selectedStall!['width'];
      if (length != null && width != null) {
        _selectedStallType = '${length}m × ${width}m Stall';
      }
    }
    
    // Pre-fill form with user data if available
    _prefillForm();
  }



  Future<void> _prefillForm() async {
    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser != null) {
        final profile = await _supabaseService.getUserProfile(currentUser.id);
        if (profile != null) {
          setState(() {
            _companyNameController.text = profile['company_name'] ?? '';
            _contactPersonController.text = profile['full_name'] ?? '';
            _emailController.text = profile['email'] ?? currentUser.email ?? '';
            _phoneController.text = profile['phone'] ?? '';
            _websiteController.text = profile['website_url'] ?? '';
          });
        }
      }
    } catch (e) {
      // Ignore errors for pre-filling
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the terms and conditions'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _supabaseService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final applicationData = {
        'user_id': currentUser.id,
        'exhibition_id': widget.exhibition['id'],
        'exhibition_title': widget.exhibition['title'],
        'exhibition_date': widget.exhibition['date'],
        'exhibition_location': widget.exhibition['location'],
        'company_name': _companyNameController.text,
        'full_name': _contactPersonController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'website': _websiteController.text,
        'stall_type': _selectedStallType,
        'notes': _notesController.text,
        'status': 'Pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      // Add selected stall data if available
      if (widget.selectedStall != null) {
        applicationData['stall_id'] = widget.selectedStall!['id']?.toString() ?? '';
        applicationData['stall_instance_id'] = widget.selectedStall!['instance_id']?.toString() ?? '';
        applicationData['stall_size'] = '${widget.selectedStall!['length']} × ${widget.selectedStall!['width']} m';
        applicationData['stall_price'] = widget.selectedStall!['instance_price']?.toString() ?? '';
        applicationData['stall_location'] = 'Position: (${widget.selectedStall!['position_x']}, ${widget.selectedStall!['position_y']})';
        applicationData['stall_type'] = _selectedStallType.isNotEmpty ? _selectedStallType : '${widget.selectedStall!['length']}m × ${widget.selectedStall!['width']}m Stall';
      }

      // Create message from notes only (description field removed)
      final message = _notesController.text.isNotEmpty 
          ? 'Additional Notes: ${_notesController.text}'
          : 'No additional notes provided';

      // Ensure we have valid UUIDs before proceeding
      final stallId = widget.selectedStall?['id']?.toString();
      final stallInstanceId = widget.selectedStall?['instance_id']?.toString();
      
      if (stallId == null || stallId.isEmpty) {
        throw Exception('Invalid stall ID: stall template ID is missing');
      }
      
      if (stallInstanceId == null || stallInstanceId.isEmpty) {
        throw Exception('Invalid stall instance ID: instance ID is missing');
      }

      await _supabaseService.createStallApplication(
        stallId: stallId,
        exhibitionId: widget.exhibition['id'],
        stallInstanceId: stallInstanceId,
        message: message,
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        // Show success dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: AppTheme.successGreen,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text('Application Submitted'),
              ],
            ),
            content: const Text(
              'Your application has been submitted successfully! You will receive a confirmation email shortly.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Go back to previous screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting application: $e'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundPeach,
        title: Row(
          children: [
            const Icon(
              Icons.assignment,
              color: AppTheme.primaryMaroon,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Application Form',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    widget.exhibition['title'] ?? 'Exhibition',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black.withOpacity(0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Exhibition Info Card
                _buildExhibitionInfoCard(),
                const SizedBox(height: 24),

                // Stall Preview Card (if stall is selected)
                if (widget.selectedStall != null) ...[
                  _buildStallPreviewCard(),
                  const SizedBox(height: 24),
                ],

                // Company Information
                _buildSectionTitle('Company Information'),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _companyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name (Optional)',
                    prefixIcon: Icon(Icons.business),
                  ),
                  // Company name is now optional
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'Please enter company name';
                  //   }
                  //   return null;
                  // },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _contactPersonController,
                  decoration: const InputDecoration(
                    labelText: 'Contact Person *',
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter contact person name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address *',
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email address';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    prefixIcon: Icon(Icons.phone),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _websiteController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Website (Optional)',
                    prefixIcon: Icon(Icons.language),
                  ),
                ),
                const SizedBox(height: 24),

                // Stall Requirements - Already selected, no need to repeat
                // _buildSectionTitle('Stall Requirements'),
                // const SizedBox(height: 16),
                // 
                // DropdownButtonFormField<String>(
                //   value: _selectedStallType.isEmpty ? null : _selectedStallType,
                //   decoration: const InputDecoration(
                //     labelText: 'Preferred Stall Type *',
                //     prefixIcon: Icon(Icons.grid_on),
                //   ),
                //   items: _dynamicStallTypes.map((String value) {
                //     return DropdownMenuItem<String>(
                //       value: value,
                //       child: Text(value),
                //     );
                //   }).toList(),
                //   onChanged: (String? newValue) {
                //     setState(() {
                //       _selectedStallType = newValue ?? '';
                //     });
                //   },
                //   validator: (value) {
                //     if (value == null || value.isEmpty) {
                //       return 'Please select a stall type';
                //     }
                //     return null;
                //   },
                // ),
                // const SizedBox(height: 16),


                const SizedBox(height: 24),

                // Additional Information - Only Notes
                _buildSectionTitle('Additional Notes'),
                const SizedBox(height: 16),

                // Company Description field removed as requested
                // TextFormField(
                //   controller: _descriptionController,
                //   maxLines: 4,
                //   decoration: const InputDecoration(
                //     labelText: 'Company Description & Requirements',
                //     prefixIcon: Icon(Icons.description),
                //     alignLabelWithHint: true,
                //   ),
                // ),
                // const SizedBox(height: 16),

                // Optional Notes Field
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Additional Notes (Optional)',
                    prefixIcon: Icon(Icons.note_add),
                    alignLabelWithHint: true,
                    hintText: 'Any additional information or special requests...',
                  ),
                ),
                const SizedBox(height: 24),

                // Terms and Conditions
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Checkbox(
                        value: _acceptTerms,
                        onChanged: (value) {
                          setState(() {
                            _acceptTerms = value ?? false;
                          });
                        },
                        activeColor: AppTheme.primaryMaroon,
                      ),
                    ),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.7),
                            fontSize: 14,
                          ),
                          children: [
                            const TextSpan(text: 'I agree to the '),
                            TextSpan(
                              text: 'Terms of Service',
                              style: const TextStyle(
                                color: AppTheme.primaryMaroon,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const TextSpan(text: ' and '),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: const TextStyle(
                                color: AppTheme.primaryMaroon,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitApplication,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryMaroon,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Send Application',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStallPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPeach,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppTheme.primaryMaroon.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryMaroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.grid_on,
                  color: AppTheme.primaryMaroon,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Stall',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.selectedStall!['length']}m × ${widget.selectedStall!['width']}m Stall',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.primaryMaroon,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stall Type',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.selectedStall!['length']}m × ${widget.selectedStall!['width']}m',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Position',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '(${widget.selectedStall!['position_x']}, ${widget.selectedStall!['position_y']})',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryMaroon.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppTheme.primaryMaroon.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.attach_money,
                  color: AppTheme.primaryMaroon,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Price: ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
                Text(
                  '₹${widget.selectedStall!['instance_price']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryMaroon,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExhibitionInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundPeach,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderLightGray,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.black.withOpacity(0.05),
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
                  color: AppTheme.primaryMaroon.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.event,
                  color: AppTheme.primaryMaroon,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.exhibition['title'] ?? 'Exhibition Title',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.exhibition['date'] ?? 'Date TBD',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 16,
                color: Colors.black.withOpacity(0.7),
              ),
              const SizedBox(width: 4),
              Text(
                widget.exhibition['location'] ?? 'Location TBD',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black.withOpacity(0.7),
                ),
              ),
              const Spacer(),
              Text(
                widget.exhibition['price_range'] ?? 'Price TBD',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryMaroon,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }
}
