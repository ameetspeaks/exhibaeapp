# WhatsApp Migration Instructions

## Problem
The error `ERROR: 42P07: relation "phone_verifications" already exists` occurs because the table was created in a previous migration, but the current migration script is trying to create it again.

## Solution
Use the new migration files that safely handle existing tables and add missing components.

## Migration Files to Run (in order)

### 1. `database/migrations/fix_whatsapp_tables.sql`
This migration safely handles all WhatsApp-related tables:
- **Profiles table**: Adds missing WhatsApp columns (`phone_verified`, `phone_verified_at`, `whatsapp_enabled`, `auth_provider`)
- **OTP verifications table**: Creates if it doesn't exist
- **Auth tokens table**: Creates if it doesn't exist  
- **WhatsApp message logs table**: Creates if it doesn't exist
- **Indexes**: Creates all necessary indexes safely
- **RLS policies**: Sets up Row Level Security policies
- **Permissions**: Grants necessary permissions

### 2. `database/migrations/fix_phone_verifications_table.sql`
This migration specifically fixes the `phone_verifications` table:
- **Missing columns**: Adds `otp_verification_id` if it doesn't exist
- **Foreign key constraints**: Adds proper foreign key relationships
- **Check constraints**: Adds status and verification type constraints
- **Indexes**: Creates missing indexes
- **RLS policies**: Sets up security policies

### 3. `database/migrations/create_whatsapp_functions.sql`
This migration creates all the database functions:
- **OTP functions**: `generate_otp()`, `create_otp_verification()`, `verify_otp()`
- **Token functions**: `generate_secure_token()`, `create_auth_token()`, `validate_auth_token()`, `revoke_auth_token()`
- **Utility functions**: `find_user_by_phone()`, `cleanup_expired_auth_data()`, `log_whatsapp_message()`
- **Permissions**: Grants execute permissions on all functions

## How to Run

### Option 1: Supabase Dashboard
1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Run each migration file in order:
   ```sql
   -- Run fix_whatsapp_tables.sql first
   -- Then run fix_phone_verifications_table.sql
   -- Finally run create_whatsapp_functions.sql
   ```

### Option 2: Command Line
If you have Supabase CLI installed:
```bash
# Run the migrations
supabase db push
```

### Option 3: Direct SQL Execution
Copy and paste the contents of each migration file into your database SQL editor and execute them in order.

## Verification

After running the migrations, verify that:

1. **Tables exist**:
   ```sql
   SELECT table_name FROM information_schema.tables 
   WHERE table_schema = 'public' 
   AND table_name IN ('profiles', 'otp_verifications', 'auth_tokens', 'phone_verifications', 'whatsapp_message_logs');
   ```

2. **Functions exist**:
   ```sql
   SELECT routine_name FROM information_schema.routines 
   WHERE routine_schema = 'public' 
   AND routine_name IN ('generate_otp', 'create_otp_verification', 'verify_otp', 'find_user_by_phone');
   ```

3. **Columns exist in profiles**:
   ```sql
   SELECT column_name FROM information_schema.columns 
   WHERE table_name = 'profiles' 
   AND column_name IN ('phone_verified', 'phone_verified_at', 'whatsapp_enabled', 'auth_provider');
   ```

## Troubleshooting

### If you still get errors:
1. **Check existing tables**: Run `\dt` in psql to see what tables already exist
2. **Check existing functions**: Run `\df` in psql to see what functions already exist
3. **Drop and recreate**: If needed, you can drop existing tables and run the migrations fresh:
   ```sql
   DROP TABLE IF EXISTS phone_verifications CASCADE;
   DROP TABLE IF EXISTS otp_verifications CASCADE;
   DROP TABLE IF EXISTS auth_tokens CASCADE;
   DROP TABLE IF EXISTS whatsapp_message_logs CASCADE;
   ```

### If functions already exist:
The migration uses `CREATE OR REPLACE FUNCTION`, so existing functions will be updated automatically.

## Benefits of This Approach

1. **Safe**: Uses `IF NOT EXISTS` checks to avoid conflicts
2. **Incremental**: Can be run multiple times safely
3. **Complete**: Covers all tables, indexes, constraints, and functions
4. **Secure**: Sets up proper RLS policies and permissions
5. **Backward Compatible**: Works with existing data

## Next Steps

After running these migrations:
1. Test the WhatsApp authentication flow
2. Verify OTP creation and verification works
3. Check that phone verification status is properly tracked
4. Ensure all database functions return expected results

The WhatsApp authentication system should now work without any database errors!
