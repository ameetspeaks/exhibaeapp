class WhatsAppConfig {
  // Aisensy WhatsApp API Configuration
  // Replace these with your actual Aisensy API credentials
  
  // Your Aisensy API Key
  static const String apiKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6IjY4OWM3N2ViZTgwYjdmMGMyZjRmZjE5YiIsIm5hbWUiOiJFeGhpYmFlIiwiYXBwTmFtZSI6IkFpU2Vuc3kiLCJjbGllbnRJZCI6IjY4OWM3N2ViZTgwYjdmMGMyZjRmZjE5NiIsImFjdGl2ZVBsYW4iOiJGUkVFX0ZPUkVWRVIiLCJpYXQiOjE3NTUwODQ3Nzl9.cjPM5l-xG-eA849w3EIQo0jPfFLYjGvASJUV5jC0b-k';
  
  // Aisensy API Base URL
  static const String baseUrl = 'https://backend.aisensy.com';
  
  // Campaign name for authentication
  static const String campaignName = 'auth';
  
  // User name for messages
  static const String userName = 'Exhibae';
  
  // Source identifier
  static const String source = 'organic';
  
  // OTP expiration time in minutes
  static const int otpExpirationMinutes = 5;
  
  // Maximum OTP attempts
  static const int maxOtpAttempts = 3;
  
  // Resend OTP cooldown in seconds
  static const int resendCooldownSeconds = 30;
  
  // Aisensy API endpoints
  static String get messagesEndpoint => '$baseUrl/campaign/t1/api/v2';
  
  // Message template structure for Aisensy API
  static Map<String, dynamic> getOtpMessageTemplate(String phoneNumber, String otp) {
    return {
      'apiKey': apiKey,
      'campaignName': campaignName,
      'destination': phoneNumber.replaceAll('+', ''), // Remove + for Aisensy
      'userName': userName,
      'source': source,
      'templateParams': [otp],
      'buttons': [
        {
          'type': 'button',
          'sub_type': 'url',
          'index': '0', // String format as per API docs
          'parameters': [
            {
              'type': 'text',
              'text': otp
            }
          ]
        }
      ]
    };
  }
  
  // Headers for API requests
  static Map<String, String> get apiHeaders => {
    'Content-Type': 'application/json',
  };
  
  // Webhook verification response (if needed for Aisensy)
  static Map<String, dynamic> getWebhookVerificationResponse(String challenge) {
    return {
      'hub.mode': 'subscribe',
      'hub.verify_token': 'aisensy_verify_token',
      'hub.challenge': challenge,
    };
  }
}
