import 'package:flutter/material.dart';
import 'exhibition_form_model.dart';
import '../../../../core/services/supabase_service.dart';

enum ExhibitionFormStep {
  basicDetails, // Includes both basic info and location
  stallLayout,  // Stalls configuration
  gallery,      // Gallery images
  review,       // Review and submit for approval
}

class ExhibitionFormState extends ChangeNotifier {
  ExhibitionFormModel _formData = ExhibitionFormModel();
  ExhibitionFormStep _currentStep = ExhibitionFormStep.basicDetails;
  bool _isLoading = false;
  String? _error;
  bool _isEditing = false;

  ExhibitionFormModel get formData => _formData;
  ExhibitionFormStep get currentStep => _currentStep;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEditing => _isEditing;

  void init({Map<String, dynamic>? existingData}) {
    if (existingData != null) {
      _formData = ExhibitionFormModel.fromJson(existingData);
      _isEditing = true;
      // Load existing stalls data if we have an exhibition ID
      if (_formData.id != null) {
        _loadExistingStalls();
      }
    } else {
      _formData = ExhibitionFormModel();
      _isEditing = false;
    }
    _currentStep = ExhibitionFormStep.basicDetails;
    _error = null;
    notifyListeners();
  }

  void setStep(ExhibitionFormStep step) {
    _currentStep = step;
    notifyListeners();
  }

  void nextStep() {
    final values = ExhibitionFormStep.values;
    final currentIndex = values.indexOf(_currentStep);
    if (currentIndex < values.length - 1) {
      _currentStep = values[currentIndex + 1];
      notifyListeners();
    }
  }

  void previousStep() {
    final values = ExhibitionFormStep.values;
    final currentIndex = values.indexOf(_currentStep);
    if (currentIndex > 0) {
      _currentStep = values[currentIndex - 1];
      notifyListeners();
    }
  }

  void updateBasicInfo({
    String? title,
    String? description,
    String? categoryId,
    String? eventTypeId,
    DateTime? startDate,
    DateTime? endDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    DateTime? applicationDeadline,
  }) {
    if (title != null) _formData.title = title;
    if (description != null) _formData.description = description;
    if (categoryId != null) _formData.categoryId = categoryId;
    if (eventTypeId != null) _formData.eventTypeId = eventTypeId;
    if (startDate != null) _formData.startDate = startDate;
    if (endDate != null) _formData.endDate = endDate;
    if (startTime != null) _formData.startTime = startTime;
    if (endTime != null) _formData.endTime = endTime;
    if (applicationDeadline != null) _formData.applicationDeadline = applicationDeadline;
    notifyListeners();
  }

  void updateLocation({
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? venueTypeId,
    double? latitude,
    double? longitude,
  }) {
    if (address != null) _formData.address = address;
    if (city != null) _formData.city = city;
    if (state != null) _formData.state = state;
    if (country != null) _formData.country = country;
    if (postalCode != null) _formData.postalCode = postalCode;
    if (venueTypeId != null) _formData.venueTypeId = venueTypeId;
    if (latitude != null) _formData.latitude = latitude;
    if (longitude != null) _formData.longitude = longitude;
    notifyListeners();
  }

  void updateGallery(List<Map<String, dynamic>> galleryImages) {
    print('DEBUG: updateGallery called with ${galleryImages.length} images');
    print('DEBUG: Previous gallery images count: ${_formData.galleryImages.length}');
    _formData.galleryImages = galleryImages;
    print('DEBUG: Updated gallery images count: ${_formData.galleryImages.length}');
    notifyListeners();
  }

  void updateStalls(List<Map<String, dynamic>> stalls) {
    _formData.stalls = stalls;
    notifyListeners();
  }

  void updateAmenities(List<String> amenities) {
    _formData.selectedAmenities = amenities;
    notifyListeners();
  }

  void updateMedia({
    List<String>? images,
    String? floorPlan,
  }) {
    if (images != null) _formData.images = images;
    if (floorPlan != null) _formData.floorPlan = floorPlan;
    notifyListeners();
  }

  void updateGalleryImages(List<Map<String, dynamic>> galleryImages) {
    _formData.galleryImages = galleryImages;
    notifyListeners();
  }

  void updatePricing({
    double? stallStartingPrice,
  }) {
    if (stallStartingPrice != null) _formData.stallStartingPrice = stallStartingPrice;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  // Submit exhibition for approval
  Future<bool> submitForApproval() async {
    try {
      setLoading(true);
      setError(null);
      
      final supabaseService = SupabaseService.instance;
      
      // Update exhibition status to draft (but will be shown as "pending for approval" to users)
      if (_formData.id != null) {
        final result = await supabaseService.client
            .from('exhibitions')
            .update({
              'status': 'draft',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', _formData.id!)
            .select();
        
        if (result.isNotEmpty) {
          // Update local form data
          _formData.status = 'draft';
          notifyListeners();
        } else {
          throw Exception('Failed to update exhibition status');
        }
      } else {
        throw Exception('Exhibition ID not found. Please save the exhibition first.');
      }
      
      setLoading(false);
      return true;
    } catch (e) {
      setError('Failed to submit for approval: $e');
      setLoading(false);
      return false;
    }
  }

  // Save current step to database
  Future<bool> saveCurrentStep() async {
    try {
      setLoading(true);
      setError(null);
      
      final supabaseService = SupabaseService.instance;
      
             switch (_currentStep) {
         case ExhibitionFormStep.basicDetails:
           return await _saveBasicDetails(supabaseService);
         case ExhibitionFormStep.stallLayout:
           return await _saveStallLayout(supabaseService);
         case ExhibitionFormStep.gallery:
           return await _saveGallery(supabaseService);
         case ExhibitionFormStep.review:
           return true; // Review step doesn't save, it just shows the review
       }
    } catch (e) {
      setError('Failed to save step: $e');
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> _saveBasicDetails(SupabaseService supabaseService) async {
    try {
      // Get current user ID for organizer
      final currentUser = supabaseService.currentUser;
      if (currentUser == null) {
        setError('User not authenticated. Please log in again.');
        return false;
      }

      // For now, let's assume the user is an organizer and proceed
      // The RLS policies should handle the security
      print('Current user ID: ${currentUser.id}');
      print('Current user email: ${currentUser.email}');
      
      // Try to get or create profile, but don't fail if it doesn't work
      try {
        final profileResponse = await supabaseService.client
            .from('profiles')
            .select('role')
            .eq('id', currentUser.id)
            .single();
        
        print('User profile found: ${profileResponse['role']}');
        
                 if (profileResponse['role'] != 'organiser') {
           // Try to update, but don't fail if it doesn't work
           try {
             await supabaseService.client
                 .from('profiles')
                 .update({
                   'role': 'organiser',
                   'updated_at': DateTime.now().toIso8601String(),
                 })
                 .eq('id', currentUser.id);
             print('Updated user role to organiser');
           } catch (updateError) {
             print('Warning: Could not update user role: $updateError');
             // Continue anyway - the user might still be able to create exhibitions
           }
         }
      } catch (e) {
        print('Profile not found, attempting to create: $e');
        // Try to create profile, but don't fail if it doesn't work
        try {
                     await supabaseService.client
               .from('profiles')
               .insert({
                 'id': currentUser.id,
                 'email': currentUser.email,
                 'role': 'organiser',
                 'created_at': DateTime.now().toIso8601String(),
                 'updated_at': DateTime.now().toIso8601String(),
               });
           print('Created new user profile with organiser role');
        } catch (profileError) {
          print('Warning: Could not create user profile: $profileError');
          // Continue anyway - the user might still be able to create exhibitions
        }
      }

      // Create or update exhibition with basic details and location
      final exhibitionData = {
        'title': _formData.title,
        'description': _formData.description,
        'category_id': _formData.categoryId,
        'event_type_id': _formData.eventTypeId,
        'start_date': _formData.startDate?.toIso8601String(),
        'end_date': _formData.endDate?.toIso8601String(),
        'start_time': _formData.startTime != null ? '${_formData.startTime!.hour.toString().padLeft(2, '0')}:${_formData.startTime!.minute.toString().padLeft(2, '0')}' : null,
        'end_time': _formData.endTime != null ? '${_formData.endTime!.hour.toString().padLeft(2, '0')}:${_formData.endTime!.minute.toString().padLeft(2, '0')}' : null,
        'application_deadline': _formData.applicationDeadline?.toIso8601String(),
        'address': _formData.address,
        'city': _formData.city,
        'state': _formData.state,
        'country': _formData.country,
        'postal_code': _formData.postalCode,
        'venue_type_id': _formData.venueTypeId,
        'latitude': _formData.latitude,
        'longitude': _formData.longitude,
        'organiser_id': currentUser.id, // Add organizer ID for RLS
        'status': 'draft', // Always draft until completed
      };

      if (_isEditing && _formData.id != null) {
        // Update existing exhibition
        await supabaseService.client
            .from('exhibitions')
            .update(exhibitionData)
            .eq('id', _formData.id!);
      } else {
        // Create new exhibition
        final response = await supabaseService.client
            .from('exhibitions')
            .insert(exhibitionData)
            .select()
            .single();
        _formData.id = response['id'];
        _isEditing = true;
      }
      
      return true;
    } catch (e) {
      setError('Failed to save basic details: $e');
      return false;
    }
  }

  Future<bool> _saveStallLayout(SupabaseService supabaseService) async {
    try {
      if (_formData.id == null) {
        setError('Exhibition ID not found. Please save basic details first.');
        return false;
      }

      // If we're editing and there are existing stalls, don't recreate them
      if (_isEditing) {
        // Just update the exhibition status to indicate we've been through the stall layout step
        await supabaseService.client
            .from('exhibitions')
            .update({'status': 'draft'})
            .eq('id', _formData.id!);
        return true;
      }

      // Save stalls and their instances (only for new exhibitions)
      if (_formData.stalls.isNotEmpty) {
        for (final stall in _formData.stalls) {
          final stallAmenities = stall.remove('amenities') as List<dynamic>? ?? [];
          
          // Create the stall
          final stallResponse = await supabaseService.client
              .from('stalls')
              .insert({
                ...stall,
                'exhibition_id': _formData.id!,
              })
              .select()
              .single();
          
          final stallId = stallResponse['id'] as String;
          
          // Create stall instances based on quantity
          final quantity = stall['quantity'] as int? ?? 1;
          final List<Map<String, dynamic>> stallInstances = [];
          for (int i = 0; i < quantity; i++) {
            stallInstances.add({
              'stall_id': stallId,
              'exhibition_id': _formData.id!,
              'instance_number': i + 1,
              'status': 'available',
              'price': stall['price'] ?? 0.0,
              'original_price': stall['price'] ?? 0.0,
            });
          }
          
          // Insert all stall instances
          if (stallInstances.isNotEmpty) {
            await supabaseService.client
                .from('stall_instances')
                .insert(stallInstances);
          }
          
          // Create stall amenities
          if (stallAmenities.isNotEmpty) {
            final amenityData = stallAmenities.map((amenityId) => {
              'stall_id': stallId,
              'amenity_id': amenityId,
            }).toList();
            
            await supabaseService.client
                .from('stall_amenities')
                .insert(amenityData);
          }
        }
        
        // If stalls were added, update exhibition status to 'ready_for_review' or keep as 'draft'
        // For now, keep as 'draft' until gallery is completed
        await supabaseService.client
            .from('exhibitions')
            .update({'status': 'draft'})
            .eq('id', _formData.id!);
      } else {
        // No stalls added - keep exhibition as draft
        await supabaseService.client
            .from('exhibitions')
            .update({'status': 'draft'})
            .eq('id', _formData.id!);
      }
      
      return true;
    } catch (e) {
      setError('Failed to save stall layout: $e');
      return false;
    }
  }

  Future<bool> _saveGallery(SupabaseService supabaseService) async {
    try {
      if (_formData.id == null) {
        setError('Exhibition ID not found. Please save basic details first.');
        return false;
      }

      // Save gallery images
      if (_formData.galleryImages.isNotEmpty) {
        for (final image in _formData.galleryImages) {
          // Check if this image already exists in the database
          final existingImages = await supabaseService.client
              .from('gallery_images')
              .select('id')
              .eq('exhibition_id', _formData.id!)
              .eq('image_url', image['image_url'])
              .eq('image_type', image['image_type']);

          // Only insert if the image doesn't already exist
          if (existingImages.isEmpty) {
            final galleryImageData = {
              'exhibition_id': _formData.id!,
              'image_url': image['image_url'],
              'image_type': image['image_type'],
            };

            await supabaseService.client
                .from('gallery_images')
                .insert(galleryImageData);
          }
        }
      }

      // Update exhibition status based on whether stalls are present
      String finalStatus;
      
      // Check if there are existing stalls in the database
      final existingStalls = await supabaseService.client
          .from('stalls')
          .select('id')
          .eq('exhibition_id', _formData.id!);
      
      if (_formData.stalls.isNotEmpty || existingStalls.isNotEmpty) {
        finalStatus = 'published'; // Exhibition is complete with stalls
      } else {
        finalStatus = 'draft'; // Exhibition is complete but has no stalls (draft)
      }
      
      await supabaseService.client
          .from('exhibitions')
          .update({'status': finalStatus})
          .eq('id', _formData.id!);
      
      return true;
    } catch (e) {
      setError('Failed to save gallery: $e');
      return false;
    }
  }



     bool canProceed() {
     switch (_currentStep) {
       case ExhibitionFormStep.basicDetails:
         return _formData.title.isNotEmpty &&
                _formData.description.isNotEmpty &&
                _formData.startDate != null &&
                _formData.endDate != null &&
                _formData.address.isNotEmpty &&
                _formData.state.isNotEmpty &&
                _formData.city.isNotEmpty &&
                _formData.country.isNotEmpty;
       case ExhibitionFormStep.stallLayout:
         return true; // Allow proceeding even without stalls (exhibition will be draft)
       case ExhibitionFormStep.gallery:
         return true; // Gallery is optional
       case ExhibitionFormStep.review:
         return _formData.isValid; // Must be valid to submit for approval
     }
   }

  void reset() {
    _formData = ExhibitionFormModel();
    _currentStep = ExhibitionFormStep.basicDetails;
    _isLoading = false;
    _error = null;
    _isEditing = false;
    notifyListeners();
  }

  // Load existing gallery images from database
  Future<void> loadGalleryImages(SupabaseService supabaseService) async {
    try {
      if (_formData.id == null) return;

      final response = await supabaseService.client
          .from('gallery_images')
          .select('image_url, image_type, created_at')
          .eq('exhibition_id', _formData.id!)
          .order('created_at');

      if (response != null) {
        _formData.galleryImages = List<Map<String, dynamic>>.from(response);
        notifyListeners();
      }
    } catch (e) {
      print('Error loading gallery images: $e');
      // Don't set error here as gallery images are optional
    }
  }

  // Load existing stalls from database
  Future<void> _loadExistingStalls() async {
    try {
      if (_formData.id == null) return;

      final supabaseService = SupabaseService.instance;
      final stallsWithInstances = await supabaseService.getStallsByExhibition(_formData.id!);
      
      if (stallsWithInstances.isNotEmpty) {
        // Convert stalls data to form format
        final stallsForForm = <Map<String, dynamic>>[];
        final stallTypes = <String, Map<String, dynamic>>{};
        
        for (final stall in stallsWithInstances) {
          final stallId = stall['id'] as String;
          if (!stallTypes.containsKey(stallId)) {
            // Create a stall type entry
            stallTypes[stallId] = {
              'id': stall['id'],
              'name': stall['name'],
              'length': stall['length'],
              'width': stall['width'],
              'unit_id': stall['unit_id'],
              'price': stall['price'],
              'quantity': 1, // Will be incremented
              'amenities': stall['amenities'] ?? [],
            };
          } else {
            // Increment quantity for existing stall type
            stallTypes[stallId]!['quantity'] = (stallTypes[stallId]!['quantity'] as int) + 1;
          }
        }
        
        // Convert to list format
        stallsForForm.addAll(stallTypes.values);
        
        // Update form data
        _formData.stalls = stallsForForm;
        notifyListeners();
        print('DEBUG: Loaded ${stallsForForm.length} stall types into form state');
      }
    } catch (e) {
      print('Error loading existing stalls: $e');
      // Don't set error here as stalls are optional
    }
  }
}
