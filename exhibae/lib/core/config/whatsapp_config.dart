class WhatsAppConfig {
  // WhatsApp Business API Configuration
  // Replace these with your actual WhatsApp Business API credentials
  
  // Your WhatsApp Business Phone Number ID
  static const String phoneNumberId = 'YOUR_PHONE_NUMBER_ID';
  
  // Your WhatsApp Business Access Token
  static const String accessToken = 'YOUR_ACCESS_TOKEN';
  
  // Your webhook verify token
  static const String verifyToken = 'YOUR_VERIFY_TOKEN';
  
  // WhatsApp Business API Base URL
  static const String baseUrl = 'https://graph.facebook.com/v18.0';
  
  // Message template name for OTP verification
  static const String otpTemplateName = 'otp_verification';
  
  // Language code for messages
  static const String languageCode = 'en';
  
  // OTP expiration time in minutes
  static const int otpExpirationMinutes = 5;
  
  // Maximum OTP attempts
  static const int maxOtpAttempts = 3;
  
  // Resend OTP cooldown in seconds
  static const int resendCooldownSeconds = 30;
  
  // WhatsApp Business API endpoints
  static String get messagesEndpoint => '$baseUrl/$phoneNumberId/messages';
  static String get webhookEndpoint => '$baseUrl/$phoneNumberId/webhook';
  
  // Message template structure
  static Map<String, dynamic> getOtpMessageTemplate(String phoneNumber, String otp) {
    return {
      'messaging_product': 'whatsapp',
      'to': phoneNumber,
      'type': 'template',
      'template': {
        'name': otpTemplateName,
        'language': {
          'code': languageCode
        },
        'components': [
          {
            'type': 'body',
            'parameters': [
              {
                'type': 'text',
                'text': otp
              }
            ]
          }
        ]
      }
    };
  }
  
  // Headers for API requests
  static Map<String, String> get apiHeaders => {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
  };
  
  // Webhook verification response
  static Map<String, dynamic> getWebhookVerificationResponse(String challenge) {
    return {
      'hub.mode': 'subscribe',
      'hub.verify_token': verifyToken,
      'hub.challenge': challenge,
    };
  }
}
