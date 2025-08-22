# Test User OTP Fix

## 🔍 **Problem Identified**

### **Issue:**
Test users were getting the following error when trying to create OTP verifications:
```
PostgrestException(message: Could not find the 'id' column of 'otp_verifications' in the schema cache, code: PGRST204, details: Bad Request, hint: null)
```

### **Root Cause:**
There were inconsistencies in the database schema across different migrations:
1. Some migrations used `id` as the primary key for `otp_verifications` table
2. Other migrations used `otp_id` as the primary key
3. The Flutter code was trying to insert with `id` field, but the actual schema used `otp_id`

## 🛠️ **Solution Implemented**

### **1. Fixed Database Schema (`fix_otp_verifications_schema.sql`)**

**Changes:**
- **Column Renaming**: Renamed `id` to `otp_id` in `otp_verifications` table
- **Column Renaming**: Renamed `verification_type` to `otp_type` 
- **Column Removal**: Removed `status` column (belongs in `phone_verifications` table)
- **Constraint Updates**: Updated all constraints to use correct column names
- **Index Updates**: Updated all indexes to use correct column names

**Key Features:**
```sql
-- Ensures consistent schema
CREATE TABLE public.otp_verifications (
    otp_id UUID DEFAULT gen_random_uuid() PRIMARY KEY,  -- Correct primary key
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    phone_number VARCHAR(20) NOT NULL,
    email VARCHAR(255),
    otp_code VARCHAR(6) NOT NULL,
    otp_type VARCHAR(20) NOT NULL,  -- Correct column name
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    attempts INTEGER DEFAULT 0,
    max_attempts INTEGER DEFAULT 3,
    verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### **2. Fixed Foreign Key Constraint (`fix_phone_verifications_table.sql`)**

**Changes:**
- **Updated Foreign Key**: Changed reference from `otp_verifications (id)` to `otp_verifications (otp_id)`

```sql
-- Correct foreign key constraint
ALTER TABLE public.phone_verifications 
ADD CONSTRAINT phone_verifications_otp_verification_id_fkey 
FOREIGN KEY (otp_verification_id) REFERENCES otp_verifications (otp_id) ON DELETE CASCADE;
```

### **3. Fixed Flutter Code (`whatsapp_auth_service.dart`)**

**Changes:**
- **Updated Test OTP Creation**: Changed field names to match correct schema
- **Correct Column Names**: Used `otp_id`, `otp_type`, `verified` instead of `id`, `verification_type`, `status`

```dart
// Before (incorrect)
final verificationData = {
  'id': const Uuid().v4(),
  'verification_type': verificationType,
  'status': 'pending',
  // ...
};

// After (correct)
final verificationData = {
  'otp_id': const Uuid().v4(),
  'otp_type': verificationType,
  'verified': false,
  // ...
};
```

### **4. Fixed Database Functions (`fix_whatsapp_functions.sql`)**

**Changes:**
- **Updated All Functions**: Fixed `create_otp_verification`, `verify_otp`, `create_auth_token`, `log_whatsapp_message`
- **Correct RETURNING Clauses**: Changed `RETURNING id INTO` to `RETURNING otp_id INTO`
- **Correct WHERE Clauses**: Updated all WHERE conditions to use `otp_id`

```sql
-- Before (incorrect)
) RETURNING id INTO v_otp_id;

-- After (correct)
) RETURNING otp_id INTO v_otp_id;
```

## 📋 **Migration Files Created**

1. **`fix_otp_verifications_schema.sql`** - Fixes table schema inconsistencies
2. **`fix_phone_verifications_table.sql`** - Fixes foreign key constraint
3. **`fix_whatsapp_functions.sql`** - Fixes all database functions

## 🚀 **How to Apply the Fix**

### **Option 1: Run Migrations in Order**
```bash
# Run the migrations in your Supabase SQL editor or via CLI
# 1. First fix the schema
# 2. Then fix the foreign key
# 3. Finally fix the functions
```

### **Option 2: Manual SQL Execution**
```sql
-- Run these in your Supabase SQL editor:
-- 1. fix_otp_verifications_schema.sql
-- 2. fix_phone_verifications_table.sql  
-- 3. fix_whatsapp_functions.sql
```

## ✅ **Verification**

After applying the fixes:
1. Test users should be able to create OTP verifications without errors
2. The `otp_verifications` table should have consistent column names
3. All foreign key relationships should work correctly
4. Database functions should work without column reference errors

## 🔧 **Test Commands**

```sql
-- Verify the schema is correct
SELECT column_name, data_type, is_nullable 
FROM information_schema.columns 
WHERE table_name = 'otp_verifications' 
ORDER BY ordinal_position;

-- Test OTP creation for test users
SELECT * FROM create_otp_verification(
    p_phone_number => '+919670006261',
    p_otp_type => 'whatsapp_login'
);
```

## 📝 **Notes**

- The fix ensures backward compatibility by handling both old and new schema versions
- All existing data is preserved during the migration
- The fix is safe to run multiple times (idempotent)
- Test users will now work correctly with the WhatsApp OTP system
