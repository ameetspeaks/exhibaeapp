import 'package:flutter/material.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/profile_picture_widget.dart';
import '../../../../core/widgets/company_logo_widget.dart';

class OrganizerEditProfileScreen extends StatefulWidget {
  const OrganizerEditProfileScreen({super.key});

  @override
  State<OrganizerEditProfileScreen> createState() => _OrganizerEditProfileScreenState();
}

class _OrganizerEditProfileScreenState extends State<OrganizerEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabaseService = SupabaseService.instance;
  
  // Form controllers
  final _fullNameController = TextEditingController();
  final _companyNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteUrlController = TextEditingController();
  final _facebookUrlController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSaving = false;
  Map<String, dynamic>? _profile;
  String? _currentAvatarUrl;
  String? _currentLogoUrl;
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  
  @override
  void dispose() {
    _fullNameController.dispose();
    _companyNameController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _websiteUrlController.dispose();
    _facebookUrlController.dispose();
    super.dispose();
  }
  
  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final user = _supabaseService.currentUser;
      if (user != null) {
        final profile = await _supabaseService.getUserProfile(user.id);
        if (profile != null) {
          setState(() {
            _profile = profile;
            _currentAvatarUrl = profile['avatar_url'];
            _currentLogoUrl = profile['company_logo_url'];
            _fullNameController.text = profile['full_name'] ?? '';
            _companyNameController.text = profile['company_name'] ?? '';
            _phoneController.text = profile['phone'] ?? '';
            _descriptionController.text = profile['description'] ?? '';
            _websiteUrlController.text = profile['website_url'] ?? '';
            _facebookUrlController.text = profile['facebook_url'] ?? '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _onAvatarChanged(String? newAvatarUrl) {
    setState(() {
      _currentAvatarUrl = newAvatarUrl;
    });
  }

  void _onAvatarDeleted() {
    setState(() {
      _currentAvatarUrl = null;
    });
  }

  void _onLogoChanged(String? newLogoUrl) {
    setState(() {
      _currentLogoUrl = newLogoUrl;
    });
  }

  void _onLogoDeleted() {
    setState(() {
      _currentLogoUrl = null;
    });
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final user = _supabaseService.currentUser;
      if (user != null) {
        final updates = {
          'full_name': _fullNameController.text.trim(),
          'company_name': _companyNameController.text.trim(),
          'phone': _phoneController.text.trim(),
          'description': _descriptionController.text.trim(),
          'website_url': _websiteUrlController.text.trim(),
          'facebook_url': _facebookUrlController.text.trim(),
        };
        
        await _supabaseService.updateUserProfile(user.id, updates);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Picture and Company Logo Section
                    Center(
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : Column(
                              children: [
                                // Profile Picture
                                const Text(
                                  'Profile Picture',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ProfilePictureWidget(
                                  userId: _supabaseService.currentUser?.id ?? '',
                                  currentAvatarUrl: _currentAvatarUrl,
                                  size: 100,
                                  showEditButton: true,
                                  showDeleteButton: true,
                                  onAvatarChanged: _onAvatarChanged,
                                  onAvatarDeleted: _onAvatarDeleted,
                                ),
                                const SizedBox(height: 32),
                                // Company Logo
                                const Text(
                                  'Company Logo',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                CompanyLogoWidget(
                                  userId: _supabaseService.currentUser?.id ?? '',
                                  currentLogoUrl: _currentLogoUrl,
                                  size: 100,
                                  showEditButton: true,
                                  showDeleteButton: true,
                                  onLogoChanged: _onLogoChanged,
                                  onLogoDeleted: _onLogoDeleted,
                                ),
                              ],
                            ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Full Name
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Company Name
                    TextFormField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Company Name',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Phone
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                        alignLabelWithHint: true,
                      ),
                      maxLines: 3,
                      maxLength: 500,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Website URL
                    TextFormField(
                      controller: _websiteUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Website URL',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.language),
                        hintText: 'https://example.com',
                      ),
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final uri = Uri.tryParse(value);
                          if (uri == null || !uri.hasAbsolutePath) {
                            return 'Please enter a valid URL';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Facebook URL
                    TextFormField(
                      controller: _facebookUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Facebook URL',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.facebook),
                        hintText: 'https://facebook.com/username',
                      ),
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final uri = Uri.tryParse(value);
                          if (uri == null || !uri.hasAbsolutePath) {
                            return 'Please enter a valid URL';
                          }
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
