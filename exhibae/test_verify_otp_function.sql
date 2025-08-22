-- Test script to verify the verify_otp function is working correctly
-- Run this after applying the migration

-- 1. Check if the function exists with the new return type
SELECT 
    routine_name,
    data_type,
    parameter_name,
    parameter_mode,
    parameter_default
FROM information_schema.routines r
LEFT JOIN information_schema.parameters p ON r.routine_name = p.specific_name
WHERE routine_name = 'verify_otp'
ORDER BY ordinal_position;

-- 2. Check if the is_temp_profile column exists
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND column_name = 'is_temp_profile';

-- 3. Check recent OTP verifications
SELECT 
    otp_id,
    phone_number,
    otp_type,
    verified,
    verified_at,
    created_at
FROM public.otp_verifications 
ORDER BY created_at DESC 
LIMIT 5;

-- 4. Check if any profiles were created recently
SELECT 
    id,
    phone,
    full_name,
    role,
    is_temp_profile,
    created_at
FROM public.profiles 
ORDER BY created_at DESC 
LIMIT 5;

-- 5. Test the function manually (replace with actual values)
-- SELECT * FROM verify_otp(
--     p_phone_number := '+919670006261',
--     p_otp_code := '123456',
--     p_otp_type := 'registration'
-- );
