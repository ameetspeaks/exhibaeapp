import 'package:flutter/material.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';
import 'whatsapp_otp_verification_screen.dart';

class ImprovedSignupFlowScreen extends StatefulWidget {
  const ImprovedSignupFlowScreen({super.key});

  @override
  State<ImprovedSignupFlowScreen> createState() => _ImprovedSignupFlowScreenState();
}

class _ImprovedSignupFlowScreenState extends State<ImprovedSignupFlowScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  
  String _selectedCountryCode = '+91'; // Default to India (+91)
  bool _isLoading = false;
  bool _isCheckingUser = false;
  
  // Flow state management
  bool _phoneVerified = false;
  bool _isReturningUser = false;
  String? _verifiedPhoneNumber;
  String? _tempUserId; // For storing temporary user ID during signup process
  
  final SupabaseService _supabaseService = SupabaseService.instance;



  @override
  void initState() {
    super.initState();
    _checkForIncompleteSignup();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Check if user has incomplete signup process
  Future<void> _checkForIncompleteSignup() async {
    try {
      // Check if there's a temporary user session or incomplete signup
      final currentUser = _supabaseService.client.auth.currentUser;
      if (currentUser != null) {
        // Check if user profile is complete
        final profile = await _supabaseService.getCurrentUserProfile();
        if (profile != null && profile['full_name'] != null && profile['role'] != null) {
          // Profile is complete, navigate to dashboard
          Navigator.pushReplacementNamed(context, '/home');
          return;
        } else {
          // Incomplete profile, continue signup
          _tempUserId = currentUser.id;
          setState(() {
            _phoneVerified = true;
            _verifiedPhoneNumber = profile?['phone'];
            if (_verifiedPhoneNumber != null) {
              _phoneController.text = _verifiedPhoneNumber!.replaceFirst('+91', '');
            }
          });
        }
      }
    } catch (e) {
      print('Error checking incomplete signup: $e');
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
      final fullPhoneNumber = '$_selectedCountryCode${_phoneController.text.trim()}';
      final formattedPhone = await _formatPhoneNumber(fullPhoneNumber);
      
      // Check if user exists with this phone number
      final existingUser = await _supabaseService.findUserByPhone(formattedPhone);
      
      if (existingUser != null && existingUser['phone_verified'] == true) {
        // Returning user - send login OTP
        setState(() {
          _isReturningUser = true;
          _isLoading = false;
        });
        
        final otpResult = await _supabaseService.sendWhatsAppOtp(
          phoneNumber: formattedPhone,
          verificationType: 'whatsapp_login',
        );
        
        if (mounted && otpResult['success']) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WhatsAppOtpVerificationScreen(
                phoneNumber: formattedPhone,
                verificationType: 'whatsapp_login',
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(otpResult['message'] ?? 'Failed to send OTP'),
              backgroundColor: AppTheme.errorRed,
            ),
          );
        }
      } else {
        // New user - send registration OTP
        setState(() {
          _isReturningUser = false;
          _isLoading = false;
        });
        
        final otpResult = await _supabaseService.sendWhatsAppOtp(
          phoneNumber: formattedPhone,
          verificationType: 'registration',
        );
        
        if (mounted && otpResult['success']) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WhatsAppOtpVerificationScreen(
                phoneNumber: formattedPhone,
                verificationType: 'registration',
              ),
            ),
          ).then((verified) {
            if (verified == true) {
              setState(() {
                _phoneVerified = true;
                _verifiedPhoneNumber = formattedPhone;
              });
            }
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(otpResult['message'] ?? 'Failed to send OTP'),
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

  Future<void> _handleCreateAccount() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full name'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    print('Starting account creation process...');
    print('Phone verified: $_phoneVerified');
    print('Verified phone number: $_verifiedPhoneNumber');
    print('Temp user ID: $_tempUserId');
    print('Full name: ${_nameController.text.trim()}');
    print('Default role: shopper');

    setState(() {
      _isLoading = true;
    });

    try {
      if (_phoneVerified && _verifiedPhoneNumber != null) {
        // Create user account with verified phone
        final response = await _supabaseService.createWhatsAppUser(
          phoneNumber: _verifiedPhoneNumber!,
          userData: {
            'full_name': _nameController.text.trim(),
            'role': 'shopper', // Default role - can be changed later in profile
            'phone_verified': true,
            'whatsapp_enabled': true,
            'auth_provider': 'whatsapp',
          },
        );
        
        print('Account creation response - User: ${response.user?.id}, Session: ${response.session != null}');

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (response.user != null) {
            print('Account created successfully');
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created successfully!'),
                backgroundColor: AppTheme.successGreen,
              ),
            );
            
            // Navigate to home screen
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/home',
              (route) => false,
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to create account. Please try again.'),
                backgroundColor: AppTheme.errorRed,
              ),
            );
          }
        }
      } else {
        // Phone not verified yet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please verify your phone number first'),
            backgroundColor: AppTheme.errorRed,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error creating account: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        String errorMessage = 'Error creating account. Please try again.';
        
        // Handle specific error cases
        if (e.toString().contains('phone_provider_disabled')) {
          errorMessage = 'Phone signup is currently disabled. Please contact support.';
        } else if (e.toString().contains('User already registered')) {
          errorMessage = 'An account with this phone number already exists. Please try logging in instead.';
        } else if (e.toString().contains('Invalid email')) {
          errorMessage = 'Invalid phone number format. Please check and try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<String> _formatPhoneNumber(String phoneNumber) async {
    try {
      final parsed = PhoneNumber.parse(phoneNumber);
      return parsed.international;
    } catch (e) {
      print('Error formatting phone number: $e');
      return phoneNumber;
    }
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }
    if (value.length < 10) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your full name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    return null;
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppTheme.backgroundPeach,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with Logo
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppTheme.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.white.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/images/exhibae-icon.png',
                              height: 100,
                              width: 100,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading logo: $error');
                                return const Icon(
                                  Icons.event,
                                  color: AppTheme.gradientBlack,
                                  size: 60,
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Text(
                          _phoneVerified ? 'Complete Your Profile' : 'Create Account',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  if (!_phoneVerified) ...[
                    // Phone Number Section
                    Text(
                      'PHONE NUMBER',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundPeach.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.borderLightGray,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Country Code Dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.borderLightGray),
                            ),
                            child: DropdownButton<String>(
                              value: _selectedCountryCode,
                              underline: Container(),
                              items: [
                                DropdownMenuItem(value: '+91', child: Text('🇮🇳 +91')),
                                DropdownMenuItem(value: '+1', child: Text('🇺🇸 +1')),
                                DropdownMenuItem(value: '+44', child: Text('🇬🇧 +44')),
                                DropdownMenuItem(value: '+61', child: Text('🇦🇺 +61')),
                                DropdownMenuItem(value: '+86', child: Text('🇨🇳 +86')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedCountryCode = value!;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Phone Number Input
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: TextStyle(color: Colors.black),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.white,
                                hintText: 'Enter 10-digit number',
                                hintStyle: TextStyle(
                                  color: Colors.black.withOpacity(0.5),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              validator: _validatePhone,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Verify Phone Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handlePhoneVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: AppTheme.borderLightGray,
                            ),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.message, size: 20, color: Colors.black),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Verify with WhatsApp',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ] else ...[
                    // Profile Completion Section
                    Text(
                      'FULL NAME',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.backgroundPeach.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.borderLightGray,
                        ),
                      ),
                      child: TextFormField(
                        controller: _nameController,
                        style: TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          hintText: 'Enter your full name',
                          hintStyle: TextStyle(
                            color: Colors.black.withOpacity(0.5),
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        validator: _validateName,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Create Account Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleCreateAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryMaroon,
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
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Back to Login
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Already have an account? Sign In',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black.withOpacity(0.8),
                          decoration: TextDecoration.underline,
                        ),
                      ),
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
}
