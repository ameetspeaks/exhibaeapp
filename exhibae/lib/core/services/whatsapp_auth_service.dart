import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import '../config/supabase_config.dart';
import '../config/whatsapp_config.dart';

class WhatsAppAuthService {
  static WhatsAppAuthService? _instance;
  static WhatsAppAuthService get instance => _instance ??= WhatsAppAuthService._internal();
  
  WhatsAppAuthService._internal();

  // WhatsApp Business API configuration
  static const String _baseUrl = WhatsAppConfig.baseUrl;
  static const String _phoneNumberId = WhatsAppConfig.phoneNumberId;
  static const String _accessToken = WhatsAppConfig.accessToken;
  static const String _verifyToken = WhatsAppConfig.verifyToken;
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // Initialize WhatsApp Business API
  Future<void> initialize() async {
    // Store tokens securely
    await _secureStorage.write(key: 'whatsapp_phone_number_id', value: _phoneNumberId);
    await _secureStorage.write(key: 'whatsapp_access_token', value: _accessToken);
    await _secureStorage.write(key: 'whatsapp_verify_token', value: _verifyToken);
  }

  // Send OTP via WhatsApp
  Future<bool> sendWhatsAppOtp(String phoneNumber) async {
    try {
      // Format phone number to international format
      final formattedPhone = await _formatPhoneNumber(phoneNumber);
      
      // Generate OTP
      final otp = _generateOtp();
      
      // Store OTP temporarily (in production, use a more secure method)
      await _secureStorage.write(key: 'whatsapp_otp_$formattedPhone', value: otp);
      
      // Prepare message template using config
      final message = WhatsAppConfig.getOtpMessageTemplate(formattedPhone, otp);

      // Send message via WhatsApp Business API
      final response = await http.post(
        Uri.parse(WhatsAppConfig.messagesEndpoint),
        headers: WhatsAppConfig.apiHeaders,
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['messages'] != null;
      } else {
        print('WhatsApp API Error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error sending WhatsApp OTP: $e');
      return false;
    }
  }

  // Verify WhatsApp OTP
  Future<bool> verifyWhatsAppOtp(String phoneNumber, String otp) async {
    try {
      final formattedPhone = await _formatPhoneNumber(phoneNumber);
      final storedOtp = await _secureStorage.read(key: 'whatsapp_otp_$formattedPhone');
      
      if (storedOtp == otp) {
        // Clear the stored OTP after successful verification
        await _secureStorage.delete(key: 'whatsapp_otp_$formattedPhone');
        return true;
      }
      return false;
    } catch (e) {
      print('Error verifying WhatsApp OTP: $e');
      return false;
    }
  }

  // Format phone number to international format
  Future<String> _formatPhoneNumber(String phoneNumber) async {
    try {
      final parsed = PhoneNumber.parse(phoneNumber);
      return parsed.international ?? phoneNumber;
    } catch (e) {
      // If parsing fails, return the original number
      return phoneNumber;
    }
  }

  // Generate 6-digit OTP
  String _generateOtp() {
    return (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
  }

  // Get WhatsApp user info (if available)
  Future<Map<String, dynamic>?> getWhatsAppUserInfo(String phoneNumber) async {
    try {
      final formattedPhone = await _formatPhoneNumber(phoneNumber);
      
      // In a real implementation, you might want to store user info
      // when they first authenticate via WhatsApp
      return {
        'phone_number': formattedPhone,
        'auth_provider': 'whatsapp',
        'verified': true,
      };
    } catch (e) {
      print('Error getting WhatsApp user info: $e');
      return null;
    }
  }

  // Check if WhatsApp is available for a phone number
  Future<bool> isWhatsAppAvailable(String phoneNumber) async {
    try {
      final formattedPhone = await _formatPhoneNumber(phoneNumber);
      
      // This is a simplified check. In production, you might want to
      // use WhatsApp's Business Management API to check if the number
      // is registered with WhatsApp
      return true;
    } catch (e) {
      return false;
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
    } catch (e) {
      print('Error handling webhook: $e');
    }
  }
}
