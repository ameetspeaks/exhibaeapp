import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/supabase_config.dart';
import '../config/whatsapp_config.dart';

class WhatsAppAuthService {
  static WhatsAppAuthService? _instance;
  static WhatsAppAuthService get instance => _instance ??= WhatsAppAuthService._internal();
  
  WhatsAppAuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Aisensy WhatsApp API configuration
  static const String _baseUrl = WhatsAppConfig.baseUrl;
  static const String _apiKey = WhatsAppConfig.apiKey;

  // Initialize Aisensy WhatsApp API
  Future<void> initialize() async {
    // Store API key securely
    await _secureStorage.write(key: 'aisensy_api_key', value: _apiKey);
  }

  // Send OTP via WhatsApp with database integration
  Future<Map<String, dynamic>> sendWhatsAppOtp({
    required String phoneNumber,
    String? userId,
    String verificationType = 'whatsapp_login',
  }) async {
    try {
      final formattedPhone = await _formatPhoneNumber(phoneNumber);
      
      // Check if this is a test user (bypass OTP and Aisensy API)
      if (_isTestUser(formattedPhone)) {
        // Create test OTP verification record
        final verificationResult = await _createTestPhoneVerification(
          userId: userId,
          phoneNumber: formattedPhone,
          verificationType: verificationType,
        );

        if (!verificationResult['success']) {
          return verificationResult;
        }

        final verificationId = verificationResult['verification_id'];
        
        return {
          'success': true,
          'message': 'Test OTP sent successfully (bypassed Aisensy API)',
          'expiresIn': 300, // 5 minutes
          'verificationId': verificationId,
          'is_test_user': true,
        };
      }
      
      // Check rate limiting
      final rateLimitCheck = await _checkRateLimit(formattedPhone);
      if (!rateLimitCheck['allowed']) {
        return {
          'success': false,
          'message': rateLimitCheck['message'],
          'retryAfter': rateLimitCheck['retryAfter'],
        };
      }

      // Create OTP verification in database
      final verificationResult = await _createPhoneVerification(
        userId: userId,
        phoneNumber: formattedPhone,
        verificationType: verificationType,
      );

      if (!verificationResult['success']) {
        return verificationResult;
      }

      final otpCode = verificationResult['otp_code'];
      final verificationId = verificationResult['verification_id'];

      // Send WhatsApp message
      final whatsappResult = await _sendWhatsAppMessage(formattedPhone, otpCode);
      
      // Log the message
      await _logWhatsAppMessage(
        phoneNumber: formattedPhone,
        messageType: 'otp_verification',
        messageId: whatsappResult['message_id'],
        status: whatsappResult['success'] ? 'sent' : 'failed',
        errorMessage: whatsappResult['error_message'],
      );

      if (whatsappResult['success']) {
        // Update verification record with WhatsApp message ID
        await _updateVerificationMessageId(verificationId, whatsappResult['message_id']);
        
        final result = {
          'success': true,
          'message': 'OTP sent successfully via WhatsApp',
          'expiresIn': 300, // 5 minutes
          'verificationId': verificationId,
        };
        return result;
      } else {
        return {
          'success': false,
          'message': 'Failed to send WhatsApp message: ${whatsappResult['error_message']}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error sending OTP: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }

  // Verify WhatsApp OTP with database integration
  Future<Map<String, dynamic>> verifyWhatsAppOtp({
    required String phoneNumber,
    required String otp,
    String? userId,
    String verificationType = 'whatsapp_login',
  }) async {
    try {
      final formattedPhone = await _formatPhoneNumber(phoneNumber);
      
      // Check if this is a test user (bypass normal OTP verification)
      if (_isTestUser(formattedPhone)) {
        // For test users, accept OTP 123456
        if (otp == '123456') {
          // Get user info for test user
          final userInfo = await _findUserByPhone(formattedPhone);
          if (userInfo != null) {
            return {
              'success': true,
              'message': 'Test OTP verified successfully',
              'phoneVerified': true,
              'user': userInfo,
              'is_test_user': true,
            };
          } else {
            return {
              'success': false,
              'message': 'Test user not found in database',
              'phoneVerified': false,
            };
          }
        } else {
          return {
            'success': false,
            'message': 'Invalid test OTP. Use 123456 for test users.',
            'phoneVerified': false,
          };
        }
      }
      
      // Verify OTP using database function
      final result = await _supabase.rpc('verify_otp', params: {
        'p_user_id': userId,
        'p_phone_number': formattedPhone,
        'p_otp_code': otp,
        'p_otp_type': verificationType,
      });

      if (result != null && result.isNotEmpty) {
        final success = result[0]['success'] as bool;
        final message = result[0]['message'] as String;
        final phoneVerified = result[0]['phone_verified'] as bool;
        final otpId = result[0]['verification_otp_id'] as String?; // Allow null
        final verifiedUserId = result[0]['user_id'] as String?; // Get the user ID if created
        
        if (success) {
          // Update phone verification status to verified (only if otpId is not null)
          if (otpId != null) {
            await _updatePhoneVerificationStatus(otpId, 'verified');
          }
          
          // Create or ensure profile exists for the user
          String finalUserId = userId ?? verifiedUserId ?? '';
          if (finalUserId.isNotEmpty) {
            await _ensureProfileExists(finalUserId, formattedPhone, verificationType);
          }
          
          // If this is a WhatsApp login, get user info and handle phone verification
          if (verificationType == 'whatsapp_login' && userId == null) {
            final userInfo = await _findUserByPhone(formattedPhone);
            if (userInfo != null) {
              // For WhatsApp login, we consider the phone verified if OTP is successful
              // and user exists, even if phone_verified was false in the database
              return {
                'success': true,
                'message': message,
                'phoneVerified': true, // Force to true for WhatsApp login
                'user': userInfo,
              };
            }
          }

          return {
            'success': true,
            'message': message,
            'phoneVerified': phoneVerified,
            'userId': finalUserId,
          };
        } else {
          // Update phone verification status to failed (only if otpId is not null)
          if (otpId != null) {
            await _updatePhoneVerificationStatus(otpId, 'failed');
          }
          
          return {
            'success': false,
            'message': message,
            'phoneVerified': false,
          };
        }
      }

      return {
        'success': false,
        'message': 'Verification failed',
        'phoneVerified': false,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error verifying OTP: ${e.toString()}',
        'phoneVerified': false,
      };
    }
  }

  // Check if user exists with verified phone number
  Future<Map<String, dynamic>?> findUserByPhone(String phoneNumber) async {
    try {
      final formattedPhone = await _formatPhoneNumber(phoneNumber);
      
      final result = await _supabase.rpc('find_user_by_phone', params: {
        'p_phone_number': formattedPhone,
      });

      if (result != null && result.isNotEmpty) {
        final userData = result[0];
        final userInfo = {
          'user_id': userData['user_id'],
          'phone_verified': userData['phone_verified'],
          'auth_provider': userData['auth_provider'],
        };
        return userInfo;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Check if WhatsApp is available for a phone number
  Future<bool> isWhatsAppAvailable(String phoneNumber) async {
    try {
      final formattedPhone = await _formatPhoneNumber(phoneNumber);
      
      // In production, you might want to use WhatsApp's Business Management API
      // to check if the number is registered with WhatsApp
      // For now, we'll assume all valid phone numbers can receive WhatsApp
      return true;
    } catch (e) {
      return false;
    }
  }

  // Get user's phone verification status
  Future<Map<String, dynamic>> getPhoneVerificationStatus(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('phone, phone_verified, phone_verified_at, whatsapp_enabled, auth_provider')
          .eq('id', userId)
          .single();

      return {
        'phone': response['phone'],
        'phone_verified': response['phone_verified'] ?? false,
        'phone_verified_at': response['phone_verified_at'],
        'whatsapp_enabled': response['whatsapp_enabled'] ?? false,
        'auth_provider': response['auth_provider'] ?? 'email',
      };
    } catch (e) {
      return {
        'phone': null,
        'phone_verified': false,
        'phone_verified_at': null,
        'whatsapp_enabled': false,
        'auth_provider': 'email',
      };
    }
  }

  // Update user's phone number
  Future<Map<String, dynamic>> updatePhoneNumber({
    required String userId,
    required String newPhoneNumber,
  }) async {
    try {
      final formattedPhone = await _formatPhoneNumber(newPhoneNumber);
      
      // Check if phone number is already verified by another user
      final existingUser = await findUserByPhone(formattedPhone);
      if (existingUser != null && existingUser['user_id'] != userId) {
        return {
          'success': false,
          'message': 'This phone number is already verified by another account',
        };
      }

      // Send OTP for phone update
      final otpResult = await sendWhatsAppOtp(
        phoneNumber: formattedPhone,
        userId: userId,
        verificationType: 'phone_update',
      );

      return otpResult;
    } catch (e) {
      return {
        'success': false,
        'message': 'Error updating phone number: ${e.toString()}',
      };
    }
  }

  // Test Aisensy API integration
  Future<Map<String, dynamic>> testAisensyApi(String phoneNumber) async {
    try {
      final formattedPhone = await _formatPhoneNumber(phoneNumber);
      final testOtp = '123456';
      
      final result = await _sendWhatsAppMessage(formattedPhone, testOtp);
      
      return result;
    } catch (e) {
      return {
        'success': false,
        'error_message': e.toString(),
      };
    }
  }

  // Private helper methods

  Future<String> _formatPhoneNumber(String phoneNumber) async {
    try {
      final parsed = PhoneNumber.parse(phoneNumber);
      return parsed.international ?? phoneNumber;
    } catch (e) {
      return phoneNumber;
    }
  }

  Future<Map<String, dynamic>> _checkRateLimit(String phoneNumber) async {
    try {
      // Check recent OTP requests in the last hour
      final oneHourAgo = DateTime.now().subtract(const Duration(hours: 1));
      
      final response = await _supabase
          .from('otp_verifications')
          .select('created_at')
          .eq('phone_number', phoneNumber)
          .eq('otp_type', 'whatsapp')
          .gte('created_at', oneHourAgo.toIso8601String())
          .order('created_at', ascending: false);

      final recentRequests = response.length;
      
      if (recentRequests >= 3) {
        // Find the oldest request to calculate retry time
        final oldestRequest = DateTime.parse(response.last['created_at']);
        final retryTime = oldestRequest.add(const Duration(hours: 1));
        final retryAfter = retryTime.difference(DateTime.now()).inSeconds;
        
        return {
          'allowed': false,
          'message': 'Too many OTP requests. Please try again later.',
          'retryAfter': retryAfter > 0 ? retryAfter : 0,
        };
      }

      return {'allowed': true};
    } catch (e) {
      return {'allowed': true}; // Allow if check fails
    }
  }

  Future<Map<String, dynamic>> _createPhoneVerification({
    String? userId,
    required String phoneNumber,
    required String verificationType,
  }) async {
    try {
      final result = await _supabase.rpc('create_otp_verification', params: {
        'p_user_id': userId,
        'p_phone_number': phoneNumber,
        'p_otp_type': verificationType,
      });

      if (result != null && result.isNotEmpty) {
        final data = result[0];
        final otpVerificationId = data['verification_id'];
        
        // Create phone verification record to track the process
        final phoneVerificationResult = await _supabase
            .from('phone_verifications')
            .insert({
              'user_id': userId,
              'phone_number': phoneNumber,
              'verification_type': verificationType,
              'otp_verification_id': otpVerificationId,
              'status': 'pending',
            })
            .select()
            .single();
        
        return {
          'success': true,
          'verification_id': phoneVerificationResult['verification_id'], // Return phone verification ID
          'otp_verification_id': otpVerificationId,
          'otp_code': data['otp_code'],
          'expires_at': data['expires_at'],
        };
      }

      return {
        'success': false,
        'message': 'Failed to create phone verification',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating verification: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> _sendWhatsAppMessage(String phoneNumber, String otp) async {
    try {
      // Prepare message template using config
      final message = WhatsAppConfig.getOtpMessageTemplate(phoneNumber, otp);

      // Send message via Aisensy API
      final response = await http.post(
        Uri.parse(WhatsAppConfig.messagesEndpoint),
        headers: WhatsAppConfig.apiHeaders,
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        
        // Aisensy API response format - handle multiple possible success indicators
        final success = responseData['status'] == 'success' || 
                       responseData['success'] == true || 
                       responseData['success'] == 'true' ||
                       responseData['submitted_message_id'] != null;
        
        final messageId = responseData['data']?['messageId'] ?? 
                         responseData['messageId'] ?? 
                         responseData['id'] ?? 
                         responseData['submitted_message_id'];
        final errorMessage = responseData['message'] ?? responseData['error'];
        
        if (success) {
          return {
            'success': true,
            'message_id': messageId ?? 'aisensy_${DateTime.now().millisecondsSinceEpoch}',
          };
        } else {
          return {
            'success': false,
            'error_message': errorMessage ?? 'Failed to send message via Aisensy',
          };
        }
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error_message': errorData['message'] ?? errorData['error'] ?? 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error_message': e.toString(),
      };
    }
  }

  Future<void> _logWhatsAppMessage({
    required String phoneNumber,
    required String messageType,
    String? messageId,
    String status = 'sent',
    String? errorMessage,
  }) async {
    try {
      await _supabase.rpc('log_whatsapp_message', params: {
        'p_phone_number': phoneNumber,
        'p_message_type': messageType,
        'p_message_id': messageId,
        'p_status': status,
        'p_error_message': errorMessage,
      });
    } catch (e) {
      // Silently handle logging errors
    }
  }

  Future<void> _updateVerificationMessageId(String verificationId, String messageId) async {
    try {
              await _supabase
            .from('phone_verifications')
            .update({
              'whatsapp_message_id': messageId,
              'status': 'sent',
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('verification_id', verificationId);
    } catch (e) {
      // Silently handle update errors
    }
  }

  Future<void> _updatePhoneVerificationStatus(String otpVerificationId, String status) async {
    try {
      await _supabase
          .from('phone_verifications')
          .update({
            'status': status,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('otp_verification_id', otpVerificationId);
    } catch (e) {
      // Silently handle update errors
    }
  }

  Future<Map<String, dynamic>?> _findUserByPhone(String phoneNumber) async {
    try {
      final result = await _supabase.rpc('find_user_by_phone', params: {
        'p_phone_number': phoneNumber,
      });

      if (result != null && result.isNotEmpty) {
        final userData = result[0];
        return {
          'user_id': userData['user_id'],
          'phone_verified': userData['phone_verified'],
          'auth_provider': userData['auth_provider'],
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Ensure profile exists for the user
  Future<void> _ensureProfileExists(String userId, String phoneNumber, String verificationType) async {
    try {
      
      // Check if profile already exists
      final existingProfile = await _supabase
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      
      if (existingProfile == null) {
        
        // Create a basic profile entry
        final profileData = {
          'id': userId,
          'phone': phoneNumber,
          'phone_verified': true,
          'phone_verified_at': DateTime.now().toIso8601String(),
          'whatsapp_enabled': true,
          'auth_provider': 'whatsapp',
          'role': 'shopper', // Default role, can be updated later
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
        
        // For registration, we'll create a temporary profile that will be updated later
        if (verificationType == 'registration') {
          profileData['full_name'] = 'User_${phoneNumber.replaceAll('+', '').replaceAll('-', '').replaceAll(' ', '')}';
          profileData['is_temp_profile'] = true; // Flag to indicate this is a temporary profile
        }
        
        await _supabase.from('profiles').insert(profileData);
      } else {
        
        // Update phone verification status if needed
        await _supabase
            .from('profiles')
            .update({
              'phone_verified': true,
              'phone_verified_at': DateTime.now().toIso8601String(),
              'whatsapp_enabled': true,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId);
      }
    } catch (e) {
      // Silently handle profile creation/update errors
    }
  }

  // Webhook verification for Aisensy API (if needed)
  Future<bool> verifyWebhook(String mode, String token, String challenge) async {
    final storedToken = await _secureStorage.read(key: 'aisensy_verify_token');
    
    if (mode == 'subscribe' && token == storedToken) {
      return true;
    }
    return false;
  }

  // Handle incoming webhook messages
  Future<void> handleWebhook(Map<String, dynamic> webhookData) async {
    try {
      // Handle incoming messages, status updates, etc.
      // This would be implemented based on your specific requirements
      
      // Update message status in logs if needed
      final entry = webhookData['entry']?[0]?['changes']?[0]?['value'];
      if (entry != null) {
        final messageId = entry['messages']?[0]?['id'];
        final status = entry['statuses']?[0]?['status'];
        
        if (messageId != null && status != null) {
          // Update message status in database
          await _updateMessageStatus(messageId, status);
        }
      }
    } catch (e) {
      // Silently handle webhook errors
    }
  }

  Future<void> _updateMessageStatus(String messageId, String status) async {
    try {
      await _supabase
          .from('whatsapp_message_logs')
          .update({'status': status})
          .eq('message_id', messageId);
    } catch (e) {
      // Silently handle update errors
    }
  }

  // Test user helper methods
  bool _isTestUser(String phoneNumber) {
    final testPhoneNumbers = [
      // Organizer (Savan) - both formats
      '+919670006261',
      '9670006261',
      // Brand (Raje)
      '+919670006262',
      '919670006262',
      // Shopper (meet)
      '+919670006263',
      '919670006263',
    ];
    return testPhoneNumbers.contains(phoneNumber);
  }

  Future<Map<String, dynamic>> _createTestPhoneVerification({
    String? userId,
    required String phoneNumber,
    required String verificationType,
  }) async {
    try {
      // Create a test OTP verification record
      final verificationData = {
        'otp_id': const Uuid().v4(),
        'user_id': userId,
        'phone_number': phoneNumber,
        'otp_code': '123456', // Fixed OTP for test users
        'otp_type': verificationType,
        'verified': false,
        'expires_at': DateTime.now().add(const Duration(minutes: 5)).toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('otp_verifications').insert(verificationData);
      
      return {
        'success': true,
        'verification_id': verificationData['otp_id'],
        'otp_code': '123456',
        'message': 'Test OTP verification created',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error creating test verification: ${e.toString()}',
      };
    }
  }
}
