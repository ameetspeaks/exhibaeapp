import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/supabase_service.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String phoneNumber;

  const RoleSelectionScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String? _selectedRole;
  bool _isLoading = false;
  final TextEditingController _fullNameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final SupabaseService _supabaseService = SupabaseService.instance;

  final List<Map<String, dynamic>> _roles = [
    {
      'id': 'shopper',
      'title': 'Shopper',
      'description': 'Browse and purchase products from exhibitions',
      'icon': Icons.shopping_bag,
      'color': const Color(0xFF3B82F6),
    },
    {
      'id': 'brand',
      'title': 'Brand',
      'description': 'Showcase your products and connect with customers',
      'icon': Icons.store,
      'color': const Color(0xFF10B981),
    },
    {
      'id': 'organiser',
      'title': 'Organiser',
      'description': 'Create and manage exhibitions and events',
      'icon': Icons.event,
      'color': const Color(0xFFF59E0B),
    },
  ];

  @override
  void initState() {
    super.initState();
    print('RoleSelectionScreen initialized for phone: ${widget.phoneNumber}');
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  // Header
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
                            Icons.person_add,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Complete Your Profile',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose your role and enter your details',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Role Selection
                  Text(
                    'Select your role:',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Role Cards
                  ..._roles.map((role) => _buildRoleCard(role)).toList(),

                  const SizedBox(height: 32),

                  // Full Name Input
                  Text(
                    'Full Name:',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _fullNameController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter your full name',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 16,
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xFF25D366),
                          width: 2,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.errorRed,
                          width: 2,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppTheme.errorRed,
                          width: 2,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      prefixIcon: const Icon(
                        Icons.person,
                        color: Colors.white,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters long';
                      }
                      if (value.trim().length > 50) {
                        return 'Name must be less than 50 characters';
                      }
                      // Check for valid name format (letters, spaces, hyphens, apostrophes)
                      final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
                      if (!nameRegex.hasMatch(value.trim())) {
                        return 'Please enter a valid name (letters only)';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 32),

                  // Signup Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: !_isLoading ? _signup : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF25D366),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
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
                              'Signup',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Help Text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You can change your role and profile details later in your profile settings',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
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

  Widget _buildRoleCard(Map<String, dynamic> role) {
    final isSelected = _selectedRole == role['id'];
    final color = role['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRole = role['id'];
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.2) : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.white.withOpacity(0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  role['icon'] as IconData,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role['title'] as String,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role['description'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Selection Indicator
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signup() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Additional validation
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role'),
          backgroundColor: AppTheme.errorRed,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Creating account for phone: ${widget.phoneNumber} with role: $_selectedRole');

      // Create temporary email and password
      final tempEmail = '${widget.phoneNumber.replaceAll('+', '').replaceAll('-', '').replaceAll(' ', '')}@exhibae.com';
      final tempPassword = 'whatsapp_${widget.phoneNumber.replaceAll('+', '').replaceAll('-', '').replaceAll(' ', '')}';

      print('Creating user in auth.users with email: $tempEmail');

      // First, create user in auth.users to get the UID
      final signUpResponse = await _supabaseService.client.auth.signUp(
        email: tempEmail,
        password: tempPassword,
                 data: {
           'phone': widget.phoneNumber,
           'auth_provider': 'whatsapp',
           'role': _selectedRole, // This will be 'organiser' from the enum
         },
        emailRedirectTo: null,
      );

      if (signUpResponse.user == null) {
        throw Exception('Failed to create user in auth.users');
      }

      final userId = signUpResponse.user!.id;
      print('User created in auth.users with ID: $userId');

      // Now create/update the profile using the UID
      try {
        // Check if profile already exists
        final existingProfile = await _supabaseService.client
            .from('profiles')
            .select('id')
            .eq('id', userId)
            .maybeSingle();

        if (existingProfile != null) {
          print('Profile already exists, updating...');
          
                     // Update existing profile
           await _supabaseService.client
               .from('profiles')
               .update({
                 'email': tempEmail, // Add the temporary email
                 'role': _selectedRole,
                 'full_name': _fullNameController.text.trim(),
                 'phone': widget.phoneNumber,
                 'phone_verified': true,
                 'phone_verified_at': DateTime.now().toIso8601String(),
                 'whatsapp_enabled': true,
                 'auth_provider': 'whatsapp',
                 'updated_at': DateTime.now().toIso8601String(),
               })
               .eq('id', userId);

          print('Profile updated successfully');
        } else {
          print('Creating new profile...');
          
                     // Create new profile
           await _supabaseService.client
               .from('profiles')
               .insert({
                 'id': userId,
                 'email': tempEmail, // Add the temporary email
                 'role': _selectedRole,
                 'full_name': _fullNameController.text.trim(),
                 'phone': widget.phoneNumber,
                 'phone_verified': true,
                 'phone_verified_at': DateTime.now().toIso8601String(),
                 'whatsapp_enabled': true,
                 'auth_provider': 'whatsapp',
                 'created_at': DateTime.now().toIso8601String(),
                 'updated_at': DateTime.now().toIso8601String(),
               });

          print('Profile created successfully');
        }

                 // Try to sign in the user
         print('Attempting to sign in user with email: $tempEmail');
         final signInResponse = await _supabaseService.client.auth.signInWithPassword(
           email: tempEmail,
           password: tempPassword,
         );
         print('Sign in response - User: ${signInResponse.user?.id}, Session: ${signInResponse.session != null}');

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          if (signInResponse.user != null && signInResponse.session != null) {
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Account created successfully!'),
                backgroundColor: Color(0xFF25D366),
              ),
            );

                         // Navigate to appropriate dashboard based on role
             String dashboardRoute;
             switch (_selectedRole) {
               case 'shopper':
                 dashboardRoute = '/shopper-dashboard';
                 break;
               case 'brand':
                 dashboardRoute = '/home';
                 break;
               case 'organiser':
                 dashboardRoute = '/home';
                 break;
               default:
                 dashboardRoute = '/home';
             }
             
             Navigator.pushNamedAndRemoveUntil(
               context,
               dashboardRoute,
               (route) => false,
             );
                     } else {
             // Try to refresh session or handle the case where user exists but session failed
             print('Session creation failed, trying to refresh session...');
             try {
               await _supabaseService.client.auth.refreshSession();
               print('Session refreshed successfully');
               
               // Show success message and navigate
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(
                   content: Text('Account created successfully!'),
                   backgroundColor: Color(0xFF25D366),
                 ),
               );
               
               // Navigate to appropriate dashboard based on role
               String dashboardRoute;
               switch (_selectedRole) {
                 case 'shopper':
                   dashboardRoute = '/shopper-dashboard';
                   break;
                 case 'brand':
                   dashboardRoute = '/home';
                   break;
                 case 'organiser':
                   dashboardRoute = '/home';
                   break;
                 default:
                   dashboardRoute = '/home';
               }
               
               Navigator.pushNamedAndRemoveUntil(
                 context,
                 dashboardRoute,
                 (route) => false,
               );
             } catch (refreshError) {
               print('Session refresh failed: $refreshError');
               // Show error message
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(
                   content: Text('Account created but sign-in failed. Please try logging in.'),
                   backgroundColor: AppTheme.errorRed,
                 ),
               );
             }
           }
        }

      } catch (profileError) {
        print('Error creating/updating profile: $profileError');
        
        // If profile creation fails, try to delete the auth user
        try {
          await _supabaseService.client.auth.admin.deleteUser(userId);
          print('Cleaned up auth user after profile creation failure');
        } catch (cleanupError) {
          print('Error cleaning up auth user: $cleanupError');
        }
        
        throw profileError;
      }

    } catch (e) {
      print('Error creating account: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show user-friendly error message
        String errorMessage = 'Failed to create account. Please try again.';
        
        if (e.toString().contains('User already registered')) {
          errorMessage = 'An account with this phone number already exists. Please try logging in instead.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection and try again.';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Request timed out. Please try again.';
        } else if (e.toString().contains('invalid input value for enum user_role')) {
          errorMessage = 'Invalid role selected. Please try again.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: AppTheme.errorRed,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    }
  }
}
