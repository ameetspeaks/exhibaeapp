# Test Users Setup for App Functionality Testing

## 🎯 **Overview**

This document describes the setup of 3 test users that bypass OTP verification and Aisensy API calls for testing app functionality without requiring real WhatsApp integration.

## 👥 **Test Users Created**

### **1. Organizer Test User**
- **Phone Number:** `+919670006261`
- **Role:** `organizer`
- **OTP:** `123456`
- **Email:** `9670006261@test.exhibae.com`
- **Full Name:** `Test Organizer`

### **2. Brand Test User**
- **Phone Number:** `+919670006262`
- **Role:** `brand`
- **OTP:** `123456`
- **Email:** `9670006262@test.exhibae.com`
- **Full Name:** `Test Brand`

### **3. Shopper Test User**
- **Phone Number:** `+919670006263`
- **Role:** `shopper`
- **OTP:** `123456`
- **Email:** `9670006263@test.exhibae.com`
- **Full Name:** `Test Shopper`

## 🔧 **Technical Implementation**

### **Database Changes**

**File:** `create_test_users.sql`

The script creates:
1. **Users in `auth.users` table** with test metadata
2. **Profiles in `profiles` table** with proper role assignments
3. **OTP verification records** with fixed OTP `123456`
4. **Phone verification records** marked as verified

### **Flutter Code Changes**

**File:** `lib/core/services/whatsapp_auth_service.dart`

#### **1. Test User Detection**
```dart
bool _isTestUser(String phoneNumber) {
  final testPhoneNumbers = [
    '+919670006261', // Organizer
    '+919670006262', // Brand
    '+919670006263', // Shopper
  ];
  return testPhoneNumbers.contains(phoneNumber);
}
```

#### **2. OTP Sending Bypass**
- Test users bypass Aisensy API calls
- No real WhatsApp messages are sent
- Returns success immediately with test OTP

#### **3. OTP Verification Bypass**
- Accepts only OTP `123456` for test users
- Bypasses normal database verification
- Returns user info directly

## 🚀 **Setup Instructions**

### **1. Run Database Script**
```bash
# Execute the test users creation script
psql -h your-supabase-host -U postgres -d postgres -f create_test_users.sql
```

### **2. Deploy Updated Flutter Code**
```bash
# The WhatsApp auth service has been updated with test user support
flutter build apk
# or
flutter build ios
```

### **3. Test the Setup**
```bash
# Run verification queries
psql -h your-supabase-host -U postgres -d postgres -f test_user_fix.sql
```

## 📱 **How to Use Test Users**

### **Login Process**
1. **Enter Phone Number:** Use any of the test phone numbers
   - `+919670006261` (Organizer)
   - `+919670006262` (Brand)
   - `+919670006263` (Shopper)

2. **Enter OTP:** Always use `123456`

3. **Result:** User will be logged in with the appropriate role

### **Expected Behavior**
- ✅ **No Aisensy API calls** for test users
- ✅ **No real WhatsApp messages** sent
- ✅ **Immediate OTP success** with `123456`
- ✅ **Proper role assignment** in the app
- ✅ **Full app functionality** available

## 🔍 **Verification Queries**

### **Check Test Users in Database**
```sql
-- Check auth.users table
SELECT 
    au.id,
    au.email,
    au.raw_user_meta_data->>'phone' as phone,
    au.raw_user_meta_data->>'role' as role,
    au.raw_user_meta_data->>'full_name' as full_name
FROM auth.users au
WHERE au.email LIKE '%@test.exhibae.com'
ORDER BY au.raw_user_meta_data->>'role';

-- Check profiles table
SELECT 
    p.id,
    p.phone,
    p.full_name,
    p.role,
    p.auth_provider,
    p.phone_verified,
    p.is_test_user
FROM public.profiles p
WHERE p.phone IN ('+919670006261', '+919670006262', '+919670006263')
ORDER BY p.role;
```

### **Test find_user_by_phone Function**
```sql
-- Test with each phone number
SELECT 'Organizer' as role, * FROM find_user_by_phone('+919670006261')
UNION ALL
SELECT 'Brand' as role, * FROM find_user_by_phone('+919670006262')
UNION ALL
SELECT 'Shopper' as role, * FROM find_user_by_phone('+919670006263');
```

## 🛡️ **Security Considerations**

### **Production Safety**
- Test users are clearly marked with `is_test_user: true`
- Test phone numbers are in a specific range
- Test users can be easily identified and filtered

### **Environment Separation**
- Test users only work in development/testing environments
- Production environment should not have test users
- Clear documentation prevents accidental production use

## 🔄 **Maintenance**

### **Adding New Test Users**
1. Add phone number to `_isTestUser()` method
2. Add user creation in `create_test_users.sql`
3. Update this documentation

### **Removing Test Users**
```sql
-- Remove test users from database
DELETE FROM public.profiles WHERE is_test_user = true;
DELETE FROM auth.users WHERE email LIKE '%@test.exhibae.com';
```

## 📋 **Testing Checklist**

- [ ] **Organizer user** can login with `+919670006261` and OTP `123456`
- [ ] **Brand user** can login with `+919670006262` and OTP `123456`
- [ ] **Shopper user** can login with `+919670006263` and OTP `123456`
- [ ] **No Aisensy API calls** are made for test users
- [ ] **No real WhatsApp messages** are sent
- [ ] **Proper role-based functionality** works for each user
- [ ] **App navigation** works correctly for each role
- [ ] **Database queries** return correct user data

## 🐛 **Troubleshooting**

### **Common Issues**

#### **1. Test User Not Found**
```sql
-- Check if test user exists
SELECT * FROM public.profiles WHERE phone = '+919670006261';
```

#### **2. OTP Not Working**
- Ensure OTP is exactly `123456`
- Check if test user detection is working
- Verify phone number format

#### **3. Role Not Assigned**
```sql
-- Check role assignment
SELECT phone, role, full_name FROM public.profiles 
WHERE phone IN ('+919670006261', '+919670006262', '+919670006263');
```

### **Debug Logs**
Look for these log messages:
```
Test user detected: +919670006261 - bypassing OTP and Aisensy API
Test OTP accepted for: +919670006261
```

## 📞 **Support**

If you encounter issues with test users:
1. Check the database queries above
2. Verify the Flutter code changes are deployed
3. Check debug logs for test user detection
4. Ensure phone numbers are in the correct format
