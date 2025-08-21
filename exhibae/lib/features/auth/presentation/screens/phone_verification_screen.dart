import 'package:flutter/material.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import 'whatsapp_otp_verification_screen.dart';

class PhoneVerificationScreen extends StatefulWidget {
  const PhoneVerificationScreen({super.key});

  @override
  State<PhoneVerificationScreen> createState() => _PhoneVerificationScreenState();
}

class _PhoneVerificationScreenState extends State<PhoneVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _phoneFocusNode = FocusNode();
  
  bool _isLoading = false;
  bool _isCheckingWhatsApp = false;
  bool _isWhatsAppAvailable = false;
  Map<String, dynamic>? _phoneStatus;

  final SupabaseService _supabaseService = SupabaseService.instance;

  @override
  void initState() {
    super.initState();
    _loadPhoneStatus();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadPhoneStatus() async {
    try {
      final status = await _supabaseService.getPhoneVerificationStatus();
      setState(() {
        _phoneStatus = status;
        if (status['phone'] != null) {
          _phoneController.text = status['phone'];
        }
      });
    } catch (e) {
      print('Error loading phone status: $e');
    }
  }

  Future<void> _checkWhatsAppAvailability() async {
    if (_phoneController.text.isEmpty) return;

    setState(() {
      _isCheckingWhatsApp = true;
    });

    try {
      final isAvailable = await _supabaseService.isWhatsAppAvailable(_phoneController.text);
      
      if (mounted) {
        setState(() {
          _isWhatsAppAvailable = isAvailable;
          _isCheckingWhatsApp = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingWhatsApp = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking WhatsApp availability: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _handlePhoneVerification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final formattedPhone = await _formatPhoneNumber(_phoneController.text);
      
      // Send WhatsApp OTP for phone verification
      final otpResult = await _supabaseService.sendWhatsAppOtp(
        phoneNumber: formattedPhone,
        verificationType: 'phone_update',
      );
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (otpResult['success']) {
          // Navigate to OTP verification screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WhatsAppOtpVerificationScreen(
                phoneNumber: formattedPhone,
                verificationType: 'phone_update',
              ),
            ),
          ).then((verified) {
            if (verified == true) {
              // Phone verified successfully
              _loadPhoneStatus(); // Refresh status
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phone number verified successfully!'),
                  backgroundColor: Color(0xFF25D366),
                ),
              );
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(otpResult['message']),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<String> _formatPhoneNumber(String phoneNumber) async {
    try {
      final parsed = PhoneNumber.parse(phoneNumber);
      return parsed.international ?? phoneNumber;
    } catch (e) {
      return phoneNumber;
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    
    // Basic phone number validation
    final phoneRegex = RegExp(r'^\+?[1-9]\d{1,14}$');
    if (!phoneRegex.hasMatch(value.replaceAll(RegExp(r'[\s\-\(\)]'), ''))) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isPhoneVerified = _phoneStatus?['phone_verified'] ?? false;
    final currentPhone = _phoneStatus?['phone'];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Phone Verification',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.gradientBlack,
              AppTheme.gradientPink,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // WhatsApp Icon and Title
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF25D366),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF25D366).withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.whatsapp,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Phone Verification',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isPhoneVerified 
                              ? 'Your phone number is verified for WhatsApp login'
                              : 'Add your phone number to enable WhatsApp login',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Current Status
                  if (isPhoneVerified && currentPhone != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF25D366),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Color(0xFF25D366),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Phone Verified',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF25D366),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Phone: $currentPhone',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'You can now login with WhatsApp',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!isPhoneVerified) ...[
                    // Phone Number Input
                    Text(
                      'Phone Number:',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _phoneController,
                      focusNode: _phoneFocusNode,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '+1 (555) 123-4567',
                        prefixIcon: const Icon(Icons.phone, color: Colors.black),
                        suffixIcon: _isCheckingWhatsApp
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                ),
                              )
                            : _isWhatsAppAvailable
                                ? const Icon(Icons.check_circle, color: Color(0xFF25D366))
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.black),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppTheme.primaryMaroon, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                      ),
                      validator: _validatePhone,
                      onChanged: (value) {
                        if (value.length > 10) {
                          _checkWhatsAppAvailability();
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    if (_isWhatsAppAvailable)
                      Row(
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF25D366), size: 16),
                          const SizedBox(width: 8),
                          Text(
                            'WhatsApp is available for this number',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF25D366),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 32),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: (_isLoading || !_isWhatsAppAvailable) ? null : _handlePhoneVerification,
                        style: TextButton.styleFrom(
                          backgroundColor: _isWhatsAppAvailable 
                              ? const Color(0xFF25D366) 
                              : Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
                                'Verify Phone Number',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Benefits Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Benefits of Phone Verification:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildBenefitItem(
                          icon: Icons.whatsapp,
                          title: 'WhatsApp Login',
                          description: 'Login quickly with WhatsApp OTP',
                        ),
                        _buildBenefitItem(
                          icon: Icons.security,
                          title: 'Enhanced Security',
                          description: 'Two-factor authentication via WhatsApp',
                        ),
                        _buildBenefitItem(
                          icon: Icons.notifications,
                          title: 'Important Updates',
                          description: 'Receive important notifications via WhatsApp',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF25D366),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
