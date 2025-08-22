-- Fix OTP type constraint to allow whatsapp_login
-- This adds 'whatsapp_login' to the allowed otp_type values

-- Drop the existing constraint
ALTER TABLE public.otp_verifications 
DROP CONSTRAINT IF EXISTS otp_verifications_otp_type_check;

-- Add the updated constraint with whatsapp_login included
ALTER TABLE public.otp_verifications 
ADD CONSTRAINT otp_verifications_otp_type_check 
CHECK (otp_type IN ('whatsapp', 'whatsapp_login', 'email', 'sms', 'login', 'registration', 'password_reset', 'phone_update'));

-- Log the change
SELECT 'OTP type constraint updated to include whatsapp_login' as migration_status;
