# All Test Users Setup - Complete Guide

## 🎯 **Overview**

This document describes the complete setup for all three test users with their respective roles, login credentials, and test functionality that bypasses OTP verification and Aisensy API calls.

## 👥 **Test Users Summary**

| Role | Name | Phone Number | Email | User ID |
|------|------|--------------|-------|---------|
| **Organizer** | Savan | `9670006261` | `919670006261@whatsapp.exhibae.com` | `f753f461-14b9-450e-b389-e8432148f13c` |
| **Brand** | Raje | `+919670006262` | `919670006262@exhibae.com` | `40b08d09-adf9-43c5-8093-5dedcb204e97` |
| **Shopper** | meet | `+919670006263` | `919670006263@exhibae.com` | `47d504a5-2f13-4a81-8e7d-2addb572b434` |

## 🔑 **Login Credentials**

### **All Users Use:**
- **OTP:** `123456` (fixed for all test users)
- **Bypass Aisensy API:** ✅ Yes
- **No Real WhatsApp Messages:** ✅ Yes

## 📱 **How to Login**

### **1. Organizer (Savan)**
```
Phone Number: 9670006261
OTP: 123456
Role: organiser
Company: JRD Events
```

### **2. Brand (Raje)**
```
Phone Number: +919670006262
OTP: 123456
Role: brand
Company: (None)
```

### **3. Shopper (meet)**
```
Phone Number: +919670006263
OTP: 123456
Role: shopper
Company: (None)
```

## 🔧 **Technical Implementation**

### **Database Setup**

**File:** `setup_all_test_users_otp.sql`

The script performs the following for all three users:

1. **Creates OTP Records:**
   - OTP Code: `123456`
   - Type: `whatsapp_login`
   - Status: `verified`
   - Expires: 1 hour from creation

2. **Creates Phone Verification Records:**
   - Type: `whatsapp_login`
   - Status: `verified`

3. **Verification Queries:**
   - Checks all users are properly configured
   - Tests `find_user_by_phone` function
   - Validates OTP and phone verification records

### **Flutter Code Updates**

**File:** `lib/core/services/whatsapp_auth_service.dart`

#### **Updated Test User Detection:**
```dart
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
```

## 🚀 **Setup Instructions**

### **1. Run Database Setup Script**
```bash
# Execute the setup script for all test users
psql -h your-supabase-host -U postgres -d postgres -f setup_all_test_users_otp.sql
```

### **2. Deploy Updated Flutter Code**
```bash
# Build the app with updated test user detection
flutter build apk --release
# or
flutter build ios
```

### **3. Verify the Setup**
```bash
# Check that all users are properly configured
psql -h your-supabase-host -U postgres -d postgres -c "
SELECT 
    p.full_name,
    p.role,
    p.phone,
    p.phone_verified,
    p.whatsapp_enabled,
    p.auth_provider
FROM public.profiles p
WHERE p.phone IN ('9670006261', '+919670006262', '+919670006263')
ORDER BY p.role;
"
```

## 📱 **Expected Behavior**

### **For All Test Users:**
- ✅ **No Aisensy API calls** are made
- ✅ **No real WhatsApp messages** sent
- ✅ **Immediate OTP success** with `123456`
- ✅ **User logs in** with their respective role
- ✅ **All existing user data preserved**

### **Role-Specific Features:**

#### **Organizer (Savan):**
- Access to organizer dashboard
- Can create and manage exhibitions
- Company data: JRD Events
- Avatar and logo URLs preserved

#### **Brand (Raje):**
- Access to brand dashboard
- Can apply for exhibitions
- Can manage stall applications

#### **Shopper (meet):**
- Access to shopper dashboard
- Can browse exhibitions
- Can save favorites

## 🔍 **Verification Queries**

### **Check All Test Users**
```sql
-- Check all test users
SELECT 
    p.full_name,
    p.role,
    p.phone,
    p.company_name,
    p.phone_verified,
    p.whatsapp_enabled,
    p.auth_provider,
    p.updated_at
FROM public.profiles p
WHERE p.phone IN ('9670006261', '+919670006262', '+919670006263')
ORDER BY p.role;
```

### **Check OTP Records**
```sql
-- Check OTP verification records
SELECT 
    p.full_name,
    p.role,
    p.phone,
    ov.otp_code,
    ov.verified,
    ov.expires_at
FROM public.otp_verifications ov
JOIN public.profiles p ON ov.user_id = p.id
WHERE p.phone IN ('9670006261', '+919670006262', '+919670006263')
ORDER BY p.role;
```

### **Test find_user_by_phone Function**
```sql
-- Test with all phone numbers
SELECT 'Organizer' as role, * FROM find_user_by_phone('9670006261')
UNION ALL
SELECT 'Brand' as role, * FROM find_user_by_phone('+919670006262')
UNION ALL
SELECT 'Shopper' as role, * FROM find_user_by_phone('+919670006263');
```

## 🛡️ **Data Preservation**

### **What's Preserved for Each User:**

#### **Organizer (Savan):**
- ✅ **User ID:** `f753f461-14b9-450e-b389-e8432148f13c`
- ✅ **Full Name:** `Savan`
- ✅ **Role:** `organiser`
- ✅ **Company Name:** `JRD Events`
- ✅ **Avatar URL:** Preserved
- ✅ **Company Logo URL:** Preserved

#### **Brand (Raje):**
- ✅ **User ID:** `40b08d09-adf9-43c5-8093-5dedcb204e97`
- ✅ **Full Name:** `Raje`
- ✅ **Role:** `brand`
- ✅ **Phone:** `+919670006262`

#### **Shopper (meet):**
- ✅ **User ID:** `47d504a5-2f13-4a81-8e7d-2addb572b434`
- ✅ **Full Name:** `meet`
- ✅ **Role:** `shopper`
- ✅ **Phone:** `+919670006263`

## 📋 **Testing Checklist**

### **For Each User:**
- [ ] **User can login** with their phone number and OTP `123456`
- [ ] **No Aisensy API calls** are made
- [ ] **No real WhatsApp messages** are sent
- [ ] **User logs in** with correct role
- [ ] **find_user_by_phone function** works with their phone format
- [ ] **All existing functionality** works normally

### **Role-Specific Testing:**
- [ ] **Organizer:** Can access organizer features
- [ ] **Brand:** Can access brand features
- [ ] **Shopper:** Can access shopper features

## 🐛 **Troubleshooting**

### **Common Issues**

#### **1. User Not Found**
```sql
-- Check if users exist with both phone formats
SELECT * FROM public.profiles 
WHERE phone IN ('9670006261', '+919670006261', '+919670006262', '+919670006263');
```

#### **2. OTP Not Working**
- Ensure OTP is exactly `123456`
- Check if test user detection is working
- Verify phone number format handling

#### **3. Network Errors**
- Check Android network security configuration
- Verify INTERNET permissions
- Check network security config file

### **Debug Logs**
Look for these log messages:
```
Test user detected: [phone_number] - bypassing OTP and Aisensy API
Test OTP accepted for: [phone_number]
```

## 📞 **Support**

If you encounter issues:
1. Run the verification queries above
2. Check debug logs for test user detection
3. Verify the database updates were successful
4. Ensure the Flutter code is deployed with the latest changes
5. Check Android network configuration for release builds

## 🎉 **Success Indicators**

When everything is working correctly, you should see:
- ✅ All three users can login with OTP `123456`
- ✅ No network errors in release builds
- ✅ No Aisensy API calls in logs
- ✅ Users access their role-specific dashboards
- ✅ All existing data is preserved
