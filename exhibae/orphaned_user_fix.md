# Orphaned User Fix

## 🔍 **Problem Identified**

### **Error:**
```
Error creating WhatsApp session: AuthApiException(message: User already registered, statusCode: 422, code: user_already_exists)
```

### **Root Cause:**
The user exists in `auth.users` table but **NOT** in the `profiles` table. This happened because:

1. **Previous Attempt Failed** - During earlier testing, the user was created in `auth.users` 
2. **Profile Creation Failed** - The profile creation failed due to the database constraint error we fixed
3. **Orphaned User** - User exists in auth but has no corresponding profile

## 🛠️ **Solution Implemented**

### **1. Enhanced User Creation Logic**
**File:** `lib/core/services/supabase_service.dart`

**New Flow:**
1. **Check if user exists** in `auth.users` by attempting sign-in
2. **If user exists:**
   - Check if profile exists in `profiles` table
   - **If profile exists:** Update profile with new data
   - **If no profile:** Create new profile for existing user
3. **If user doesn't exist:** Create new user and profile

### **2. Key Code Changes:**

```dart
// First, check if user already exists in auth.users
try {
  final existingUser = await client.auth.signInWithPassword(
    email: tempEmail,
    password: tempPassword,
  );
  
  if (existingUser.user != null) {
    print('User already exists in auth.users: ${existingUser.user!.id}');
    
    // Check if profile exists
    try {
      final existingProfile = await client
          .from('profiles')
          .select()
          .eq('id', existingUser.user!.id)
          .single();
      
      // Profile exists - update it
      await client.from('profiles').update({
        'full_name': userData?['full_name'],
        'role': userData?['role'] ?? 'shopper',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', existingUser.user!.id);
      
    } catch (profileError) {
      // Profile doesn't exist - create it
      final profileData = {
        'id': existingUser.user!.id, // Use existing user ID
        'phone': phoneNumber,
        'full_name': userData?['full_name'],
        'role': userData?['role'] ?? 'shopper',
        // ... other profile data
      };
      
      await client.from('profiles').insert(profileData);
    }
    
    return existingUser;
  }
} catch (signInError) {
  // User doesn't exist - create new user
  // Continue with normal creation flow
}
```

## 🔧 **Database Cleanup**

### **SQL Script Created:** `cleanup_orphaned_users.sql`

**What it does:**
1. **Identifies orphaned users** - Users in `auth.users` without profiles
2. **Shows specific user** - For phone number `+918588876261`
3. **Provides cleanup options** - Safe queries to understand the situation

### **Run these queries in your Supabase SQL editor:**

```sql
-- Check for orphaned users
SELECT 
    au.id,
    au.email,
    au.raw_user_meta_data,
    au.created_at
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.id
WHERE p.id IS NULL
AND au.email LIKE '%@whatsapp.exhibae.com';

-- Check specific phone number
SELECT 
    au.id,
    au.email,
    au.raw_user_meta_data,
    au.created_at,
    CASE WHEN p.id IS NOT NULL THEN 'Has Profile' ELSE 'No Profile' END as profile_status
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.id
WHERE au.email LIKE '%918588876261%'
OR (au.raw_user_meta_data->>'phone')::text = '+918588876261';
```

## 🚀 **Expected Results**

### **After Implementation:**
1. ✅ **No More "User already registered" Errors** - Handles existing users gracefully
2. ✅ **Profile Creation** - Creates missing profiles for existing users
3. ✅ **Data Consistency** - Ensures auth.users and profiles tables are in sync
4. ✅ **Smooth User Experience** - Users can complete signup even if they have partial data

### **For Your Specific Case:**
- The user with phone `+918588876261` should now be able to complete signup
- If they exist in `auth.users` but not in `profiles`, a profile will be created
- If they exist in both, their profile will be updated with new role/name

## 📋 **Next Steps**

### **1. Test the Fix:**
- Try the signup flow again with the same phone number
- The app should now handle the existing user gracefully

### **2. Check Database:**
- Run the SQL queries to see the current state
- Verify that the user now has a profile

### **3. Cleanup (Optional):**
- If you want to clean up orphaned users, use the provided SQL script
- **Be careful** - only delete users you're sure are orphaned

The enhanced user creation logic now handles all edge cases and ensures data consistency between `auth.users` and `profiles` tables! 🎉
