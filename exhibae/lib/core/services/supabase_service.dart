import 'dart:typed_data';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._internal();
  
  SupabaseService._internal();

  SupabaseClient get client => Supabase.instance.client;

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
  }

  // Authentication methods
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? userData,
  }) async {
    try {
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );
      
      // Check if the signup was successful
      if (response.user != null) {
        // Check if email confirmation is required
        if (response.user!.emailConfirmedAt == null) {
          // Email confirmation is required - this is expected
          // The email should be sent automatically by Supabase
          // If it's not being sent, it might be a configuration issue in the Supabase dashboard
          // You need to:
          // 1. Go to Supabase Dashboard > Authentication > Settings
          // 2. Enable "Enable email confirmations"
          // 3. Configure an email provider (SendGrid, Mailgun, etc.)
          // 4. Make sure your email provider is properly configured
        } else {
          // Email is already confirmed (this shouldn't happen in normal flow)
        }
        return response;
      } else {
        throw Exception('Signup failed: No user returned');
      }
    } catch (e) {
      // Provide more specific error messages
      if (e.toString().contains('Invalid API key')) {
        throw Exception('Invalid Supabase configuration. Please check your anon key.');
      } else if (e.toString().contains('Email not confirmed')) {
        throw Exception('Email confirmation required. Please check your email.');
      } else if (e.toString().contains('User already registered')) {
        throw Exception('User with this email already exists. Please try logging in instead.');
      } else if (e.toString().contains('Invalid email')) {
        throw Exception('Please enter a valid email address.');
      } else if (e.toString().contains('Password')) {
        throw Exception('Password must be at least 6 characters long.');
      } else {
        rethrow;
      }
    }
  }

  Future<AuthResponse> signInWithPhone({
    required String phone,
    required String otp,
    required String role,
  }) async {
    final response = await client.auth.verifyOTP(
      phone: phone,
      token: otp,
      type: OtpType.sms,
    );

    // Sync role from profiles table to metadata if needed
    if (response.user != null) {
      await _syncUserRole(response.user!);
      
      // Update user metadata with role
      await client.auth.updateUser(
        UserAttributes(
          data: {
            'role': role,
          },
        ),
      );
    }

    return response;
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    // Sync role from profiles table to metadata if needed
    if (response.user != null) {
      await _syncUserRole(response.user!);
      
      // Update user metadata with role
      await client.auth.updateUser(
        UserAttributes(
          data: {
            'role': role,
          },
        ),
      );
    }

    return response;
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  Future<AuthResponse> verifyOtp({
    required String email,
    required String token,
  }) async {
    return await client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );
  }

  Future<void> resendOtp(String email) async {
    await client.auth.resend(
      email: email,
      type: OtpType.signup,
    );
  }

  User? get currentUser => client.auth.currentUser;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // Exhibition methods
  Future<List<Map<String, dynamic>>> getExhibitions() async {
    final response = await client
        .from('exhibitions')
        .select('''
          *,
          category:exhibition_categories(*),
          venue_type:venue_types(*),
          event_type:event_types(*),
          measurement_unit:measurement_units(*),
          organiser:profiles(*)
        ''')
        .eq('status', 'published')
        .gte('end_date', DateTime.now().toIso8601String())
        .order('start_date', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Get all exhibitions for a specific organizer (regardless of status)
  Future<List<Map<String, dynamic>>> getOrganizerExhibitions(String organizerId) async {
    final response = await client
        .from('exhibitions')
        .select('''
          *,
          category:exhibition_categories(*),
          venue_type:venue_types(*),
          event_type:event_types(*),
          measurement_unit:measurement_units(*),
          organiser:profiles(*)
        ''')
        .eq('organiser_id', organizerId)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getExhibitionById(String id) async {
    final response = await client
        .from('exhibitions')
        .select('''
          *,
          category:exhibition_categories(*),
          venue_type:venue_types(*),
          event_type:event_types(*),
          measurement_unit:measurement_units(*),
          organiser:profiles(*)
        ''')
        .eq('id', id)
        .single();
    
    return response;
  }

  Future<List<Map<String, dynamic>>> getExhibitionsByCategory(String categoryId) async {
    final response = await client
        .from('exhibitions')
        .select('''
          *,
          category:exhibition_categories(*),
          venue_type:venue_types(*),
          event_type:event_types(*),
          measurement_unit:measurement_units(*),
          organiser:profiles(*)
        ''')
        .eq('category_id', categoryId)
        .eq('status', 'published')
        .gte('end_date', DateTime.now().toIso8601String())
        .order('start_date', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Exhibition Categories methods
  Future<List<Map<String, dynamic>>> getExhibitionCategories() async {
    final response = await client
        .from('exhibition_categories')
        .select()
        .order('name', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getExhibitionCategoryById(String id) async {
    final response = await client
        .from('exhibition_categories')
        .select()
        .eq('id', id)
        .single();
    
    return response;
  }

  Future<Map<String, dynamic>?> getExhibitionCategoryByName(String name) async {
    final response = await client
        .from('exhibition_categories')
        .select()
        .eq('name', name)
        .single();
    
    return response;
  }

  // Event Types methods
  Future<List<Map<String, dynamic>>> getEventTypes() async {
    final response = await client
        .from('event_types')
        .select()
        .order('name', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getEventTypeById(String id) async {
    final response = await client
        .from('event_types')
        .select()
        .eq('id', id)
        .single();
    
    return response;
  }

  Future<Map<String, dynamic>?> getEventTypeByName(String name) async {
    final response = await client
        .from('event_types')
        .select()
        .eq('name', name)
        .single();
    
    return response;
  }

  // Venue Types methods
  Future<List<Map<String, dynamic>>> getVenueTypes() async {
    final response = await client
        .from('venue_types')
        .select()
        .order('name', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getVenueTypeById(String id) async {
    final response = await client
        .from('venue_types')
        .select()
        .eq('id', id)
        .single();
    
    return response;
  }

  Future<Map<String, dynamic>?> getVenueTypeByName(String name) async {
    final response = await client
        .from('venue_types')
        .select()
        .eq('name', name)
        .single();
    
    return response;
  }

  // Measurement Units methods
  Future<List<Map<String, dynamic>>> getMeasurementUnits({String? type}) async {
    var query = client
        .from('measurement_units')
        .select('*');

    if (type != null) {
      query = query.eq('type', type);
    }
    
    final response = await query.order('name', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getMeasurementUnitById(String id) async {
    final response = await client
        .from('measurement_units')
        .select('*')
        .eq('id', id)
        .single();
    
    return response;
  }

  Future<Map<String, dynamic>?> getMeasurementUnitBySymbol(String symbol) async {
    final response = await client
        .from('measurement_units')
        .select('*')
        .eq('symbol', symbol)
        .single();
    
    return response;
  }

  Future<Map<String, dynamic>> createMeasurementUnit({
    required String name,
    required String symbol,
    required String type,
    String? description,
  }) async {
    final currentUser = client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final unitData = {
      'name': name,
      'symbol': symbol,
      'type': type,
      'description': description,
      'created_by': currentUser.id,
    };

    final response = await client
        .from('measurement_units')
        .insert(unitData)
        .select('*')
        .single();
    
    return response;
  }

  Future<Map<String, dynamic>> updateMeasurementUnit(
    String id, {
    String? name,
    String? symbol,
    String? type,
    String? description,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (symbol != null) updates['symbol'] = symbol;
    if (type != null) updates['type'] = type;
    if (description != null) updates['description'] = description;

    final response = await client
        .from('measurement_units')
        .update(updates)
        .eq('id', id)
        .select('*')
        .single();
    
    return response;
  }

  // Ensure default measurement units exist
  Future<void> ensureDefaultMeasurementUnits() async {
    try {
      print('DEBUG: ensureDefaultMeasurementUnits called');
      final existingUnits = await getMeasurementUnits(type: 'area');
      print('DEBUG: Existing measurement units: ${existingUnits.length}');
      
      if (existingUnits.isEmpty) {
        print('DEBUG: No measurement units found, creating defaults...');
        
        // Try to create without created_by first (in case the constraint allows null)
        try {
          print('DEBUG: Attempting to create units without created_by...');
          final response = await client.from('measurement_units').insert([
            {
              'name': 'Square Meter',
              'symbol': 'm²',
              'type': 'area',
              'description': 'Standard square meter unit',
            },
            {
              'name': 'Square Feet',
              'symbol': 'ft²',
              'type': 'area',
              'description': 'Square feet unit',
            },
            {
              'name': 'Square Yard',
              'symbol': 'yd²',
              'type': 'area',
              'description': 'Square yard unit',
            },
          ]).select();
          print('DEBUG: Default measurement units created successfully: ${response.length} units');
        } catch (insertError) {
          print('DEBUG: Failed to create without created_by: $insertError');
          
          // If that fails, try with created_by
          final currentUser = client.auth.currentUser;
          print('DEBUG: Current user: ${currentUser?.id}');
          if (currentUser != null) {
            try {
              print('DEBUG: Attempting to create units with created_by...');
              final response = await client.from('measurement_units').insert([
                {
                  'name': 'Square Meter',
                  'symbol': 'm²',
                  'type': 'area',
                  'description': 'Standard square meter unit',
                  'created_by': currentUser.id,
                },
                {
                  'name': 'Square Feet',
                  'symbol': 'ft²',
                  'type': 'area',
                  'description': 'Square feet unit',
                  'created_by': currentUser.id,
                },
                {
                  'name': 'Square Yard',
                  'symbol': 'yd²',
                  'type': 'area',
                  'description': 'Square yard unit',
                  'created_by': currentUser.id,
                },
              ]).select();
              print('DEBUG: Default measurement units created with created_by successfully: ${response.length} units');
            } catch (insertError2) {
              print('DEBUG: Failed to create with created_by: $insertError2');
              throw insertError2;
            }
          } else {
            print('DEBUG: No current user found, cannot create measurement units');
            throw Exception('No authenticated user found');
          }
        }
      } else {
        print('DEBUG: Measurement units already exist, no need to create defaults');
      }
    } catch (e) {
      print('DEBUG: Error in ensureDefaultMeasurementUnits: $e');
      throw e;
    }
  }

  // Amenities methods
  Future<List<Map<String, dynamic>>> getAmenities() async {
    final response = await client
        .from('amenities')
        .select()
        .order('name', ascending: true);
    
    // Remove duplicates based on id
    final List<Map<String, dynamic>> uniqueAmenities = [];
    final Set<String> seenIds = {};
    
    for (final amenity in response) {
      final id = amenity['id'] as String;
      if (!seenIds.contains(id)) {
        seenIds.add(id);
        uniqueAmenities.add(amenity);
      }
    }
    
    return uniqueAmenities;
  }

  Future<Map<String, dynamic>?> getAmenityById(String id) async {
    final response = await client
        .from('amenities')
        .select()
        .eq('id', id)
        .single();
    
    return response;
  }

  Future<Map<String, dynamic>> createAmenity({
    required String name,
    String? description,
    String? icon,
  }) async {
    final amenityData = {
      'name': name,
      'description': description,
      'icon': icon,
    };

    final response = await client
        .from('amenities')
        .insert(amenityData)
        .select()
        .single();
    
    return response;
  }

  Future<Map<String, dynamic>> updateAmenity(
    String id, {
    String? name,
    String? description,
    String? icon,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (description != null) updates['description'] = description;
    if (icon != null) updates['icon'] = icon;

    final response = await client
        .from('amenities')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    
    return response;
  }

  Future<List<Map<String, dynamic>>> getStallAmenities(String stallId) async {
    final response = await client
        .from('stall_amenities')
        .select('''
          amenity:amenities(*)
        ''')
        .eq('stall_id', stallId)
        .order('created_at', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addStallAmenity(String stallId, String amenityId) async {
    await client
        .from('stall_amenities')
        .insert({
          'stall_id': stallId,
          'amenity_id': amenityId,
        });
  }

  Future<void> removeStallAmenity(String stallId, String amenityId) async {
    await client
        .from('stall_amenities')
        .delete()
        .eq('stall_id', stallId)
        .eq('amenity_id', amenityId);
  }

  // Stall Application methods
  Future<List<Map<String, dynamic>>> getStallApplications({String? brandId}) async {
    var query = client
        .from('stall_applications')
        .select('''
          *,
          stall:stalls(
            *,
            unit:measurement_units(*),
            amenities:stall_amenities!stall_amenities_stall_id_fkey(
              amenity:amenities(*)
            )
          ),
          stall_instance:stall_instances(*),
          exhibition:exhibitions!stall_applications_exhibition_id_fkey(
            id,
            title,
            start_date,
            end_date,
            address,
            city,
            state,
            country
          ),
          brand:profiles!stall_applications_brand_id_fkey(
            id,
            company_name,
            full_name,
            email,
            phone
          )
        ''');
    
    if (brandId != null) {
      query = query.eq('brand_id', brandId);
    }
    
    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getStallApplicationsByExhibition(String exhibitionId) async {
    final response = await client
        .from('stall_applications')
        .select('''
          *,
          stall:stalls(
            *,
            unit:measurement_units(*),
            amenities:stall_amenities!stall_amenities_stall_id_fkey(
              amenity:amenities(*)
            )
          ),
          stall_instance:stall_instances(*),
          exhibition:exhibitions!stall_applications_exhibition_id_fkey(
            id,
            title,
            start_date,
            end_date,
            address,
            city,
            state,
            country
          ),
          brand:profiles!stall_applications_brand_id_fkey(
            id,
            company_name,
            full_name,
            email,
            phone
          )
        ''')
        .eq('exhibition_id', exhibitionId)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getStallApplicationById(String id) async {
    final response = await client
        .from('stall_applications')
        .select('''
          *,
          stall:stalls(
            *,
            unit:measurement_units(*),
            amenities:stall_amenities!stall_amenities_stall_id_fkey(
              amenity:amenities(*)
            )
          ),
          stall_instance:stall_instances(*),
          exhibition:exhibitions!stall_applications_exhibition_id_fkey(
            id,
            title,
            start_date,
            end_date,
            address,
            city,
            state,
            country
          ),
          brand:profiles!stall_applications_brand_id_fkey(
            id,
            company_name,
            full_name,
            email,
            phone
          )
        ''')
        .eq('id', id)
        .single();
    
    return response;
  }

  Future<Map<String, dynamic>> createStallApplication({
    required String stallId,
    required String exhibitionId,
    String? stallInstanceId,
    String? message,
  }) async {
    final currentUser = client.auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    // First, create the stall application
    final response = await client
        .from('stall_applications')
        .insert({
          'stall_id': stallId,
          'brand_id': currentUser.id,
          'exhibition_id': exhibitionId,
          'stall_instance_id': stallInstanceId,
          'message': message,
          'status': 'pending',
        })
        .select()
        .single();
    
    // Then, manually update the stall instance status to 'pending'
    // This ensures immediate status update even if the trigger doesn't handle INSERT
    if (stallInstanceId != null) {
      try {
        final updateResult = await client
            .from('stall_instances')
            .update({
              'status': 'pending',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', stallInstanceId)
            .select();
        
      } catch (e) {
        // Log the error but don't fail the application creation
      }
    }
    
    return response;
  }

  Future<Map<String, dynamic>> updateStallApplication(String id, {
    String? status,
    String? message,
    bool? bookingConfirmed,
  }) async {
    final updates = <String, dynamic>{};
    if (status != null) updates['status'] = status;
    if (message != null) updates['message'] = message;
    if (bookingConfirmed != null) updates['booking_confirmed'] = bookingConfirmed;

    final response = await client
        .from('stall_applications')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    
    return response;
  }

  Future<void> deleteStallApplication(String id) async {
    await client.from('stall_applications').delete().eq('id', id);
  }

  // Update stall application statuses when exhibition is completed
  Future<void> updateStallStatusesForCompletedExhibition(String exhibitionId) async {
    try {
      // Get all stall applications for this exhibition
      final applications = await client
          .from('stall_applications')
          .select('*')
          .eq('exhibition_id', exhibitionId);
      
      // Update each application based on its current status
      for (final application in applications) {
        final currentStatus = application['status'] as String? ?? 'pending';
        String newStatus;
        
        switch (currentStatus.toLowerCase()) {
          case 'pending':
          case 'payment_pending':
          case 'payment_review':
            // Cancel pending applications by marking them as rejected
            newStatus = 'rejected';
            break;
          case 'booked':
            // Mark booked applications as completed (use approved as a proxy)
            newStatus = 'approved';
            break;
          case 'rejected':
            // Keep rejected as is
            newStatus = 'rejected';
            break;
          default:
            // For any other status, mark as rejected
            newStatus = 'rejected';
            break;
        }
        
        if (newStatus != currentStatus) {
          // Update the application status
          await client
              .from('stall_applications')
              .update({
                'status': newStatus,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', application['id']);
          
          // Also update the corresponding stall instance status
          final stallInstanceId = application['stall_instance_id'];
          if (stallInstanceId != null) {
            String instanceStatus;
            switch (newStatus) {
              case 'approved':
                instanceStatus = 'booked';
                break;
              case 'rejected':
                instanceStatus = 'available';
                break;
              default:
                instanceStatus = 'available';
                break;
            }
            
            await client
                .from('stall_instances')
                .update({
                  'status': instanceStatus,
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', stallInstanceId);
          }
        }
      }
    } catch (e) {
      throw Exception('Failed to update stall statuses: $e');
    }
  }

  // Check and update completed exhibitions
  Future<void> checkAndUpdateCompletedExhibitions() async {
    try {
      final now = DateTime.now();
      
      // Get all exhibitions that have ended but are still marked as published/live/expired
      final completedExhibitions = await client
          .from('exhibitions')
          .select('id, title, end_date, status')
          .lt('end_date', now.toIso8601String())
          .or('status.eq.published,status.eq.live,status.eq.expired');
      
      for (final exhibition in completedExhibitions) {
        // Update exhibition status to completed
        await client
            .from('exhibitions')
            .update({
              'status': 'completed',
              'updated_at': now.toIso8601String(),
            })
            .eq('id', exhibition['id']);
        
        // Update all stall application statuses for this exhibition
        await updateStallStatusesForCompletedExhibition(exhibition['id']);
      }
    } catch (e) {
      throw Exception('Failed to check completed exhibitions: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> subscribeToStallApplications({String? brandId}) {
    final query = client
        .from('stall_applications')
        .stream(primaryKey: ['id']);

    if (brandId != null) {
      return query
          .eq('brand_id', brandId)
          .order('created_at', ascending: false)
          .map((event) => List<Map<String, dynamic>>.from(event));
    }

    return query
        .order('created_at', ascending: false)
        .map((event) => List<Map<String, dynamic>>.from(event));
  }



  // Subscribe to stall instances for real-time updates
  Stream<List<Map<String, dynamic>>> subscribeToStallInstances(String exhibitionId) {
    return client
        .from('stall_instances')
        .stream(primaryKey: ['id'])
        .eq('exhibition_id', exhibitionId)
        .order('instance_number', ascending: true)
        .map((event) => List<Map<String, dynamic>>.from(event));
  }

  // User profile methods
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    final response = await client
        .from('profiles')
        .select('''
          *,
          applications:stall_applications!stall_applications_brand_id_fkey(
            id,
            status,
            created_at,
            exhibition:exhibitions!stall_applications_exhibition_id_fkey(
              id,
              title,
              start_date,
              end_date
            )
          )
        ''')
        .eq('id', userId)
        .single();
    
    return response;
  }

  Future<Map<String, dynamic>> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    // Ensure we don't update protected fields
    updates.removeWhere((key, _) => [
      'id',
      'email',
      'role',
      'created_at',
      'followers_count',
      'attendees_hosted',
    ].contains(key));

    final response = await client
        .from('profiles')
        .update(updates)
        .eq('id', userId)
        .select()
        .single();
    
    return response;
  }

  // Profile picture methods
  Future<String?> uploadProfilePicture({
    required String userId,
    required String filePath,
    String? contentType,
  }) async {
    try {
      print('Uploading profile picture for user: $userId'); // Debug log
      
      // Create a unique filename
      final fileExtension = filePath.split('.').last.toLowerCase();
      final fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final path = 'avatars/$fileName';
      
      // Upload to profile-avatars bucket
      final bucket = 'profile-avatars';
      
      // Ensure bucket exists
      await ensureStorageBucketExists(bucket, isPublic: true);
      
      // Fix MIME type mapping
      String mimeType;
      switch (fileExtension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg'; // Default fallback
      }
      
      // Upload the file
      final publicUrl = await uploadFile(
        bucket: bucket,
        path: path,
        filePath: filePath,
        contentType: contentType ?? mimeType,
      );
      
      if (publicUrl != null) {
        // Update the user's profile with the new avatar URL
        await updateUserProfile(userId, {'avatar_url': publicUrl});
        print('Profile picture uploaded successfully: $publicUrl'); // Debug log
        return publicUrl;
      } else {
        throw Exception('Failed to upload profile picture');
      }
    } catch (e) {
      print('Error uploading profile picture: $e'); // Debug log
      rethrow;
    }
  }

  Future<String?> uploadProfilePictureFromBytes({
    required String userId,
    required Uint8List fileBytes,
    required String fileName,
    String? contentType,
  }) async {
    try {
      print('Uploading profile picture from bytes for user: $userId'); // Debug log
      
      // Create a unique filename
      final fileExtension = fileName.split('.').last.toLowerCase();
      final uniqueFileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final path = 'avatars/$uniqueFileName';
      
      // Upload to profile-avatars bucket
      final bucket = 'profile-avatars';
      
      // Ensure bucket exists
      await ensureStorageBucketExists(bucket, isPublic: true);
      
      // Fix MIME type mapping
      String mimeType;
      switch (fileExtension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg'; // Default fallback
      }
      
      // Upload the file
      final publicUrl = await uploadFile(
        bucket: bucket,
        path: path,
        fileBytes: fileBytes,
        contentType: contentType ?? mimeType,
      );
      
      if (publicUrl != null) {
        // Update the user's profile with the new avatar URL
        await updateUserProfile(userId, {'avatar_url': publicUrl});
        print('Profile picture uploaded successfully: $publicUrl'); // Debug log
        return publicUrl;
      } else {
        throw Exception('Failed to upload profile picture');
      }
    } catch (e) {
      print('Error uploading profile picture: $e'); // Debug log
      rethrow;
    }
  }

  Future<void> deleteProfilePicture(String userId) async {
    try {
      print('Deleting profile picture for user: $userId'); // Debug log
      
      // Get current profile to find the avatar URL
      final profile = await getUserProfile(userId);
      final avatarUrl = profile?['avatar_url'];
      
      if (avatarUrl != null) {
        // Extract path from URL
        final uri = Uri.parse(avatarUrl);
        final pathSegments = uri.pathSegments;
        
        if (pathSegments.length >= 3) {
          // URL format: /storage/v1/object/public/bucket/path
          final bucket = pathSegments[3]; // bucket name
          final path = pathSegments.sublist(4).join('/'); // file path
          
          // Delete from storage
          await client.storage.from(bucket).remove([path]);
          print('Profile picture deleted from storage'); // Debug log
        }
        
        // Update profile to remove avatar URL
        await updateUserProfile(userId, {'avatar_url': null});
        print('Profile picture deleted successfully'); // Debug log
      }
    } catch (e) {
      print('Error deleting profile picture: $e'); // Debug log
      rethrow;
    }
  }

  // Company logo methods
  Future<String?> uploadCompanyLogo({
    required String userId,
    required String filePath,
    String? contentType,
  }) async {
    try {
      print('Uploading company logo for user: $userId'); // Debug log
      
      // Create a unique filename
      final fileExtension = filePath.split('.').last.toLowerCase();
      final fileName = 'logo_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final path = 'logos/$fileName';
      
      // Upload to profile-avatars bucket
      final bucket = 'profile-avatars';
      
      // Ensure bucket exists
      await ensureStorageBucketExists(bucket, isPublic: true);
      
      // Fix MIME type mapping
      String mimeType;
      switch (fileExtension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg'; // Default fallback
      }
      
      // Upload the file
      final publicUrl = await uploadFile(
        bucket: bucket,
        path: path,
        filePath: filePath,
        contentType: contentType ?? mimeType,
      );
      
      if (publicUrl != null) {
        // Update the user's profile with the new company logo URL
        await updateUserProfile(userId, {'company_logo_url': publicUrl});
        print('Company logo uploaded successfully: $publicUrl'); // Debug log
        return publicUrl;
      } else {
        throw Exception('Failed to upload company logo');
      }
    } catch (e) {
      print('Error uploading company logo: $e'); // Debug log
      rethrow;
    }
  }

  Future<String?> uploadCompanyLogoFromBytes({
    required String userId,
    required Uint8List fileBytes,
    required String fileName,
    String? contentType,
  }) async {
    try {
      print('Uploading company logo from bytes for user: $userId'); // Debug log
      
      // Create a unique filename
      final fileExtension = fileName.split('.').last.toLowerCase();
      final uniqueFileName = 'logo_${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final path = 'logos/$uniqueFileName';
      
      // Upload to profile-avatars bucket
      final bucket = 'profile-avatars';
      
      // Ensure bucket exists
      await ensureStorageBucketExists(bucket, isPublic: true);
      
      // Fix MIME type mapping
      String mimeType;
      switch (fileExtension) {
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'png':
          mimeType = 'image/png';
          break;
        case 'gif':
          mimeType = 'image/gif';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg'; // Default fallback
      }
      
      // Upload the file
      final publicUrl = await uploadFile(
        bucket: bucket,
        path: path,
        fileBytes: fileBytes,
        contentType: contentType ?? mimeType,
      );
      
      if (publicUrl != null) {
        // Update the user's profile with the new company logo URL
        await updateUserProfile(userId, {'company_logo_url': publicUrl});
        print('Company logo uploaded successfully: $publicUrl'); // Debug log
        return publicUrl;
      } else {
        throw Exception('Failed to upload company logo');
      }
    } catch (e) {
      print('Error uploading company logo: $e'); // Debug log
      rethrow;
    }
  }

  Future<void> deleteCompanyLogo(String userId) async {
    try {
      print('Deleting company logo for user: $userId'); // Debug log
      
      // Get current profile to find the company logo URL
      final profile = await getUserProfile(userId);
      final logoUrl = profile?['company_logo_url'];
      
      if (logoUrl != null) {
        // Extract path from URL
        final uri = Uri.parse(logoUrl);
        final pathSegments = uri.pathSegments;
        
        if (pathSegments.length >= 3) {
          // URL format: /storage/v1/object/public/bucket/path
          final bucket = pathSegments[3]; // bucket name
          final path = pathSegments.sublist(4).join('/'); // file path
          
          // Delete from storage
          await client.storage.from(bucket).remove([path]);
          print('Company logo deleted from storage'); // Debug log
        }
        
        // Update profile to remove company logo URL
        await updateUserProfile(userId, {'company_logo_url': null});
        print('Company logo deleted successfully'); // Debug log
      }
    } catch (e) {
      print('Error deleting company logo: $e'); // Debug log
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createUserProfile({
    required String userId,
    required String email,
    String? fullName,
    String? companyName,
    String? phone,
    String? description,
    String? websiteUrl,
    String? facebookUrl,
    String role = 'shopper',
  }) async {
    final profileData = {
      'id': userId,
      'email': email,
      'full_name': fullName,
      'company_name': companyName,
      'phone': phone,
      'description': description,
      'website_url': websiteUrl,
      'facebook_url': facebookUrl,
      'role': role,
      'is_active': true,
      'ban_status': false,
    };

    final response = await client
        .from('profiles')
        .insert(profileData)
        .select()
        .single();
    
    return response;
  }

  Future<List<Map<String, dynamic>>> searchProfiles({
    String? query,
    String? role,
    bool? isActive,
    bool? isBanned,
  }) async {
    var dbQuery = client
        .from('profiles')
        .select('''
          id,
          email,
          full_name,
          role,
          company_name,
          avatar_url,
          description,
          website_url,
          facebook_url,
          followers_count,
          attendees_hosted,
          is_active,
          ban_status
        ''');
    
    if (query != null && query.isNotEmpty) {
      dbQuery = dbQuery.or(
        'email.ilike.%$query%,full_name.ilike.%$query%,company_name.ilike.%$query%'
      );
    }
    
    if (role != null) {
      dbQuery = dbQuery.eq('role', role);
    }
    
    if (isActive != null) {
      dbQuery = dbQuery.eq('is_active', isActive);
    }
    
    if (isBanned != null) {
      dbQuery = dbQuery.eq('ban_status', isBanned);
    }
    
    final response = await dbQuery.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateAvatarUrl(String userId, String avatarUrl) async {
    await client
        .from('profiles')
        .update({'avatar_url': avatarUrl})
        .eq('id', userId);
  }

  Future<void> _syncUserRole(User user) async {
    try {
      // Get role from profiles table
      final profile = await getUserProfile(user.id);
      final profileRole = profile?['role'] as String?;
      // Get current metadata role
      final metadataRole = user.userMetadata?['role'] as String?;
      
      if (profileRole != null) {
        // If metadata role is different from profile role, update metadata
        if (metadataRole != profileRole) {
          await client.auth.updateUser(UserAttributes(
            data: {
              ...user.userMetadata ?? {},
              'role': profileRole,
            },
          ));
          
          // Verify the update
          final updatedUser = await client.auth.getUser();
        }
      } else if (metadataRole != null) {
        // If profile role is missing but metadata has role, update profile
        await client
            .from('profiles')
            .update({'role': metadataRole})
            .eq('id', user.id);
      }
    } catch (e) {
      // Error syncing user role
    }
  }

  Stream<Map<String, dynamic>> subscribeToProfile(String userId) {
    return client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((event) => event.first);
  }

  // Stall methods
  Future<List<Map<String, dynamic>>> getStallsByExhibition(String exhibitionId) async {
    final response = await client
        .from('stalls')
        .select('''
          *,
          unit:measurement_units(*),
          instances:stall_instances!stall_instances_stall_id_fkey(
            id,
            position_x,
            position_y,
            rotation_angle,
            status,
            instance_number,
            price,
            original_price
          ),
          amenities:stall_amenities!stall_amenities_stall_id_fkey(
            amenity:amenities(*)
          )
        ''')
        .eq('exhibition_id', exhibitionId)
        .order('name', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getStallById(String id) async {
    final response = await client
        .from('stalls')
        .select('''
          *,
          unit:measurement_units(*),
          instances:stall_instances!stall_instances_stall_id_fkey(
            id,
            position_x,
            position_y,
            rotation_angle,
            status,
            instance_number,
            price,
            original_price
          ),
          amenities:stall_amenities!stall_amenities_stall_id_fkey(
            amenity:amenities(*)
          )
        ''')
        .eq('id', id)
        .single();
    
    return response;
  }

  Future<List<Map<String, dynamic>>> getAvailableStallInstances(String exhibitionId) async {
    final response = await client
        .from('stall_instances')
        .select('''
          *,
          stall:stalls(
            *,
            unit:measurement_units(*),
            amenities:stall_amenities!stall_amenities_stall_id_fkey(
              amenity:amenities(*)
            )
          )
        ''')
        .eq('exhibition_id', exhibitionId)
        .eq('status', 'available')
        .order('instance_number', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getAllAmenities() async {
    final response = await client
        .from('amenities')
        .select()
        .order('name', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Search and filter methods
  Future<List<Map<String, dynamic>>> searchExhibitions(String query) async {
    final response = await client
        .from('exhibitions')
        .select('''
          *,
          category:exhibition_categories(*),
          venue_type:venue_types(*),
          event_type:event_types(*),
          measurement_unit:measurement_units(*),
          organiser:profiles(*)
        ''')
        .or('title.ilike.%$query%,description.ilike.%$query%,city.ilike.%$query%,state.ilike.%$query%')
        .eq('status', 'published')
        .gte('end_date', DateTime.now().toIso8601String())
        .order('start_date', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> filterExhibitions({
    String? categoryId,
    String? city,
    String? state,
    String? eventTypeId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    var query = client
        .from('exhibitions')
        .select('''
          *,
          category:exhibition_categories(*),
          venue_type:venue_types(*),
          event_type:event_types(*),
          measurement_unit:measurement_units(*),
          organiser:profiles(*)
        ''')
        .eq('status', 'published')
        .gte('end_date', DateTime.now().toIso8601String());
    
    if (categoryId != null) {
      query = query.eq('category_id', categoryId);
    }
    
    if (city != null) {
      query = query.eq('city', city);
    }
    
    if (state != null) {
      query = query.eq('state', state);
    }
    
    if (eventTypeId != null) {
      query = query.eq('event_type_id', eventTypeId);
    }
    
    if (startDate != null) {
      query = query.gte('start_date', startDate.toIso8601String());
    }
    
    if (endDate != null) {
      query = query.lte('end_date', endDate.toIso8601String());
    }
    
    final response = await query.order('start_date', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  // File upload methods
  Future<String?> uploadFile({
    required String bucket,
    required String path,
    String? filePath,
    Uint8List? fileBytes,
    String? contentType,
  }) async {
    try {
      print('Starting file upload to bucket: $bucket, path: $path'); // Debug log
      
      // Validate bucket exists
      try {
        await client.storage.getBucket(bucket);
        print('Bucket $bucket exists and is accessible'); // Debug log
      } catch (e) {
        print('Bucket validation error: $e'); // Debug log
        throw Exception('Storage bucket "$bucket" does not exist or is not accessible: $e');
      }
      
      if (fileBytes != null) {
        // Upload from bytes (Web platform)
        print('Uploading from bytes, size: ${fileBytes.length}'); // Debug log
        
        // Determine MIME type from path if not provided
        String mimeType = contentType ?? _getMimeTypeFromPath(path);
        
        final fileOptions = FileOptions(
          contentType: mimeType,
          upsert: true,
        );
        
        await client.storage
            .from(bucket)
            .uploadBinary(path, fileBytes, fileOptions: fileOptions);
        print('Upload from bytes completed'); // Debug log
      } else if (filePath != null) {
        // Upload from file path (Mobile/Desktop platforms)
        print('Uploading from file path: $filePath'); // Debug log
        
        // Determine MIME type from path if not provided
        String mimeType = contentType ?? _getMimeTypeFromPath(path);
        
        final fileOptions = FileOptions(
          contentType: mimeType,
          upsert: true,
        );
        
        await client.storage
            .from(bucket)
            .upload(path, File(filePath), fileOptions: fileOptions);
        print('Upload from file path completed'); // Debug log
      } else {
        throw Exception('Either fileBytes or filePath must be provided');
      }

      // Get the public URL for the uploaded file
      final publicUrl = client.storage.from(bucket).getPublicUrl(path);
      print('Generated public URL: $publicUrl'); // Debug log
      return publicUrl;
    } catch (e) {
      print('Upload error: $e'); // Debug log
      return null;
    }
  }

  String getPublicUrl(String bucket, String path) {
    final response = client.storage.from(bucket).getPublicUrl(path);
    return response;
  }

  // Helper method to determine MIME type from file path
  String _getMimeTypeFromPath(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      case 'csv':
        return 'text/csv';
      case 'json':
        return 'application/json';
      case 'xml':
        return 'application/xml';
      case 'zip':
        return 'application/zip';
      case 'rar':
        return 'application/x-rar-compressed';
      case 'mp4':
        return 'video/mp4';
      case 'avi':
        return 'video/x-msvideo';
      case 'mov':
        return 'video/quicktime';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'svg':
        return 'image/svg+xml';
      default:
        return 'application/octet-stream';
    }
  }

  // Test method to check if storage buckets exist
  Future<bool> checkStorageBucketExists(String bucketName) async {
    try {
      final buckets = await client.storage.listBuckets();
      return buckets.any((bucket) => bucket.name == bucketName);
    } catch (e) {
      print('Error checking bucket existence: $e');
      return false;
    }
  }

  // Test method to debug profile-avatars storage specifically
  Future<Map<String, dynamic>> debugProfileAvatarsStorage() async {
    try {
      print('Starting debug profile-avatars storage check...'); // Debug log
      
      final currentUser = this.currentUser;
      print('Current user: ${currentUser?.id}'); // Debug log
      
      // Check if profile-avatars bucket exists
      final bucketExists = await checkStorageBucketExists('profile-avatars');
      print('profile-avatars bucket exists: $bucketExists'); // Debug log
      
      // List all available buckets
      final allBuckets = await listStorageBuckets();
      print('All available buckets: $allBuckets'); // Debug log
      
      // Get bucket details if it exists
      Map<String, dynamic>? bucketDetails;
      if (bucketExists) {
        try {
          final bucket = await client.storage.getBucket('profile-avatars');
          bucketDetails = {
            'name': bucket.name,
            'public': bucket.public,
            'file_size_limit': bucket.fileSizeLimit,
            'allowed_mime_types': bucket.allowedMimeTypes,
          };
          print('Bucket details: $bucketDetails'); // Debug log
        } catch (e) {
          print('Error getting bucket details: $e'); // Debug log
          bucketDetails = {'error': e.toString()};
        }
      }
      
      return {
        'bucket_exists': bucketExists,
        'current_user': currentUser?.id ?? 'No user',
        'all_buckets': allBuckets,
        'bucket_details': bucketDetails,
        'error': null,
      };
    } catch (e) {
      print('Debug storage error: $e'); // Debug log
      return {
        'bucket_exists': false,
        'current_user': 'Error getting user',
        'all_buckets': [],
        'bucket_details': null,
        'error': e.toString(),
      };
    }
  }

  // Test method to debug lookbook storage specifically
  Future<Map<String, dynamic>> debugLookbookStorage() async {
    try {
      print('Starting debug storage check...'); // Debug log
      
      final currentUser = this.currentUser;
      print('Current user: ${currentUser?.id}'); // Debug log
      
      // Check if lookbooks bucket exists
      final bucketExists = await checkStorageBucketExists('lookbooks');
      print('Lookbooks bucket exists: $bucketExists'); // Debug log
      
      // List all available buckets
      final allBuckets = await listStorageBuckets();
      print('All available buckets: $allBuckets'); // Debug log
      
      // Get bucket details if it exists
      Map<String, dynamic>? bucketDetails;
      if (bucketExists) {
        try {
          final bucket = await client.storage.getBucket('lookbooks');
          bucketDetails = {
            'name': bucket.name,
            'public': bucket.public,
            'file_size_limit': bucket.fileSizeLimit,
            'allowed_mime_types': bucket.allowedMimeTypes,
          };
          print('Bucket details: $bucketDetails'); // Debug log
        } catch (e) {
          print('Error getting bucket details: $e'); // Debug log
          bucketDetails = {'error': e.toString()};
        }
      }
      
      return {
        'bucket_exists': bucketExists,
        'current_user': currentUser?.id ?? 'No user',
        'all_buckets': allBuckets,
        'bucket_details': bucketDetails,
        'error': null,
      };
    } catch (e) {
      print('Debug storage error: $e'); // Debug log
      return {
        'bucket_exists': false,
        'current_user': 'Error getting user',
        'all_buckets': [],
        'bucket_details': null,
        'error': e.toString(),
      };
    }
  }

  // List all available storage buckets
  Future<List<String>> listStorageBuckets() async {
    try {
      final buckets = await client.storage.listBuckets();
      return buckets.map((bucket) => bucket.name).toList();
    } catch (e) {
      print('Error listing buckets: $e');
      return [];
    }
  }



  // Ensure storage bucket exists, create if it doesn't
  Future<bool> ensureStorageBucketExists(String bucketName, {bool isPublic = true}) async {
    try {
      print('Checking if bucket exists: $bucketName'); // Debug log
      final exists = await checkStorageBucketExists(bucketName);
      if (exists) {
        print('Bucket $bucketName already exists'); // Debug log
        return true;
      }
      print('Bucket $bucketName does not exist, creating...'); // Debug log
      final created = await createStorageBucket(bucketName, isPublic: isPublic);
      if (created) {
        print('Successfully created bucket: $bucketName'); // Debug log
      } else {
        print('Failed to create bucket: $bucketName'); // Debug log
      }
      return created;
    } catch (e) {
      print('Error ensuring bucket exists: $e'); // Debug log
      return false;
    }
  }

  // Enhanced method to ensure profile-avatars bucket exists with proper error handling
  Future<bool> ensureProfileAvatarsBucket() async {
    try {
      print('Ensuring profile-avatars bucket exists...'); // Debug log
      
      // First check if bucket exists
      final bucketExists = await checkStorageBucketExists('profile-avatars');
      if (bucketExists) {
        print('profile-avatars bucket already exists'); // Debug log
        return true;
      }
      
      // Try to create the bucket
      print('Creating profile-avatars bucket...'); // Debug log
      final success = await createStorageBucket('profile-avatars', isPublic: true);
      
      if (success) {
        print('Successfully created profile-avatars bucket'); // Debug log
        return true;
      } else {
        print('Failed to create profile-avatars bucket - this is expected if bucket creation is restricted'); // Debug log
        // Even if creation fails, check again in case it was created by another process
        final existsAfterAttempt = await checkStorageBucketExists('profile-avatars');
        if (existsAfterAttempt) {
          print('profile-avatars bucket exists after failed creation attempt'); // Debug log
          return true;
        }
        return false;
      }
    } catch (e) {
      print('Error ensuring profile-avatars bucket: $e'); // Debug log
      // Check if bucket exists despite the error
      try {
        final existsAfterError = await checkStorageBucketExists('profile-avatars');
        if (existsAfterError) {
          print('profile-avatars bucket exists despite creation error'); // Debug log
          return true;
        }
      } catch (checkError) {
        print('Error checking bucket existence after creation error: $checkError'); // Debug log
      }
      return false;
    }
  }

  // Real-time subscriptions
  Stream<List<Map<String, dynamic>>> subscribeToExhibitions() {
    return client
        .from('exhibitions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((event) => List<Map<String, dynamic>>.from(event));
  }

  // Exhibition Favorites methods
  Future<List<Map<String, dynamic>>> getExhibitionFavorites(String userId) async {
    try {
      print('Getting exhibition favorites for user: $userId'); // Debug log
      
      // First, let's test if we can get any data at all from the table
      try {
        final testResponse = await client
            .from('exhibition_favorites')
            .select('*')
            .eq('user_id', userId);
        print('Test query result: ${testResponse.length} items'); // Debug log
        print('Test query data: $testResponse'); // Debug log
      } catch (e) {
        print('Test query failed: $e'); // Debug log
      }
      
      // Also check if there's any data in the table at all
      try {
        final allFavorites = await client
            .from('exhibition_favorites')
            .select('*')
            .limit(5);
        print('All favorites in table: ${allFavorites.length} items'); // Debug log
        print('Sample favorites data: $allFavorites'); // Debug log
      } catch (e) {
        print('All favorites query failed: $e'); // Debug log
      }
      
      // Check if exhibitions table has data
      try {
        final exhibitions = await client
            .from('exhibitions')
            .select('id, title')
            .limit(5);
        print('Exhibitions in table: ${exhibitions.length} items'); // Debug log
        print('Sample exhibitions: $exhibitions'); // Debug log
      } catch (e) {
        print('Exhibitions query failed: $e'); // Debug log
      }
      
      final response = await client
          .from('exhibition_favorites')
          .select('''
            *,
            exhibition:exhibitions(
              id,
              title,
              start_date,
              end_date,
              city,
              state,
              description,
              status
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      print('Raw response from exhibition_favorites: $response'); // Debug log
      final result = List<Map<String, dynamic>>.from(response);
      print('Processed result: ${result.length} items'); // Debug log
      
      return result;
    } catch (e) {
      print('Error in getExhibitionFavorites: $e');
      return [];
    }
  }

  Future<bool> isExhibitionFavorited(String userId, String exhibitionId) async {
    try {
      print('Checking if exhibition is favorited: user=$userId, exhibition=$exhibitionId'); // Debug log
      
      final response = await client
          .from('exhibition_favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('exhibition_id', exhibitionId)
          .maybeSingle();
      
      final isFavorited = response != null;
      print('Favorite check result: $isFavorited'); // Debug log
      
      return isFavorited;
    } catch (e) {
      print('Error in isExhibitionFavorited: $e'); // Debug log
      return false;
    }
  }

  Future<void> toggleExhibitionFavorite(String userId, String exhibitionId) async {
    try {
      print('Toggling favorite for user: $userId, exhibition: $exhibitionId'); // Debug log
      
      final isFavorited = await isExhibitionFavorited(userId, exhibitionId);
      print('Current favorite status: $isFavorited'); // Debug log
      
      if (isFavorited) {
        // Remove from favorites
        print('Removing from favorites...'); // Debug log
        await client
            .from('exhibition_favorites')
            .delete()
            .eq('user_id', userId)
            .eq('exhibition_id', exhibitionId);
        print('Successfully removed from favorites'); // Debug log
      } else {
        // Add to favorites
        print('Adding to favorites...'); // Debug log
        final result = await client
            .from('exhibition_favorites')
            .insert({
              'user_id': userId,
              'exhibition_id': exhibitionId,
            });
        print('Successfully added to favorites: $result'); // Debug log
      }
    } catch (e) {
      print('Error in toggleExhibitionFavorite: $e'); // Debug log
      rethrow; // Re-throw the error so the calling code can handle it
    }
  }

  Future<bool> isExhibitionAttending(String userId, String exhibitionId) async {
    try {
      final response = await client
          .from('exhibition_attendees')
          .select('id')
          .eq('user_id', userId)
          .eq('exhibition_id', exhibitionId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> toggleExhibitionAttending(String userId, String exhibitionId) async {
    final isAttending = await isExhibitionAttending(userId, exhibitionId);
    
    if (isAttending) {
      // Remove from attending
      await client
          .from('exhibition_attendees')
          .delete()
          .eq('user_id', userId)
          .eq('exhibition_id', exhibitionId);
    } else {
      // Add to attending
      await client
          .from('exhibition_attendees')
          .insert({
            'user_id': userId,
            'exhibition_id': exhibitionId,
          });
    }
  }

  // Gallery Images methods
  Future<List<Map<String, dynamic>>> getExhibitionGalleryImages(String exhibitionId) async {
    final response = await client
        .from('gallery_images')
        .select('*')
        .eq('exhibition_id', exhibitionId)
        .order('created_at', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<List<Map<String, dynamic>>> getExhibitionGalleryImagesByType(String exhibitionId, String imageType) async {
    final response = await client
        .from('gallery_images')
        .select('*')
        .eq('exhibition_id', exhibitionId)
        .eq('image_type', imageType)
        .order('created_at', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Hero Slider methods
  Future<List<Map<String, dynamic>>> getHeroSliders() async {
    try {
      final response = await client
          .from('hero_sliders')
          .select('*')
          .eq('is_active', true)
          .order('order_index', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> subscribeToHeroSliders() {
    return client
        .from('hero_sliders')
        .stream(primaryKey: ['id'])
        .eq('is_active', true)
        .order('order_index', ascending: true)
        .map((event) => List<Map<String, dynamic>>.from(event));
  }

  // Brand Look Book methods
  Future<List<Map<String, dynamic>>> getBrandLookbooks(String brandId) async {
    try {
      final response = await client
          .from('brand_lookbooks')
          .select('*')
          .eq('brand_id', brandId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> subscribeToBrandLookbooks(String brandId) {
    return client
        .from('brand_lookbooks')
        .stream(primaryKey: ['id'])
        .eq('brand_id', brandId)
        .order('created_at', ascending: false)
        .map((event) => List<Map<String, dynamic>>.from(event));
  }

  // Create a new brand lookbook
  Future<Map<String, dynamic>?> createBrandLookbook(Map<String, dynamic> lookbookData) async {
    try {
      print('Creating brand lookbook with data: $lookbookData'); // Debug log
      
      final response = await client
          .from('brand_lookbooks')
          .insert(lookbookData)
          .select()
          .single();
      
      print('Brand lookbook created successfully: ${response['id']}'); // Debug log
      return response;
    } catch (e) {
      print('Error creating brand lookbook: $e');
      return null;
    }
  }

  Future<bool> deleteBrandLookbook(String lookbookId) async {
    try {
      await client
          .from('brand_lookbooks')
          .delete()
          .eq('id', lookbookId);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> updateBrandLookbook(String lookbookId, Map<String, dynamic> lookbookData) async {
    try {
      final response = await client
          .from('brand_lookbooks')
          .update(lookbookData)
          .eq('id', lookbookId)
          .select()
          .single();
      
      return response;
    } catch (e) {
      return null;
    }
  }

  // Brand Gallery methods
  Future<List<Map<String, dynamic>>> getBrandGallery(String brandId) async {
    try {
      final response = await client
          .from('brand_gallery')
          .select('*')
          .eq('brand_id', brandId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> subscribeToBrandGallery(String brandId) {
    return client
        .from('brand_gallery')
        .stream(primaryKey: ['id'])
        .eq('brand_id', brandId)
        .order('created_at', ascending: false)
        .map((event) => List<Map<String, dynamic>>.from(event));
  }

  Future<Map<String, dynamic>?> createBrandGalleryItem(Map<String, dynamic> galleryData) async {
    try {
      final response = await client
          .from('brand_gallery')
          .insert(galleryData)
          .select()
          .single();
      
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteBrandGalleryItem(String galleryItemId) async {
    try {
      await client
          .from('brand_gallery')
          .delete()
          .eq('id', galleryItemId);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> updateBrandGalleryItem(String galleryItemId, Map<String, dynamic> galleryData) async {
    try {
      final response = await client
          .from('brand_gallery')
          .update(galleryData)
          .eq('id', galleryItemId)
          .select()
          .single();
      
      return response;
    } catch (e) {
      return null;
    }
  }

  // Brand Stalls View methods
  Future<List<Map<String, dynamic>>> getBrandStalls(String brandId) async {
    try {
      final response = await client
          .from('brand_stalls_view')
          .select()
          .eq('brand_id', brandId)
          .order('application_created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBrandStallsByExhibition(String brandId, String exhibitionId) async {
    try {
      final response = await client
          .from('brand_stalls_view')
          .select()
          .eq('brand_id', brandId)
          .eq('exhibition_id', exhibitionId)
          .order('application_created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getBrandStallsByStatus(String brandId, String applicationStatus) async {
    try {
      final response = await client
          .from('brand_stalls_view')
          .select()
          .eq('brand_id', brandId)
          .eq('application_status', applicationStatus)
          .order('application_created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> subscribeToBrandStalls(String brandId) {
    return client
        .from('brand_stalls_view')
        .stream(primaryKey: ['application_id'])
        .map((event) {
          final allData = List<Map<String, dynamic>>.from(event);
          // Filter by brand_id on the client side since streams don't support .eq()
          return allData.where((stall) => stall['brand_id'] == brandId).toList()
            ..sort((a, b) => (b['application_created_at'] ?? '').compareTo(a['application_created_at'] ?? ''));
        });
  }

  Stream<List<Map<String, dynamic>>> subscribeToBrandStallsByExhibition(String brandId, String exhibitionId) {
    return client
        .from('brand_stalls_view')
        .stream(primaryKey: ['application_id'])
        .map((event) {
          final allData = List<Map<String, dynamic>>.from(event);
          // Filter by brand_id and exhibition_id on the client side
          return allData.where((stall) => 
            stall['brand_id'] == brandId && stall['exhibition_id'] == exhibitionId
          ).toList()
            ..sort((a, b) => (b['application_created_at'] ?? '').compareTo(a['application_created_at'] ?? ''));
        });
  }

  // Payment History methods
  Future<List<Map<String, dynamic>>> getPaymentHistory({String? organizerId}) async {
    try {
      var query = client
          .from('stall_applications')
          .select('''
            id,
            created_at,
            updated_at,
            status,
            payment_status,
            payment_amount,
            payment_date,
            payment_method,
            transaction_id,
            exhibition:exhibitions!stall_applications_exhibition_id_fkey(
              id,
              title,
              start_date,
              end_date
            ),
            brand:profiles!stall_applications_brand_id_fkey(
              id,
              company_name,
              full_name,
              email
            )
          ''')
          .inFilter('status', ['approved', 'booked'])
          .not('payment_status', 'is', null);

      if (organizerId != null) {
        query = query.eq('exhibition.organiser_id', organizerId);
      }

      final response = await query.order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getPaymentDetails(String applicationId) async {
    try {
      final response = await client
          .from('stall_applications')
          .select('''
            id,
            created_at,
            updated_at,
            status,
            payment_status,
            payment_amount,
            payment_date,
            payment_method,
            transaction_id,
            payment_notes,
            exhibition:exhibitions!stall_applications_exhibition_id_fkey(
              id,
              title,
              start_date,
              end_date,
              address,
              city,
              state,
              country
            ),
            brand:profiles!stall_applications_brand_id_fkey(
              id,
              company_name,
              full_name,
              email,
              phone
            ),
            stall:stalls(
              id,
              name,
              description,
              price
            )
          ''')
          .eq('id', applicationId)
          .single();
      
      return response;
    } catch (e) {
      return null;
    }
  }

  // Brand Profiles methods (for organizers)
  Future<List<Map<String, dynamic>>> getBrandProfiles({String? organizerId}) async {
    try {
      var query = client
          .from('profiles')
          .select('''
            id,
            company_name,
            full_name,
            email,
            phone,
            website,
            industry,
            location,
            description,
            avatar_url,
            created_at,
            updated_at,
            applications:stall_applications!stall_applications_brand_id_fkey(
              id,
              status,
              created_at,
              exhibition:exhibitions!stall_applications_exhibition_id_fkey(
                id,
                title,
                organiser_id
              )
            )
          ''')
          .eq('role', 'brand');

      if (organizerId != null) {
        query = query.eq('applications.exhibition.organiser_id', organizerId);
      }

      final response = await query.order('created_at', ascending: false);
      final brands = List<Map<String, dynamic>>.from(response);

      // Process the data to get application counts
      return brands.map((brand) {
        final applications = List<Map<String, dynamic>>.from(brand['applications'] ?? []);
        final totalApplications = applications.length;
        final approvedApplications = applications.where((app) => app['status'] == 'approved').length;
        final pendingApplications = applications.where((app) => app['status'] == 'pending').length;

        return {
          ...brand,
          'total_applications': totalApplications,
          'approved_applications': approvedApplications,
          'pending_applications': pendingApplications,
          'last_activity': applications.isNotEmpty 
              ? applications.first['created_at'] 
              : brand['created_at'],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }

  // Analytics methods
  Future<Map<String, dynamic>> getAnalyticsData({String? organizerId, String period = 'month'}) async {
    try {
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final userId = organizerId ?? currentUser.id;
      final now = DateTime.now();
      DateTime startDate;

      switch (period) {
        case 'week':
          startDate = now.subtract(Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'quarter':
          startDate = DateTime(now.year, now.month - 3, now.day);
          break;
        case 'year':
          startDate = DateTime(now.year - 1, now.month, now.day);
          break;
        default:
          startDate = DateTime(now.year, now.month - 1, now.day);
      }

      // Get exhibitions data
      final exhibitionsResponse = await client
          .from('exhibitions')
          .select('id, status, created_at')
          .eq('organiser_id', userId)
          .gte('created_at', startDate.toIso8601String());

      // Get applications data
      final applicationsResponse = await client
          .from('stall_applications')
          .select('''
            id,
            status,
            payment_status,
            payment_amount,
            created_at,
            exhibition:exhibitions!stall_applications_exhibition_id_fkey(
              organiser_id
            )
          ''')
          .eq('exhibition.organiser_id', userId)
          .gte('created_at', startDate.toIso8601String());

      final exhibitions = List<Map<String, dynamic>>.from(exhibitionsResponse);
      final applications = List<Map<String, dynamic>>.from(applicationsResponse);

      // Calculate analytics
      final totalExhibitions = exhibitions.length;
      final activeExhibitions = exhibitions.where((e) => e['status'] == 'published').length;
      final totalApplications = applications.length;
      final approvedApplications = applications.where((a) => a['status'] == 'approved').length;
      final pendingApplications = applications.where((a) => a['status'] == 'pending').length;
      final totalRevenue = applications
          .where((a) => a['payment_status'] == 'completed')
          .fold(0.0, (sum, app) => sum + (app['payment_amount'] ?? 0.0));

      return {
        'total_exhibitions': totalExhibitions,
        'active_exhibitions': activeExhibitions,
        'total_applications': totalApplications,
        'approved_applications': approvedApplications,
        'pending_applications': pendingApplications,
        'total_revenue': totalRevenue,
        'period': period,
        'start_date': startDate.toIso8601String(),
        'end_date': now.toIso8601String(),
      };
    } catch (e) {
      return {
        'total_exhibitions': 0,
        'active_exhibitions': 0,
        'total_applications': 0,
        'approved_applications': 0,
        'pending_applications': 0,
        'total_revenue': 0.0,
        'period': period,
        'start_date': '',
        'end_date': '',
      };
    }
  }

  // Reports methods
  Future<List<Map<String, dynamic>>> getReports({String? organizerId}) async {
    try {
      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final userId = organizerId ?? currentUser.id;

      // Get exhibitions with application counts
      final exhibitionsResponse = await client
          .from('exhibitions')
          .select('''
            id,
            title,
            start_date,
            end_date,
            status,
            created_at,
            applications:stall_applications!stall_applications_exhibition_id_fkey(
              id,
              status,
              payment_status,
              payment_amount
            )
          ''')
          .eq('organiser_id', userId)
          .order('created_at', ascending: false);

      final exhibitions = List<Map<String, dynamic>>.from(exhibitionsResponse);

      return exhibitions.map((exhibition) {
        final applications = List<Map<String, dynamic>>.from(exhibition['applications'] ?? []);
        final totalApplications = applications.length;
        final approvedApplications = applications.where((app) => app['status'] == 'approved').length;
        final totalRevenue = applications
            .where((app) => app['payment_status'] == 'completed')
            .fold(0.0, (sum, app) => sum + (app['payment_amount'] ?? 0.0));

        return {
          'exhibition_id': exhibition['id'],
          'exhibition_title': exhibition['title'],
          'start_date': exhibition['start_date'],
          'end_date': exhibition['end_date'],
          'status': exhibition['status'],
          'total_applications': totalApplications,
          'approved_applications': approvedApplications,
          'total_revenue': totalRevenue,
          'created_at': exhibition['created_at'],
        };
      }).toList();
    } catch (e) {
      return [];
    }
  }



  // Gallery Images methods
  Future<List<Map<String, dynamic>>> getGalleryImages(String exhibitionId) async {
    try {
      final response = await client
          .from('gallery_images')
          .select('id, image_url, image_type, created_at, updated_at')
          .eq('exhibition_id', exhibitionId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> createGalleryImage({
    required String exhibitionId,
    required String imageUrl,
    required String imageType,
  }) async {
    try {
      final response = await client
          .from('gallery_images')
          .insert({
            'exhibition_id': exhibitionId,
            'image_url': imageUrl,
            'image_type': imageType,
          })
          .select()
          .single();
      
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<bool> deleteGalleryImage(String imageId) async {
    try {
      await client
          .from('gallery_images')
          .delete()
          .eq('id', imageId);
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Exhibition creation with complete data
  Future<Map<String, dynamic>?> createExhibitionWithCompleteData({
    required Map<String, dynamic> exhibitionData,
    required List<Map<String, dynamic>> stalls,
    required List<Map<String, dynamic>> galleryImages,
    List<String>? exhibitionAmenities,
  }) async {
    try {
      // Create the exhibition first
      final exhibitionResponse = await client
          .from('exhibitions')
          .insert(exhibitionData)
          .select()
          .single();

      final exhibitionId = exhibitionResponse['id'] as String;

      // Create stalls and their instances
      if (stalls.isNotEmpty) {
        for (final stall in stalls) {
          final stallAmenities = stall.remove('amenities') as List<dynamic>? ?? [];
          final quantity = stall['quantity'] as int? ?? 1;
          
          print('Creating stall: ${stall['name']} with quantity: $quantity');
          
          // Create the stall
          final stallResponse = await client
              .from('stalls')
              .insert({
                ...stall,
                'quantity': quantity, // Ensure quantity is explicitly included
                'exhibition_id': exhibitionId,
              })
              .select()
              .single();
          
          final stallId = stallResponse['id'] as String;
          print('Created stall with ID: $stallId');
          
          // Create individual stall instances based on quantity
          final List<Map<String, dynamic>> stallInstances = [];
          for (int i = 0; i < quantity; i++) {
            final instanceData = {
              'stall_id': stallId,
              'exhibition_id': exhibitionId,
              'instance_number': i + 1,
              'status': 'available',
              'price': stall['price'] ?? 0.0,
              'original_price': stall['price'] ?? 0.0,
            };
            stallInstances.add(instanceData);
          }
          
          // Insert all stall instances for this stall type
          if (stallInstances.isNotEmpty) {
            await client
                .from('stall_instances')
                .insert(stallInstances);
            print('Created ${stallInstances.length} instances for stall: ${stall['name']}');
          }
          
          // Create stall amenities
          if (stallAmenities.isNotEmpty) {
            final amenityData = stallAmenities.map((amenityId) => {
              'stall_id': stallId,
              'amenity_id': amenityId,
            }).toList();
            
            await client
                .from('stall_amenities')
                .insert(amenityData);
            print('Added ${amenityData.length} amenities to stall: ${stall['name']}');
          }
        }
      }

      // Insert gallery images if any
      if (galleryImages.isNotEmpty) {
        final galleryImagesData = galleryImages.map((image) => {
          ...image,
          'exhibition_id': exhibitionId,
        }).toList();

        await client
            .from('gallery_images')
            .insert(galleryImagesData);
      }

      // Handle exhibition-level amenities if any
      if (exhibitionAmenities != null && exhibitionAmenities.isNotEmpty) {
        // Note: For now, we'll store exhibition amenities in a separate table
        // You may need to create an exhibition_amenities table or store as JSON in exhibitions
        print('Exhibition amenities selected: $exhibitionAmenities');
        // TODO: Implement proper storage for exhibition-level amenities
      }

      // Generate and update stall instance layout
      if (stalls.isNotEmpty) {
        final layout = await generateStallLayout(
          exhibitionId: exhibitionId,
          stalls: stalls,
        );
        
        // Update stall instances with layout positions
        for (final layoutItem in layout) {
          await client
              .from('stall_instances')
              .update({
                'position_x': layoutItem['position_x'],
                'position_y': layoutItem['position_y'],
                'rotation_angle': layoutItem['rotation_angle'],
              })
              .eq('stall_id', layoutItem['stall_id'])
              .eq('instance_number', layoutItem['instance_number']);
        }
      }

      return exhibitionResponse;
    } catch (e) {
      print('Error creating exhibition with complete data: $e');
      return null;
    }
  }

  // Get stall instances for an exhibition
  Future<List<Map<String, dynamic>>> getStallInstances(String exhibitionId) async {
    final response = await client
        .from('stall_instances')
        .select('''
          *,
          stall:stalls(
            *,
            unit:measurement_units(*)
          )
        ''')
        .eq('exhibition_id', exhibitionId)
        .order('instance_number', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
  }

  // Generate layout for stall instances
  Future<List<Map<String, dynamic>>> generateStallLayout({
    required String exhibitionId,
    required List<Map<String, dynamic>> stalls,
    double spacing = 20.0,
    double margin = 50.0,
  }) async {
    try {
      List<Map<String, dynamic>> layout = [];
      double currentX = margin;
      double currentY = margin;
      double maxHeightInRow = 0;
      double totalWidth = 800.0; // Assuming a standard layout width
      
      for (final stall in stalls) {
        final quantity = stall['quantity'] as int? ?? 1;
        final length = (stall['length'] as num?)?.toDouble() ?? 0.0;
        final width = (stall['width'] as num?)?.toDouble() ?? 0.0;
        
        for (int i = 0; i < quantity; i++) {
          // Check if we need to move to next row
          if (currentX + length > totalWidth - margin) {
            currentX = margin;
            currentY += maxHeightInRow + spacing;
            maxHeightInRow = 0;
          }
          
          layout.add({
            'stall_id': stall['id'],
            'exhibition_id': exhibitionId,
            'instance_number': i + 1,
            'position_x': currentX,
            'position_y': currentY,
            'rotation_angle': 0.0,
            'status': 'available',
            'length': length,
            'width': width,
            'stall_name': stall['name'],
            'price': stall['price'],
          });
          
          currentX += length + spacing;
          maxHeightInRow = maxHeightInRow < width ? width : maxHeightInRow;
        }
      }
      
      return layout;
    } catch (e) {
      print('Error generating stall layout: $e');
      return [];
    }
  }

  // Get stall instances with layout information
  Future<List<Map<String, dynamic>>> getStallInstancesWithLayout(String exhibitionId) async {
    try {
      final response = await client
          .from('stall_instances')
          .select('''
            *,
            stall:stalls!stall_instances_stall_id_fkey(
              id,
              name,
              length,
              width,
              price,
              unit:measurement_units!stalls_unit_id_fkey(
                id,
                name,
                symbol
              )
            )
          ''')
          .eq('exhibition_id', exhibitionId)
          .order('position_x', ascending: true)
          .order('position_y', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting stall instances with layout: $e');
      return [];
    }
  }

  // Get all states
  Future<List<Map<String, dynamic>>> getStates() async {
    try {
      final response = await client
          .from('states')
          .select('id, name, state_code, latitude, longitude')
          .order('name', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting states: $e');
      return [];
    }
  }

  // Get cities by state ID
  Future<List<Map<String, dynamic>>> getCitiesByState(String stateId) async {
    try {
      final response = await client
          .from('cities')
          .select('id, name, state_id, latitude, longitude, is_major, population')
          .eq('state_id', stateId)
          .order('is_major', ascending: false) // Major cities first
          .order('name', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting cities by state: $e');
      return [];
    }
  }

  // Get cities by state name
  Future<List<Map<String, dynamic>>> getCitiesByStateName(String stateName) async {
    try {
      final response = await client
          .from('cities')
          .select('''
            id, 
            name, 
            state_id, 
            latitude, 
            longitude, 
            is_major, 
            population,
            state:states!cities_state_id_fkey(name, state_code)
          ''')
          .eq('state.name', stateName)
          .order('is_major', ascending: false) // Major cities first
          .order('name', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting cities by state name: $e');
      return [];
    }
  }

  // Get major cities
  Future<List<Map<String, dynamic>>> getMajorCities() async {
    try {
      final response = await client
          .from('cities')
          .select('''
            id, 
            name, 
            state_id, 
            latitude, 
            longitude, 
            is_major, 
            population,
            state:states!cities_state_id_fkey(name, state_code)
          ''')
          .eq('is_major', true)
          .order('population', ascending: false) // Most populated first
          .order('name', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting major cities: $e');
      return [];
    }
  }

  // Get organizer bank details
  Future<List<Map<String, dynamic>>> getOrganizerBankDetails(String organizerId) async {
    try {
      final response = await client
          .from('organiser_bank_details')
          .select('''
            id,
            created_at,
            updated_at,
            organiser_id,
            bank_name,
            account_number,
            ifsc_code,
            account_holder_name,
            is_active
          ''')
          .eq('organiser_id', organizerId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting organizer bank details: $e');
      return [];
    }
  }

  // Get organizer UPI details
  Future<List<Map<String, dynamic>>> getOrganizerUPIDetails(String organizerId) async {
    try {
      final response = await client
          .from('organiser_upi_details')
          .select('''
            id,
            created_at,
            updated_at,
            organiser_id,
            upi_id,
            is_active
          ''')
          .eq('organiser_id', organizerId)
          .eq('is_active', true)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting organizer UPI details: $e');
      return [];
    }
  }

  // Get organizer payment details (both bank and UPI)
  Future<Map<String, dynamic>> getOrganizerPaymentDetails(String organizerId) async {
    try {
      final bankDetails = await getOrganizerBankDetails(organizerId);
      final upiDetails = await getOrganizerUPIDetails(organizerId);
      
      return {
        'bank_details': bankDetails,
        'upi_details': upiDetails,
      };
    } catch (e) {
      print('Error getting organizer payment details: $e');
      return {
        'bank_details': [],
        'upi_details': [],
      };
    }
  }

  // Get brand favorites (shoppers who marked brand as favorite)
  Future<List<Map<String, dynamic>>> getBrandFavorites(String brandId) async {
    try {
      final response = await client
          .from('brand_favorites')
          .select('''
            id,
            created_at,
            updated_at,
            user:user_id(
              id,
              email,
              profiles!user_id(
                id,
                full_name,
                avatar_url,
                role
              )
            )
          ''')
          .eq('brand_id', brandId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting brand favorites: $e');
      return [];
    }
  }

  // Get brand followers count
  Future<int> getBrandFollowersCount(String brandId) async {
    try {
      final response = await client
          .from('brand_favorites')
          .select('id')
          .eq('brand_id', brandId);
      
      return response.length;
    } catch (e) {
      print('Error getting brand followers count: $e');
      return 0;
    }
  }

  // Get brand followers with pagination
  Future<Map<String, dynamic>> getBrandFollowers(String brandId, {int page = 0, int limit = 10}) async {
    try {
      final offset = page * limit;
      
      final response = await client
          .from('brand_favorites')
          .select('''
            id,
            created_at,
            updated_at,
            user:user_id(
              id,
              email,
              profiles!user_id(
                id,
                full_name,
                avatar_url,
                role,
                company_name
              )
            )
          ''')
          .eq('brand_id', brandId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);
      
      // Get total count
      final allFollowers = await client
          .from('brand_favorites')
          .select('id')
          .eq('brand_id', brandId);
      
      final totalCount = allFollowers.length;
      
      return {
        'followers': response,
        'total_count': totalCount,
        'has_more': (offset + limit) < totalCount,
      };
    } catch (e) {
      print('Error getting brand followers: $e');
      return {
        'followers': [],
        'total_count': 0,
        'has_more': false,
      };
    }
  }

  // Manual method to create lookbooks bucket with proper configuration
  Future<bool> createLookbooksBucket() async {
    try {
      print('Creating lookbooks bucket...'); // Debug log
      
      // Check if bucket already exists
      final exists = await checkStorageBucketExists('lookbooks');
      if (exists) {
        print('Lookbooks bucket already exists'); // Debug log
        return true;
      }
      
      // Create the bucket with proper configuration
      await client.storage.createBucket(
        'lookbooks',
        BucketOptions(
          public: true,
          allowedMimeTypes: [
            'application/pdf',
            'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'application/vnd.ms-powerpoint',
            'application/vnd.openxmlformats-officedocument.presentationml.presentation',
            'application/vnd.ms-excel',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'image/jpeg',
            'image/png',
            'image/gif',
            'video/mp4',
            'video/quicktime',
            'video/x-msvideo',
            'application/octet-stream'
          ],
          fileSizeLimit: '52428800', // 50MB as string
        ),
      );
      
      print('Lookbooks bucket created successfully'); // Debug log
      return true;
    } catch (e) {
      print('Error creating lookbooks bucket: $e'); // Debug log
      return false;
    }
  }

  // Create brand-specific storage bucket for lookbooks
  Future<bool> createBrandLookbookBucket(String brandId) async {
    try {
      print('Creating brand-specific lookbook bucket for brand: $brandId'); // Debug log
      
      final bucketName = 'lookbooks'; // Use shared bucket
      
      // Check if bucket already exists
      final exists = await checkStorageBucketExists(bucketName);
      if (exists) {
        print('Lookbooks bucket already exists: $bucketName'); // Debug log
        return true;
      }
      
      // Create the bucket with proper configuration
      await client.storage.createBucket(
        bucketName,
        BucketOptions(
          public: true,
          allowedMimeTypes: [
            'application/pdf',
            'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'application/vnd.ms-powerpoint',
            'application/vnd.openxmlformats-officedocument.presentationml.presentation',
            'application/vnd.ms-excel',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            'image/jpeg',
            'image/png',
            'image/gif',
            'video/mp4',
            'video/quicktime',
            'video/x-msvideo',
            'application/octet-stream'
          ],
          fileSizeLimit: '52428800', // 50MB as string
        ),
      );
      
      print('Lookbooks bucket created successfully: $bucketName'); // Debug log
      return true;
    } catch (e) {
      print('Error creating lookbooks bucket: $e'); // Debug log
      return false;
    }
  }

  // Get bucket name (shared bucket)
  String getBrandLookbookBucketName(String brandId) {
    return 'lookbooks'; // Use shared bucket
  }

  // Check if lookbooks bucket exists
  Future<bool> checkBrandLookbookBucketExists(String brandId) async {
    final bucketName = getBrandLookbookBucketName(brandId);
    return await checkStorageBucketExists(bucketName);
  }

  // Create brand profile with automatic storage bucket creation
  Future<Map<String, dynamic>?> createBrandProfileWithStorage(Map<String, dynamic> brandData) async {
    try {
      print('Creating brand profile with automatic storage setup...'); // Debug log
      
      // First create the brand profile
      final brandResponse = await client
          .from('profiles')
          .insert(brandData)
          .select()
          .single();
      
      if (brandResponse != null) {
        final brandId = brandResponse['id'];
        print('Brand profile created with ID: $brandId'); // Debug log
        
        // Automatically create brand-specific storage bucket
        final bucketCreated = await createBrandLookbookBucket(brandId);
        print('Brand storage bucket creation result: $bucketCreated'); // Debug log
        
        if (bucketCreated) {
          print('Brand onboarding completed successfully with storage setup'); // Debug log
        } else {
          print('Warning: Brand profile created but storage bucket creation failed'); // Debug log
        }
        
        return brandResponse;
      }
      
      return null;
    } catch (e) {
      print('Error creating brand profile with storage: $e'); // Debug log
      return null;
    }
  }

  // Update brand profile with storage bucket check
  Future<Map<String, dynamic>?> updateBrandProfileWithStorage(String brandId, Map<String, dynamic> brandData) async {
    try {
      print('Updating brand profile with storage check...'); // Debug log
      
      // Update the brand profile
      final brandResponse = await client
          .from('profiles')
          .update(brandData)
          .eq('id', brandId)
          .select()
          .single();
      
      if (brandResponse != null) {
        // Ensure brand-specific storage bucket exists
        final bucketExists = await checkBrandLookbookBucketExists(brandId);
        if (!bucketExists) {
          print('Creating missing brand storage bucket for brand: $brandId'); // Debug log
          await createBrandLookbookBucket(brandId);
        }
        
        return brandResponse;
      }
      
      return null;
    } catch (e) {
      print('Error updating brand profile with storage: $e'); // Debug log
      return null;
    }
  }

  // Ensure brand folder exists in lookbooks bucket
  Future<bool> ensureBrandFolderExists(String brandId) async {
    try {
      print('Ensuring brand folder exists for brand: $brandId'); // Debug log
      
      final bucketName = 'lookbooks';
      final folderPath = '$brandId/.folder_placeholder';
      
      // Check if brand folder already exists
      try {
        final files = await client.storage
            .from(bucketName)
            .list(path: brandId);
        
        print('Brand folder check result: ${files.length} files found'); // Debug log
        
        // If folder exists and has files, we're good
        if (files.isNotEmpty) {
          print('Brand folder already exists'); // Debug log
          return true;
        }
      } catch (e) {
        print('Error checking brand folder: $e'); // Debug log
        // Folder might not exist, continue to create it
      }
      
      // Create brand folder by uploading a placeholder file
      print('Creating brand folder placeholder...'); // Debug log
      await client.storage
          .from(bucketName)
          .uploadBinary(
            folderPath,
            Uint8List.fromList([0]), // Empty file
            fileOptions: FileOptions(
              contentType: 'application/octet-stream',
              metadata: {'placeholder': 'true', 'brand_id': brandId},
            ),
          );
      
      print('Brand folder created successfully'); // Debug log
      return true;
    } catch (e) {
      print('Error ensuring brand folder exists: $e'); // Debug log
      return false;
    }
  }

  // List files in a brand's lookbook folder
  Future<List<String>> listBrandLookbookFiles(String brandId) async {
    try {
      print('Listing files for brand: $brandId'); // Debug log
      
      final bucketName = 'lookbooks';
      final files = await client.storage
          .from(bucketName)
          .list(path: brandId);
      
      final fileNames = files.map((file) => file.name).toList();
      print('Found ${fileNames.length} files for brand $brandId: $fileNames'); // Debug log
      
      return fileNames;
    } catch (e) {
      print('Error listing brand lookbook files: $e'); // Debug log
      return [];
    }
  }

  // Get current user's brand ID
  String? getCurrentUserBrandId() {
    final user = currentUser;
    if (user == null) return null;
    
    // For now, return the user ID as brand ID
    // In a real app, you might want to fetch this from the profiles table
    return user.id;
  }

  // Check if current user has storage permissions
  Future<bool> checkStoragePermissions() async {
    try {
      print('Checking storage permissions for user: ${currentUser?.id}');
      
      // First check if user is authenticated
      if (currentUser == null) {
        print('No authenticated user found');
        return false;
      }

      // Try to list buckets to check permissions
      // This is a lightweight operation that should work if we have network connectivity
      final buckets = await client.storage.listBuckets();
      print('Successfully listed ${buckets.length} storage buckets');
      
      return true;
    } catch (e) {
      print('Storage permission check failed: $e');
      
      // Check if it's a network connectivity issue
      if (e.toString().contains('Failed host lookup') || 
          e.toString().contains('No address associated with hostname') ||
          e.toString().contains('SocketException') ||
          e.toString().contains('Network is unreachable')) {
        print('Network connectivity issue detected - this is not a permissions problem');
        // Return true for network issues since permissions might be fine
        // The actual upload will fail if there are real permission issues
        return true;
      }
      
      // For other errors, assume it might be a permissions issue
      return false;
    }
  }

  // Create a storage bucket if it doesn't exist
  Future<bool> createStorageBucket(String bucketName, {bool isPublic = false}) async {
    try {
      print('Attempting to create storage bucket: $bucketName');
      
      // First check if bucket already exists
      final bucketExists = await checkStorageBucketExists(bucketName);
      if (bucketExists) {
        print('Bucket $bucketName already exists, skipping creation');
        return true;
      }
      
      print('Creating bucket with options: public=$isPublic');
      
      final bucketOptions = BucketOptions(
        public: isPublic,
        allowedMimeTypes: [
          'application/pdf',
          'application/msword',
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
          'application/vnd.ms-powerpoint',
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
          'application/vnd.ms-excel',
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          'image/jpeg',
          'image/png',
          'image/gif',
          'video/mp4',
          'video/quicktime',
          'video/x-msvideo',
          'application/octet-stream'
        ],
        fileSizeLimit: '52428800', // 50MB
      );
      
      await client.storage.createBucket(bucketName, bucketOptions);
      print('Successfully created storage bucket: $bucketName');
      return true;
    } catch (e) {
      print('Error creating storage bucket $bucketName: $e');
      
      // If bucket creation fails, check if it already exists (might have been created by another process)
      try {
        final bucketExists = await checkStorageBucketExists(bucketName);
        if (bucketExists) {
          print('Bucket $bucketName exists after failed creation attempt - continuing');
          return true;
        }
      } catch (checkError) {
        print('Error checking bucket existence: $checkError');
      }
      
      return false;
    }
  }

  // Check network connectivity to Supabase
  Future<bool> checkNetworkConnectivity() async {
    try {
      print('Checking network connectivity to Supabase...');
      
      // Try a simple operation that requires network
      await client.storage.listBuckets();
      print('✓ Network connectivity confirmed');
      return true;
    } catch (e) {
      print('✗ Network connectivity failed: $e');
      return false;
    }
  }

  /// Create lookbooks bucket directly through Supabase client
  Future<bool> createLookbooksBucketDirectly() async {
    try {
      print('Attempting to create lookbooks bucket directly...');
      
      // First check if bucket already exists
      try {
        final buckets = await client.storage.listBuckets();
        final exists = buckets.any((bucket) => bucket.id == 'lookbooks');
        if (exists) {
          print('✓ Lookbooks bucket already exists');
          return true;
        }
      } catch (checkError) {
        print('Error checking bucket existence: $checkError');
      }
      
      // Try to create the bucket directly
      await client.storage.createBucket('lookbooks');
      
      print('✓ Lookbooks bucket created successfully through client');
      return true;
    } catch (e) {
      print('Error creating lookbooks bucket directly: $e');
      
      // If it's a permission error, try a different approach
      if (e.toString().contains('403') || e.toString().contains('Unauthorized')) {
        print('Permission error detected - trying alternative approach...');
        
        // Try to create bucket with minimal options
        try {
          await client.storage.createBucket('lookbooks');
          print('✓ Lookbooks bucket created with minimal options');
          return true;
        } catch (simpleError) {
          print('Simple bucket creation also failed: $simpleError');
        }
      }
      
      // Final check - maybe bucket was created by someone else
      try {
        final buckets = await client.storage.listBuckets();
        final exists = buckets.any((bucket) => bucket.id == 'lookbooks');
        if (exists) {
          print('✓ Lookbooks bucket exists after all attempts');
          return true;
        }
      } catch (finalCheckError) {
        print('Final check failed: $finalCheckError');
      }
      
      return false;
    }
  }

  // Check if a brand is favorited by a user
  Future<bool> isBrandFavorited(String userId, String brandId) async {
    try {
      final result = await client
          .from('brand_favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('brand_id', brandId)
          .maybeSingle();
      
      return result != null;
    } catch (e) {
      print('Error checking brand favorite status: $e');
      return false;
    }
  }

  // Toggle brand favorite status
  Future<void> toggleBrandFavorite(String userId, String brandId) async {
    try {
      final isFavorited = await isBrandFavorited(userId, brandId);
      
      if (isFavorited) {
        // Remove from favorites
        await client
            .from('brand_favorites')
            .delete()
            .eq('user_id', userId)
            .eq('brand_id', brandId);
        print('Brand removed from favorites');
      } else {
        // Add to favorites
        await client
            .from('brand_favorites')
            .insert({
              'user_id': userId,
              'brand_id': brandId,
            });
        print('Brand added to favorites');
      }
    } catch (e) {
      print('Error toggling brand favorite: $e');
      throw Exception('Failed to update brand favorite: $e');
    }
  }

  // Get user's favorite brands
  Future<List<Map<String, dynamic>>> getUserFavoriteBrands(String userId) async {
    try {
      final response = await client
          .from('brand_favorites')
          .select('''
            id,
            created_at,
            brand:profiles(
              id,
              company_name,
              full_name,
              email,
              phone,
              description,
              avatar_url,
              role
            )
          ''')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting user favorite brands: $e');
      return [];
    }
  }
}
