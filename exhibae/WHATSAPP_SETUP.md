# WhatsApp Business API Integration Setup Guide

This guide will help you set up WhatsApp Business API integration for the Exhibae app.

## Prerequisites

1. **Meta Developer Account**: You need a Meta Developer account
2. **WhatsApp Business Account**: A verified WhatsApp Business account
3. **Phone Number**: A verified phone number for your WhatsApp Business account
4. **Message Templates**: Pre-approved message templates for OTP verification

## Step 1: Create Meta Developer Account

1. Go to [Meta for Developers](https://developers.facebook.com/)
2. Click "Get Started" and create a developer account
3. Complete the verification process

## Step 2: Create WhatsApp Business App

1. In your Meta Developer Console, click "Create App"
2. Select "Business" as the app type
3. Choose "WhatsApp" as the product
4. Fill in your app details and create the app

## Step 3: Configure WhatsApp Business API

1. **Get Phone Number ID**:
   - Go to WhatsApp > Getting Started
   - Add a phone number to your WhatsApp Business account
   - Note down the Phone Number ID (you'll need this)

2. **Generate Access Token**:
   - Go to WhatsApp > Getting Started
   - Generate a permanent access token
   - Save this token securely

3. **Set up Webhook** (Optional for basic OTP):
   - Go to WhatsApp > Configuration
   - Set up a webhook URL for receiving messages
   - Generate a verify token

## Step 4: Create Message Templates

1. Go to WhatsApp > Message Templates
2. Create a new template with the following details:
   - **Template Name**: `otp_verification`
   - **Category**: Authentication
   - **Language**: English
   - **Template Content**: 
     ```
     Your Exhibae verification code is: {{1}}
     
     This code will expire in 5 minutes.
     If you didn't request this code, please ignore this message.
     ```
3. Submit for approval (this may take 24-48 hours)

## Step 5: Update Configuration

1. Open `lib/core/config/whatsapp_config.dart`
2. Replace the placeholder values with your actual credentials:

```dart
class WhatsAppConfig {
  // Replace with your actual WhatsApp Business Phone Number ID
  static const String phoneNumberId = '123456789012345';
  
  // Replace with your actual WhatsApp Business Access Token
  static const String accessToken = 'YOUR_ACTUAL_ACCESS_TOKEN';
  
  // Replace with your webhook verify token
  static const String verifyToken = 'YOUR_VERIFY_TOKEN';
  
  // ... rest of the configuration
}
```

## Step 6: Test the Integration

1. **Test OTP Sending**:
   - Run the app
   - Go to Login screen
   - Click "Continue with WhatsApp"
   - Enter a valid phone number
   - Check if OTP is received via WhatsApp

2. **Test OTP Verification**:
   - Enter the received OTP
   - Verify that authentication works

## Security Considerations

1. **Access Token Security**:
   - Never commit access tokens to version control
   - Use environment variables or secure storage
   - Rotate tokens regularly

2. **Phone Number Validation**:
   - Validate phone numbers before sending OTP
   - Implement rate limiting
   - Add CAPTCHA for multiple failed attempts

3. **OTP Security**:
   - Use secure random generation
   - Implement expiration times
   - Limit OTP attempts

## Troubleshooting

### Common Issues

1. **"Invalid Access Token"**:
   - Check if your access token is correct
   - Ensure the token hasn't expired
   - Verify the phone number ID

2. **"Template Not Found"**:
   - Ensure the template name matches exactly
   - Check if the template is approved
   - Verify the template language

3. **"Phone Number Not Registered"**:
   - Ensure the phone number is in international format
   - Check if the number is registered with WhatsApp
   - Verify the number is not blocked

4. **"Rate Limit Exceeded"**:
   - Implement proper rate limiting
   - Add delays between requests
   - Monitor API usage

### Debug Mode

Enable debug logging by adding this to your WhatsApp service:

```dart
// Add to WhatsAppAuthService
static const bool _debugMode = true;

void _log(String message) {
  if (_debugMode) {
    print('WhatsApp Auth: $message');
  }
}
```

## Production Deployment

1. **Environment Variables**:
   - Move sensitive data to environment variables
   - Use different tokens for development and production

2. **Monitoring**:
   - Set up logging for WhatsApp API calls
   - Monitor success/failure rates
   - Track user engagement

3. **Backup Authentication**:
   - Keep email/password authentication as backup
   - Implement fallback mechanisms

## API Limits and Costs

- **Rate Limits**: 1000 messages per second per phone number
- **Template Messages**: Free for first 1000 conversations per month
- **Session Messages**: Free for first 1000 conversations per month
- **Additional Costs**: Check Meta's pricing for your region

## Support Resources

- [WhatsApp Business API Documentation](https://developers.facebook.com/docs/whatsapp)
- [Meta for Developers](https://developers.facebook.com/)
- [WhatsApp Business API Support](https://developers.facebook.com/support/)

## Next Steps

After successful integration:

1. **User Experience**:
   - Add WhatsApp branding to your app
   - Implement proper error handling
   - Add loading states and feedback

2. **Analytics**:
   - Track WhatsApp login usage
   - Monitor conversion rates
   - Analyze user behavior

3. **Advanced Features**:
   - Implement WhatsApp Business Profile
   - Add rich media messages
   - Implement conversation management

---

**Note**: This integration uses the official WhatsApp Business API. Make sure to comply with WhatsApp's terms of service and messaging policies.
