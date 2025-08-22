# OTP Profile Creation Fix

## 🔍 **Problem Identified**

### **Issue:**
When OTP verification is completed, users are created in:
- ✅ `otp_verifications` table
- ✅ `phone_verifications` table  
- ✅ `auth.users` table (Supabase)
- ❌ **Missing**: `profiles` table

This causes orphaned users and the "User already registered" error.

### **Root Cause:**
The OTP verification process only handles authentication but doesn't create the user profile in the `profiles` table. The profile creation only happens later in the `RoleSelectionScreen`.

## 🛠️ **Solution Implemented**

### **1. Updated Database Function (`verify_otp`)**

**File:** `database/migrations/update_verify_otp_for_profile_creation.sql`

**Changes:**
- **Added `user_id` to return table** - Function now returns the user ID
- **Added `is_temp_profile` column** - Flag to identify temporary profiles
- **Profile creation logic** - Creates temporary profile during OTP verification
- **Updated `find_user_by_phone` function** - Handles temporary profiles

**Key Features:**
```sql
-- Function now returns user_id
RETURNS TABLE(
    success BOOLEAN,
    message TEXT,
    phone_verified BOOLEAN,
    verification_otp_id UUID,
    user_id UUID  -- NEW: Returns user ID
)

-- Creates temporary profile for new users
INSERT INTO public.profiles (
    id,
    phone,
    phone_verified,
    phone_verified_at,
    whatsapp_enabled,
    auth_provider,
    role,
    full_name,
    is_temp_profile,  -- NEW: Flag for temporary profiles
    created_at,
    updated_at
) VALUES (
    v_new_user_id,
    p_phone_number,
    TRUE,
    NOW(),
    TRUE,
    'whatsapp',
    'shopper',
    'User_' || REPLACE(REPLACE(REPLACE(p_phone_number, '+', ''), '-', ''), ' ', ''),
    TRUE,  -- Mark as temporary
    NOW(),
    NOW()
);
```

### **2. Updated WhatsApp Auth Service**

**File:** `lib/core/services/whatsapp_auth_service.dart`

**Changes:**
- **Added `_ensureProfileExists` method** - Ensures profile exists after OTP verification
- **Profile creation logic** - Creates profiles immediately after successful OTP verification
- **Handles both new and existing users** - Updates existing profiles or creates new ones

**Key Features:**
```dart
// New method to ensure profile exists
Future<void> _ensureProfileExists(String userId, String phoneNumber, String verificationType) async {
  // Check if profile already exists
  final existingProfile = await _supabase
      .from('profiles')
      .select('id')
      .eq('id', userId)
      .maybeSingle();
  
  if (existingProfile == null) {
    // Create basic profile entry
    final profileData = {
      'id': userId,
      'phone': phoneNumber,
      'phone_verified': true,
      'phone_verified_at': DateTime.now().toIso8601String(),
      'whatsapp_enabled': true,
      'auth_provider': 'whatsapp',
      'role': 'shopper', // Default role
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    // For registration, create temporary profile
    if (verificationType == 'registration') {
      profileData['full_name'] = 'User_${phoneNumber.replaceAll('+', '').replaceAll('-', '').replaceAll(' ', '')}';
      profileData['is_temp_profile'] = true;
    }
    
    await _supabase.from('profiles').insert(profileData);
  }
}
```

### **3. Updated Role Selection Screen**

**File:** `lib/features/auth/presentation/screens/role_selection_screen.dart`

**Changes:**
- **Handles temporary profiles** - Updates existing temporary profiles instead of creating new ones
- **Profile update logic** - Updates role, full name, and removes temporary flag
- **Fallback logic** - Creates new profile if no temporary profile exists

**Key Features:**
```dart
// Check for existing temporary profile
final existingProfile = await _supabaseService.client
    .from('profiles')
    .select('id, is_temp_profile')
    .eq('phone', widget.phoneNumber)
    .maybeSingle();

if (existingProfile != null) {
  // Update existing profile
  await _supabaseService.client
      .from('profiles')
      .update({
        'role': _selectedRole,
        'full_name': _fullNameController.text.trim(),
        'is_temp_profile': false, // Mark as no longer temporary
        'updated_at': DateTime.now().toIso8601String(),
      })
      .eq('id', existingProfile['id']);
} else {
  // Create new profile
  // ... existing logic
}
```

## 🚀 **Complete Flow**

### **Before Fix:**
1. User enters phone number → OTP sent
2. User enters OTP → OTP verified ✅
3. User goes to role selection → Profile created ❌ (Missing step)
4. User completes profile → Account created

### **After Fix:**
1. User enters phone number → OTP sent
2. User enters OTP → OTP verified ✅ + **Temporary profile created** ✅
3. User goes to role selection → **Temporary profile updated** ✅
4. User completes profile → Account finalized ✅

## 📋 **Database Schema Updates**

### **New Column Added:**
```sql
-- Add is_temp_profile column to profiles table
ALTER TABLE public.profiles 
ADD COLUMN is_temp_profile BOOLEAN DEFAULT FALSE;
```

### **Updated Functions:**
- `verify_otp()` - Now returns `user_id` and creates temporary profiles
- `find_user_by_phone()` - Handles temporary profiles

## 🎯 **Benefits**

### **1. No More Orphaned Users:**
- ✅ Profiles are created immediately after OTP verification
- ✅ No more "User already registered" errors
- ✅ Consistent data across all tables

### **2. Better User Experience:**
- ✅ Faster account creation process
- ✅ No data loss during profile completion
- ✅ Seamless flow from OTP to account creation

### **3. Data Integrity:**
- ✅ All users have corresponding profiles
- ✅ Temporary profiles are properly updated
- ✅ No orphaned records in any table

## 🔧 **Implementation Steps**

### **1. Run Database Migration:**
```sql
-- Execute the migration file
\i database/migrations/update_verify_otp_for_profile_creation.sql
```

### **2. Deploy Code Changes:**
- Update `whatsapp_auth_service.dart`
- Update `role_selection_screen.dart`

### **3. Test the Flow:**
1. Send OTP to a new phone number
2. Verify OTP
3. Check that profile is created in `profiles` table
4. Complete role selection
5. Verify profile is updated with user details

## 🎉 **Expected Results**

After implementing this fix:
- ✅ **No more orphaned users** in `auth.users` without `profiles`
- ✅ **No more "User already registered" errors**
- ✅ **Consistent data** across all authentication tables
- ✅ **Smooth user experience** from OTP to account creation

The fix ensures that every user who completes OTP verification will have a corresponding profile in the `profiles` table! 🎯
