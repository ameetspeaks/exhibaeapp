import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../config/whatsapp_config.dart';

class WhatsAppAuthService {
  static WhatsAppAuthService? _instance;
  static WhatsAppAuthService get instance => _instance ??= WhatsAppAuthService._internal();
  
  WhatsAppAuthService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // WhatsApp Business API configuration
  static const String _baseUrl = WhatsAppConfig.baseUrl;
  static const String _phoneNumberId = WhatsAppConfig.phoneNumberId;
  static const String _accessToken = WhatsAppConfig.accessToken;
  static const String _verifyToken = WhatsAppConfig.verifyToken;

  // Initialize WhatsApp Business API
  Future<void> initialize() async {
    // Store tokens securely
    await _secureStorage.write(key: 'whatsapp_phone_number_id', value: _phoneNumberId);
    await _secureStorage.write(key: 'whatsapp_access_token', value: _accessToken);
    await _secureStorage.write(key: 'whatsapp_verify_token', value: _verifyToken);
  }

  // Send OTP via WhatsApp with database integration
  Future<Map<String, dynamic>> sendWhatsAppOtp({
    required String phoneNumber,
    String? userId,
    String verificationType = 'whatsapp_login',
  }) async {
    try {
      // Format phone number to international format
      final formattedPhone = await _formatPhoneNumber(phoneNumber);
      
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
        
        return {
          'success': true,
          'message': 'OTP sent successfully via WhatsApp',
          'expiresIn': 300, // 5 minutes
          'verificationId': verificationId,
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to send WhatsApp message: ${whatsappResult['error_message']}',
        };
      }
    } catch (e) {
      print('Error sending WhatsApp OTP: $e');
      return {
        'success': false,
        'message': 'Error sending OTP: ${e.toString()}',
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
      
      // Verify OTP using database function
      final result = await _supabase.rpc('verify_phone_otp', params: {
        'p_user_id': userId,
        'p_phone_number': formattedPhone,
        'p_otp_code': otp,
        'p_verification_type': verificationType,
      });

      if (result != null && result.isNotEmpty) {
        final success = result[0]['success'] as bool;
        final message = result[0]['message'] as String;
        final phoneVerified = result[0]['phone_verified'] as bool;

        if (success && phoneVerified) {
          // If this is a WhatsApp login, get user info
          if (verificationType == 'whatsapp_login' && userId == null) {
            final userInfo = await _findUserByPhone(formattedPhone);
            if (userInfo != null) {
              return {
                'success': true,
                'message': message,
                'phoneVerified': phoneVerified,
                'user': userInfo,
              };
            }
          }

          return {
            'success': true,
            'message': message,
            'phoneVerified': phoneVerified,
          };
        } else {
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
      print('Error verifying WhatsApp OTP: $e');
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
        return {
          'user_id': userData['user_id'],
          'phone_verified': userData['phone_verified'],
          'auth_provider': userData['auth_provider'],
        };
      }
      return null;
    } catch (e) {
      print('Error finding user by phone: $e');
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
      print('Error getting phone verification status: $e');
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
      print('Error updating phone number: $e');
      return {
        'success': false,
        'message': 'Error updating phone number: ${e.toString()}',
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
          .from('phone_verifications')
          .select('created_at')
          .eq('phone_number', phoneNumber)
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
      print('Error checking rate limit: $e');
      return {'allowed': true}; // Allow if check fails
    }
  }

  Future<Map<String, dynamic>> _createPhoneVerification({
    String? userId,
    required String phoneNumber,
    required String verificationType,
  }) async {
    try {
      final result = await _supabase.rpc('create_phone_verification', params: {
        'p_user_id': userId,
        'p_phone_number': phoneNumber,
        'p_verification_type': verificationType,
      });

      if (result != null && result.isNotEmpty) {
        final data = result[0];
        return {
          'success': true,
          'verification_id': data['id'],
          'otp_code': data['otp_code'],
          'expires_at': data['expires_at'],
        };
      }

      return {
        'success': false,
        'message': 'Failed to create phone verification',
      };
    } catch (e) {
      print('Error creating phone verification: $e');
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

      // Send message via WhatsApp Business API
      final response = await http.post(
        Uri.parse(WhatsAppConfig.messagesEndpoint),
        headers: WhatsAppConfig.apiHeaders,
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final messageId = responseData['messages']?[0]?['id'];
        
        return {
          'success': true,
          'message_id': messageId,
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'error_message': errorData['error']?['message'] ?? 'Unknown error',
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
      print('Error logging WhatsApp message: $e');
    }
  }

  Future<void> _updateVerificationMessageId(String verificationId, String messageId) async {
    try {
      await _supabase
          .from('phone_verifications')
          .update({'whatsapp_message_id': messageId})
          .eq('id', verificationId);
    } catch (e) {
      print('Error updating verification message ID: $e');
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
      print('Error finding user by phone: $e');
      return null;
    }
  }

  // Webhook verification for WhatsApp Business API
  Future<bool> verifyWebhook(String mode, String token, String challenge) async {
    final storedToken = await _secureStorage.read(key: 'whatsapp_verify_token');
    
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
      print('Webhook received: $webhookData');
      
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
      print('Error handling webhook: $e');
    }
  }

  Future<void> _updateMessageStatus(String messageId, String status) async {
    try {
      await _supabase
          .from('whatsapp_message_logs')
          .update({'status': status})
          .eq('message_id', messageId);
    } catch (e) {
      print('Error updating message status: $e');
    }
  }
}
