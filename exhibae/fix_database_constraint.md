# Database Constraint Fix

## Issue
The WhatsApp login feature is failing because the database constraint doesn't allow `whatsapp_login` as a valid `otp_type`.

## Error Message
```
PostgrestException(message: new row for relation "otp_verifications" violates check constraint "otp_verifications_otp_type_check", code: 23514, ...)
```

## Solution
Run the following SQL command in your Supabase SQL editor:

```sql
-- Fix OTP type constraint to allow whatsapp_login
-- This adds 'whatsapp_login' to the allowed otp_type values

-- Drop the existing constraint
ALTER TABLE public.otp_verifications 
DROP CONSTRAINT IF EXISTS otp_verifications_otp_type_check;

-- Add the updated constraint with whatsapp_login included
ALTER TABLE public.otp_verifications 
ADD CONSTRAINT otp_verifications_otp_type_check 
CHECK (otp_type IN ('whatsapp', 'whatsapp_login', 'email', 'sms', 'login', 'registration', 'password_reset', 'phone_update'));
```

## Alternative
You can also run the migration file:
```bash
# If using Supabase CLI
supabase db push

# Or manually run the SQL from:
database/migrations/fix_otp_type_constraint.sql
```

## Verification
After running the fix, the WhatsApp login should work without constraint violations.
