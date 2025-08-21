# WhatsApp Business API Integration Guide

This guide provides step-by-step instructions for integrating WhatsApp Business API authentication into your existing Exhibae app while preserving the current email/password authentication system.

## Overview

The WhatsApp integration adds the following capabilities to your existing authentication system:

1. **WhatsApp Login**: Existing users with verified phone numbers can login via WhatsApp OTP
2. **Phone Verification**: Users can add and verify phone numbers to enable WhatsApp login
3. **Enhanced Security**: Two-factor authentication via WhatsApp
4. **Seamless Integration**: Works alongside existing email/password authentication

## Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Flutter App   │    │   Supabase DB    │    │ WhatsApp API    │
│                 │    │                  │    │                 │
│ ┌─────────────┐ │    │ ┌──────────────┐ │    │ ┌─────────────┐ │
│ │Email/Pass   │ │    │ │profiles      │ │    │ │Message      │ │
│ │Auth (Existing)│ │    │ │phone_verified │ │    │ │Templates   │ │
│ └─────────────┘ │    │ │whatsapp_enabled│ │    │ └─────────────┘ │
│                 │    │ └──────────────┘ │    │                 │
│ ┌─────────────┐ │    │ ┌──────────────┐ │    │ ┌─────────────┐ │
│ │WhatsApp     │ │◄──►│ │phone_verifications│ │    │ │Webhook     │ │
│ │Auth (New)   │ │    │ │otp_code      │ │    │ │Delivery     │ │
│ └─────────────┘ │    │ │expires_at    │ │    │ │Status       │ │
└─────────────────┘    │ └──────────────┘ │    └─────────────────┘
                       │ ┌──────────────┐ │
                       │ │whatsapp_logs │ │
                       │ │message_tracking│ │
                       │ └──────────────┘ │
                       └──────────────────┘
```

## Database Schema

### New Tables Added

#### 1. `phone_verifications`
Stores OTP verification records for WhatsApp authentication.

```sql
CREATE TABLE public.phone_verifications (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    phone_number VARCHAR(20) NOT NULL,
    otp_code VARCHAR(6) NOT NULL,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    attempts INTEGER DEFAULT 0,
    verified BOOLEAN DEFAULT FALSE,
    verification_type VARCHAR(20) DEFAULT 'login' CHECK (verification_type IN ('login', 'phone_update', 'registration', 'whatsapp_login')),
    whatsapp_message_id VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### 2. `whatsapp_message_logs`
Tracks WhatsApp message delivery status.

```sql
CREATE TABLE public.whatsapp_message_logs (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    phone_number VARCHAR(20) NOT NULL,
    message_type VARCHAR(50) NOT NULL,
    message_id VARCHAR(255),
    status VARCHAR(50) DEFAULT 'sent',
    error_message TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Updated Tables

#### `profiles` Table Extensions
Added new columns to existing profiles table:

```sql
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS phone_verified_at TIMESTAMP WITH TIME ZONE NULL;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS whatsapp_enabled BOOLEAN DEFAULT FALSE;
ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS auth_provider VARCHAR(20) DEFAULT 'email' CHECK (auth_provider IN ('email', 'whatsapp', 'both'));
```

## Setup Instructions

### Step 1: WhatsApp Business API Setup

1. **Create Meta Developer Account**
   - Go to [Meta for Developers](https://developers.facebook.com/)
   - Create a developer account and complete verification

2. **Create WhatsApp Business App**
   - In Meta Developer Console, create a new app
   - Select "Business" as app type
   - Add "WhatsApp" product to your app

3. **Configure WhatsApp Business API**
   - Go to WhatsApp > Getting Started
   - Add a phone number to your WhatsApp Business account
   - Note down the Phone Number ID
   - Generate a permanent access token

4. **Create Message Template**
   - Go to WhatsApp > Message Templates
   - Create template with name: `otp_verification`
   - Category: Authentication
   - Language: English
   - Content: `Your Exhibae verification code is: {{1}}. This code will expire in 5 minutes.`
   - Submit for approval (24-48 hours)

5. **Set up Webhook** (Optional)
   - Go to WhatsApp > Configuration
   - Set webhook URL for receiving delivery status
   - Generate a verify token

### Step 2: Database Migration

Run the database migration to create the required tables:

```bash
# Apply the migration
psql -h your-supabase-host -U postgres -d postgres -f database/migrations/create_whatsapp_otp_tables.sql
```

### Step 3: Configuration

Update the WhatsApp configuration file:

```dart
// lib/core/config/whatsapp_config.dart
class WhatsAppConfig {
  // Replace with your actual credentials
  static const String phoneNumberId = 'YOUR_PHONE_NUMBER_ID';
  static const String accessToken = 'YOUR_ACCESS_TOKEN';
  static const String verifyToken = 'YOUR_VERIFY_TOKEN';
  
  // ... rest of configuration
}
```

### Step 4: Environment Variables

Add WhatsApp credentials to your environment:

```env
# .env file
WHATSAPP_PHONE_NUMBER_ID=your_phone_number_id
WHATSAPP_ACCESS_TOKEN=your_access_token
WHATSAPP_VERIFY_TOKEN=your_verify_token
```

## Authentication Flow

### 1. WhatsApp Login (Existing Users)

```
User enters phone number
         ↓
Check if phone is verified in profiles
         ↓
If verified → Send WhatsApp OTP
         ↓
User enters OTP
         ↓
Verify OTP and sign in user
```

### 2. Phone Verification (New Feature)

```
Authenticated user goes to phone verification
         ↓
User enters phone number
         ↓
Send WhatsApp OTP
         ↓
User verifies OTP
         ↓
Update profile with verified phone
         ↓
Enable WhatsApp login for user
```

### 3. Existing Email/Password Auth

```
User signs up with email/password (unchanged)
         ↓
User logs in with email/password (unchanged)
         ↓
Optional: User can add phone verification
         ↓
User can now use WhatsApp login
```

## API Endpoints

### WhatsApp Authentication

```dart
// Send OTP for WhatsApp login
await supabaseService.sendWhatsAppOtp(
  phoneNumber: '+1234567890',
  verificationType: 'whatsapp_login',
);

// Verify OTP for WhatsApp login
final response = await supabaseService.signInWithWhatsApp(
  phoneNumber: '+1234567890',
  otp: '123456',
);

// Send OTP for phone verification
await supabaseService.sendWhatsAppOtp(
  phoneNumber: '+1234567890',
  userId: currentUserId,
  verificationType: 'phone_update',
);

// Verify OTP for phone verification
final result = await supabaseService.verifyWhatsAppOtp(
  phoneNumber: '+1234567890',
  otp: '123456',
  userId: currentUserId,
  verificationType: 'phone_update',
);
```

### Phone Management

```dart
// Get phone verification status
final status = await supabaseService.getPhoneVerificationStatus();

// Update phone number
final result = await supabaseService.updatePhoneNumber('+1234567890');

// Find user by phone number
final user = await supabaseService.findUserByPhone('+1234567890');
```

## UI Components

### 1. WhatsApp Login Screen
- Phone number input with validation
- WhatsApp availability checking
- OTP sending functionality
- Only for existing users with verified phones

### 2. Phone Verification Screen
- Add phone number to existing account
- WhatsApp OTP verification
- Benefits explanation
- Status display

### 3. WhatsApp OTP Verification Screen
- 6-digit OTP input with auto-focus
- Resend functionality with timer
- Error handling and validation

## Security Features

### 1. Rate Limiting
- Maximum 3 OTP requests per hour per phone number
- Automatic cleanup of expired OTPs
- Attempt tracking and blocking

### 2. OTP Security
- 6-digit random OTP generation
- 5-minute expiration time
- Maximum 3 verification attempts
- Secure storage in database

### 3. Phone Number Validation
- International format validation
- Duplicate phone number prevention
- WhatsApp availability checking

## Error Handling

### Common Error Scenarios

1. **Invalid Phone Number**
   - Format validation
   - WhatsApp availability check
   - User-friendly error messages

2. **OTP Expired**
   - Automatic cleanup
   - Resend functionality
   - Clear expiration messaging

3. **Rate Limit Exceeded**
   - Retry timer display
   - User-friendly messaging
   - Automatic retry after cooldown

4. **WhatsApp API Errors**
   - Fallback messaging
   - Error logging
   - Retry mechanisms

## Testing

### 1. Unit Tests
```dart
// Test WhatsApp auth service
test('should send OTP successfully', () async {
  final result = await whatsAppAuthService.sendWhatsAppOtp(
    phoneNumber: '+1234567890',
    verificationType: 'whatsapp_login',
  );
  expect(result['success'], true);
});
```

### 2. Integration Tests
```dart
// Test complete WhatsApp login flow
test('should complete WhatsApp login flow', () async {
  // Send OTP
  final otpResult = await supabaseService.sendWhatsAppOtp(
    phoneNumber: '+1234567890',
    verificationType: 'whatsapp_login',
  );
  
  // Verify OTP
  final loginResult = await supabaseService.signInWithWhatsApp(
    phoneNumber: '+1234567890',
    otp: '123456',
  );
  
  expect(loginResult.user, isNotNull);
});
```

### 3. UI Tests
```dart
// Test WhatsApp login screen
testWidgets('should show WhatsApp login form', (tester) async {
  await tester.pumpWidget(WhatsAppLoginScreen());
  expect(find.text('Login with WhatsApp'), findsOneWidget);
  expect(find.byType(TextFormField), findsOneWidget);
});
```

## Monitoring and Analytics

### 1. WhatsApp Message Tracking
- Message delivery status
- Success/failure rates
- Response times
- Error logging

### 2. User Analytics
- WhatsApp login usage
- Phone verification completion rates
- User engagement metrics
- Conversion tracking

### 3. Performance Monitoring
- API response times
- Database query performance
- OTP generation and verification times
- Error rates and patterns

## Deployment Checklist

### Pre-deployment
- [ ] WhatsApp Business API credentials configured
- [ ] Message templates approved
- [ ] Database migration applied
- [ ] Environment variables set
- [ ] Error handling tested
- [ ] Rate limiting configured
- [ ] Security policies reviewed

### Post-deployment
- [ ] Webhook endpoints tested
- [ ] Message delivery verified
- [ ] User flows tested
- [ ] Monitoring alerts configured
- [ ] Backup authentication working
- [ ] Performance metrics collected

## Troubleshooting

### Common Issues

1. **"Invalid Access Token"**
   - Check token expiration
   - Verify phone number ID
   - Ensure proper permissions

2. **"Template Not Found"**
   - Verify template name spelling
   - Check template approval status
   - Confirm template language

3. **"Phone Number Not Registered"**
   - Verify international format
   - Check WhatsApp registration
   - Test with known working number

4. **"Rate Limit Exceeded"**
   - Implement proper rate limiting
   - Add retry delays
   - Monitor usage patterns

### Debug Mode

Enable debug logging:

```dart
// Add to WhatsAppAuthService
static const bool _debugMode = true;

void _log(String message) {
  if (_debugMode) {
    print('WhatsApp Auth: $message');
  }
}
```

## Support Resources

- [WhatsApp Business API Documentation](https://developers.facebook.com/docs/whatsapp)
- [Meta for Developers](https://developers.facebook.com/)
- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Documentation](https://flutter.dev/docs)

## Next Steps

After successful integration:

1. **User Experience Enhancement**
   - Add WhatsApp branding
   - Implement smooth transitions
   - Add loading animations

2. **Advanced Features**
   - Two-factor authentication
   - Account recovery via WhatsApp
   - Rich media messages

3. **Analytics and Optimization**
   - Track user behavior
   - Optimize conversion rates
   - A/B test different flows

---

**Note**: This integration preserves your existing authentication system while adding WhatsApp capabilities. Users can continue using email/password authentication, and the WhatsApp features are optional enhancements.
