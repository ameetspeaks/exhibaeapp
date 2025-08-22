# Existing User Test Setup - Phone Number 9670006261

## 🎯 **Overview**

This document describes how to update the existing user with phone number `9670006261` to enable test functionality that bypasses OTP verification and Aisensy API calls.

## 👤 **Existing User Details**

### **Current User Information:**
- **User ID:** `f753f461-14b9-450e-b389-e8432148f13c`
- **Phone Number:** `9670006261`
- **Email:** `919670006261@whatsapp.exhibae.com`
- **Full Name:** `Savan`
- **Role:** `organiser`
- **Company Name:** `JRD Events`
- **Current Status:** 
  - `phone_verified: false`
  - `whatsapp_enabled: false`
  - `auth_provider: "email"`

### **Target Test Configuration:**
- **OTP:** `123456` (fixed)
- **Bypass Aisensy API:** ✅ Yes
- **Phone Verified:** ✅ Yes
- **WhatsApp Enabled:** ✅ Yes
- **Auth Provider:** `whatsapp`

## 🔧 **Technical Implementation**

### **Database Updates**

**File:** `update_existing_user_for_test.sql`

The script performs the following updates:

1. **Update Profile Table:**
       ```sql
    UPDATE public.profiles 
    SET 
        phone_verified = true,
        phone_verified_at = NOW(),
        whatsapp_enabled = true,
        auth_provider = 'whatsapp',
        updated_at = NOW()
    WHERE phone = '9670006261';
    ```

2. **Update Auth Users Metadata:**
   ```sql
   UPDATE auth.users 
   SET 
       raw_user_meta_data = raw_user_meta_data || 
       '{"phone_verified": true, "whatsapp_enabled": true, "auth_provider": "test", "is_test_user": true}'::jsonb,
       updated_at = NOW()
   WHERE email = '919670006261@whatsapp.exhibae.com';
   ```

3. **Create Test OTP Record:**
       ```sql
    INSERT INTO public.otp_verifications (
        otp_id, user_id, phone_number, otp_code, otp_type, verified, verified_at, expires_at
    ) VALUES (
        gen_random_uuid(),
        'f753f461-14b9-450e-b389-e8432148f13c',
        '9670006261',
        '123456',
        'whatsapp_login',
        true,
        NOW(),
        NOW() + INTERVAL '1 hour'
    );
    ```

### **Flutter Code Updates**

**File:** `lib/core/services/whatsapp_auth_service.dart`

#### **Updated Test User Detection:**
```dart
bool _isTestUser(String phoneNumber) {
  final testPhoneNumbers = [
    '+919670006261', // Organizer (with country code)
    '9670006261',    // Organizer (without country code - existing user)
    '+919670006262', // Brand
    '+919670006263', // Shopper
  ];
  return testPhoneNumbers.contains(phoneNumber);
}
```

## 🚀 **Setup Instructions**

### **1. Run Database Update Script**
```bash
# Execute the update script for the existing user
psql -h your-supabase-host -U postgres -d postgres -f update_existing_user_for_test.sql
```

### **2. Deploy Updated Flutter Code**
```bash
# The WhatsApp auth service has been updated to handle both phone number formats
flutter build apk
# or
flutter build ios
```

### **3. Verify the Updates**
```bash
# Check that the user is properly configured for testing
psql -h your-supabase-host -U postgres -d postgres -c "
SELECT 
    p.phone,
    p.full_name,
    p.role,
    p.phone_verified,
    p.whatsapp_enabled,
    p.auth_provider,
    p.is_test_user
FROM public.profiles p
WHERE p.phone = '9670006261';
"
```

## 📱 **How to Use the Updated User**

### **Login Process**
1. **Enter Phone Number:** `9670006261` (existing user format)
   - The app will automatically format it to `+919670006261` if needed

2. **Enter OTP:** `123456`

3. **Result:** User will be logged in as "Savan" with organizer role

### **Expected Behavior**
- ✅ **No Aisensy API calls** for this user
- ✅ **No real WhatsApp messages** sent
- ✅ **Immediate OTP success** with `123456`
- ✅ **User logs in as "Savan"** with organizer role
- ✅ **All existing user data preserved** (company, avatar, etc.)

## 🔍 **Verification Queries**

### **Check Updated User Details**
```sql
-- Check profile updates
SELECT 
    p.phone,
    p.full_name,
    p.role,
    p.company_name,
    p.phone_verified,
    p.whatsapp_enabled,
    p.auth_provider,
    p.is_test_user,
    p.updated_at
FROM public.profiles p
WHERE p.phone = '9670006261';

-- Check auth.users metadata
SELECT 
    au.email,
    au.raw_user_meta_data->>'phone' as phone,
    au.raw_user_meta_data->>'phone_verified' as phone_verified,
    au.raw_user_meta_data->>'whatsapp_enabled' as whatsapp_enabled,
    au.raw_user_meta_data->>'auth_provider' as auth_provider,
    au.raw_user_meta_data->>'is_test_user' as is_test_user
FROM auth.users au
WHERE au.email = '919670006261@whatsapp.exhibae.com';
```

### **Test find_user_by_phone Function**
```sql
-- Test with both phone number formats
SELECT 'With +91' as format, * FROM find_user_by_phone('+919670006261')
UNION ALL
SELECT 'Without +91' as format, * FROM find_user_by_phone('9670006261');
```

### **Check OTP Verification Records**
```sql
-- Check OTP verification
SELECT 
    id,
    user_id,
    phone_number,
    otp_code,
    verification_type,
    status,
    expires_at
FROM public.otp_verifications 
WHERE phone_number IN ('+919670006261', '9670006261');

-- Check phone verification
SELECT 
    id,
    user_id,
    phone_number,
    verification_type,
    status,
    verified_at
FROM public.phone_verifications 
WHERE phone_number IN ('+919670006261', '9670006261');
```

## 🛡️ **Data Preservation**

### **What's Preserved:**
- ✅ **User ID:** `f753f461-14b9-450e-b389-e8432148f13c`
- ✅ **Full Name:** `Savan`
- ✅ **Role:** `organiser`
- ✅ **Company Name:** `JRD Events`
- ✅ **Avatar URL:** Preserved
- ✅ **Company Logo URL:** Preserved
- ✅ **All other profile data:** Preserved

### **What's Updated:**
- 🔄 **Phone Verified:** `false` → `true`
- 🔄 **WhatsApp Enabled:** `false` → `true`
- 🔄 **Auth Provider:** `email` → `whatsapp`
- 🔄 **Test User Flag:** Added `is_test_user: true` (in metadata)
- 🔄 **OTP:** Set to `123456`

## 🔄 **Reverting Changes (If Needed)**

### **Restore Original Settings:**
```sql
-- Restore original profile settings
UPDATE public.profiles 
SET 
    phone_verified = false,
    phone_verified_at = NULL,
    whatsapp_enabled = false,
    auth_provider = 'email',
    updated_at = NOW()
WHERE phone = '9670006261';

-- Restore original auth.users metadata
UPDATE auth.users 
SET 
    raw_user_meta_data = raw_user_meta_data - 'phone_verified' - 'whatsapp_enabled' - 'auth_provider' - 'is_test_user',
    updated_at = NOW()
WHERE email = '919670006261@whatsapp.exhibae.com';

-- Remove test OTP records
DELETE FROM public.otp_verifications 
WHERE phone_number IN ('+919670006261', '9670006261');

DELETE FROM public.phone_verifications 
WHERE phone_number IN ('+919670006261', '9670006261');
```

## 📋 **Testing Checklist**

- [ ] **User can login** with phone `9670006261` and OTP `123456`
- [ ] **No Aisensy API calls** are made
- [ ] **No real WhatsApp messages** are sent
- [ ] **User logs in as "Savan"** with organizer role
- [ ] **Company data preserved** (JRD Events)
- [ ] **Avatar and logo URLs** still work
- [ ] **find_user_by_phone function** works with both phone formats
- [ ] **All existing functionality** works normally

## 🐛 **Troubleshooting**

### **Common Issues**

#### **1. User Not Found**
```sql
-- Check if user exists with both phone formats
SELECT * FROM public.profiles WHERE phone IN ('9670006261', '+919670006261');
```

#### **2. OTP Not Working**
- Ensure OTP is exactly `123456`
- Check if test user detection is working
- Verify phone number format handling

#### **3. Data Loss**
```sql
-- Check if original data is preserved
SELECT 
    full_name, role, company_name, avatar_url, company_logo_url
FROM public.profiles 
WHERE phone = '9670006261';
```

### **Debug Logs**
Look for these log messages:
```
Test user detected: 9670006261 - bypassing OTP and Aisensy API
Test OTP accepted for: 9670006261
```

## 📞 **Support**

If you encounter issues:
1. Run the verification queries above
2. Check debug logs for test user detection
3. Verify the database updates were successful
4. Ensure the Flutter code is deployed with the latest changes
