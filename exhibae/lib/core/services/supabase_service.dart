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
      print('Starting signup for email: $email');
      
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: userData,
      );
      
      print('Signup response received: ${response.user?.email}');
      print('User ID: ${response.user?.id}');
      print('Email confirmed: ${response.user?.emailConfirmedAt}');
      print('Session: ${response.session}');
      
      // Check if the signup was successful
      if (response.user != null) {
        // Check if email confirmation is required
        if (response.user!.emailConfirmedAt == null) {
          // Email confirmation is required - this is expected
          print('Email confirmation required for: ${response.user!.email}');
          // The email should be sent automatically by Supabase
          // If it's not being sent, it might be a configuration issue in the Supabase dashboard
          // You need to:
          // 1. Go to Supabase Dashboard > Authentication > Settings
          // 2. Enable "Enable email confirmations"
          // 3. Configure an email provider (SendGrid, Mailgun, etc.)
          // 4. Make sure your email provider is properly configured
        } else {
          // Email is already confirmed (this shouldn't happen in normal flow)
          print('Email already confirmed for: ${response.user!.email}');
        }
        return response;
      } else {
        print('No user returned from signup');
        throw Exception('Signup failed: No user returned');
      }
    } catch (e) {
      print('Signup error: $e');
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
        .select('''
          *,
          created_by:profiles!measurement_units_created_by_fkey(
            id,
            email,
            full_name
          )
        ''');

    if (type != null) {
      query = query.eq('type', type);
    }
    
    final response = await query.order('name', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getMeasurementUnitById(String id) async {
    final response = await client
        .from('measurement_units')
        .select('''
          *,
          created_by:profiles!measurement_units_created_by_fkey(
            id,
            email,
            full_name
          )
        ''')
        .eq('id', id)
        .single();
    
    return response;
  }

  Future<Map<String, dynamic>?> getMeasurementUnitBySymbol(String symbol) async {
    final response = await client
        .from('measurement_units')
        .select('''
          *,
          created_by:profiles!measurement_units_created_by_fkey(
            id,
            email,
            full_name
          )
        ''')
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
        .select('''
          *,
          created_by:profiles!measurement_units_created_by_fkey(
            id,
            email,
            full_name
          )
        ''')
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
        .select('''
          *,
          created_by:profiles!measurement_units_created_by_fkey(
            id,
            email,
            full_name
          )
        ''')
        .single();
    
    return response;
  }

  // Amenities methods
  Future<List<Map<String, dynamic>>> getAmenities() async {
    final response = await client
        .from('amenities')
        .select()
        .order('name', ascending: true);
    
    return List<Map<String, dynamic>>.from(response);
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
        print('Updating stall instance $stallInstanceId status to pending');
        final updateResult = await client
            .from('stall_instances')
            .update({
              'status': 'pending',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', stallInstanceId)
            .select();
        
        print('Stall instance status update result: $updateResult');
      } catch (e) {
        // Log the error but don't fail the application creation
        print('Warning: Could not update stall instance status: $e');
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
      print('Syncing user role for user: ${user.id}');
      
      // Get role from profiles table
      final profile = await getUserProfile(user.id);
      final profileRole = profile?['role'] as String?;
      print('Profile role: $profileRole');
      
      // Get current metadata role
      final metadataRole = user.userMetadata?['role'] as String?;
      print('Current metadata role: $metadataRole');
      
      if (profileRole != null) {
        // If metadata role is different from profile role, update metadata
        if (metadataRole != profileRole) {
          print('Updating metadata role to match profile role: $profileRole');
          await client.auth.updateUser(UserAttributes(
            data: {
              ...user.userMetadata ?? {},
              'role': profileRole,
            },
          ));
          
          // Verify the update
          final updatedUser = await client.auth.getUser();
          print('Updated metadata role: ${updatedUser.user?.userMetadata?['role']}');
        }
      } else if (metadataRole != null) {
        // If profile role is missing but metadata has role, update profile
        print('Updating profile role to match metadata role: $metadataRole');
        await client
            .from('profiles')
            .update({'role': metadataRole})
            .eq('id', user.id);
      }
    } catch (e) {
      print('Error syncing user role: $e');
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
      print('Starting file upload to bucket: $bucket, path: $path');
      
      // Validate bucket exists
      try {
        await client.storage.getBucket(bucket);
        print('Bucket $bucket exists and is accessible');
      } catch (e) {
        print('Error accessing bucket $bucket: $e');
        throw Exception('Storage bucket "$bucket" does not exist or is not accessible');
      }
      
      if (fileBytes != null) {
        // Upload from bytes (Web platform)
        final fileOptions = FileOptions(
          contentType: contentType ?? 'application/octet-stream',
          upsert: true,
        );
        print('Uploading from bytes, size: ${fileBytes.length}');
        
        await client.storage
            .from(bucket)
            .uploadBinary(path, fileBytes, fileOptions: fileOptions);
        
        print('File uploaded successfully from bytes');
      } else if (filePath != null) {
        // Upload from file path (Mobile/Desktop platforms)
        final fileOptions = FileOptions(
          contentType: contentType ?? 'application/octet-stream',
          upsert: true,
        );
        print('Uploading from file path: $filePath');
        
        await client.storage
            .from(bucket)
            .upload(path, File(filePath), fileOptions: fileOptions);
        
        print('File uploaded successfully from file path');
      } else {
        throw Exception('Either fileBytes or filePath must be provided');
      }

      // Get the public URL for the uploaded file
      final publicUrl = client.storage.from(bucket).getPublicUrl(path);
      print('Generated public URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      print('Error uploading file: $e');
      print('Error details: ${e.toString()}');
      return null;
    }
  }

  String getPublicUrl(String bucket, String path) {
    final response = client.storage.from(bucket).getPublicUrl(path);
    return response;
  }

  // Test method to check if storage buckets exist
  Future<bool> checkStorageBucketExists(String bucketName) async {
    try {
      await client.storage.getBucket(bucketName);
      print('Storage bucket "$bucketName" exists and is accessible');
      return true;
    } catch (e) {
      print('Storage bucket "$bucketName" does not exist or is not accessible: $e');
      return false;
    }
  }

  // List all available storage buckets
  Future<List<String>> listStorageBuckets() async {
    try {
      final buckets = await client.storage.listBuckets();
      final bucketNames = buckets.map((bucket) => bucket.name).toList();
      print('Available storage buckets: $bucketNames');
      return bucketNames;
    } catch (e) {
      print('Error listing storage buckets: $e');
      return [];
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
    final response = await client
        .from('exhibition_favorites')
        .select('''
          *,
          exhibition:exhibitions!exhibition_favorites_exhibition_id_fkey(
            id,
            title,
            start_date,
            end_date,
            city,
            state,
            images
          )
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return List<Map<String, dynamic>>.from(response);
  }

  Future<bool> isExhibitionFavorited(String userId, String exhibitionId) async {
    try {
      final response = await client
          .from('exhibition_favorites')
          .select('id')
          .eq('user_id', userId)
          .eq('exhibition_id', exhibitionId)
          .maybeSingle();
      
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> toggleExhibitionFavorite(String userId, String exhibitionId) async {
    final isFavorited = await isExhibitionFavorited(userId, exhibitionId);
    
    if (isFavorited) {
      // Remove from favorites
      await client
          .from('exhibition_favorites')
          .delete()
          .eq('user_id', userId)
          .eq('exhibition_id', exhibitionId);
    } else {
      // Add to favorites
      await client
          .from('exhibition_favorites')
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
      print('Error fetching hero sliders: $e');
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
      print('Error fetching brand lookbooks: $e');
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

  Future<Map<String, dynamic>?> createBrandLookbook(Map<String, dynamic> lookbookData) async {
    try {
      print('Creating brand lookbook with data: $lookbookData');
      
      final response = await client
          .from('brand_lookbooks')
          .insert(lookbookData)
          .select()
          .single();
      
      print('Brand lookbook created successfully: ${response['id']}');
      return response;
    } catch (e) {
      print('Error creating brand lookbook: $e');
      print('Error details: ${e.toString()}');
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
      print('Error deleting brand lookbook: $e');
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
      print('Error updating brand lookbook: $e');
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
      print('Error fetching brand gallery: $e');
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
      print('Creating brand gallery item with data: $galleryData');
      
      final response = await client
          .from('brand_gallery')
          .insert(galleryData)
          .select()
          .single();
      
      print('Brand gallery item created successfully: ${response['id']}');
      return response;
    } catch (e) {
      print('Error creating brand gallery item: $e');
      print('Error details: ${e.toString()}');
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
      print('Error deleting brand gallery item: $e');
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
      print('Error updating brand gallery item: $e');
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
      print('Error fetching brand stalls: $e');
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
      print('Error fetching brand stalls by exhibition: $e');
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
      print('Error fetching brand stalls by status: $e');
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
}
