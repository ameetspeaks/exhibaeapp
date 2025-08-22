-- Test script to verify verify_otp function
-- Run this to check if the function is working correctly

-- First, let's check if the function exists
SELECT 
    routine_name,
    routine_type,
    data_type
FROM information_schema.routines 
WHERE routine_name = 'verify_otp' 
AND routine_schema = 'public';

-- Check the function signature
SELECT 
    parameter_name,
    parameter_mode,
    data_type,
    parameter_default
FROM information_schema.parameters 
WHERE specific_name = 'verify_otp' 
AND specific_schema = 'public'
ORDER BY ordinal_position;

-- Test the function with a dummy call (this will fail but show us the structure)
-- SELECT * FROM verify_otp(NULL, '+919876543210', NULL, '123456', 'whatsapp');

-- Check if we have any OTP records to test with
SELECT 
    otp_id,
    phone_number,
    otp_code,
    otp_type,
    verified,
    expires_at,
    created_at
FROM public.otp_verifications 
ORDER BY created_at DESC 
LIMIT 5;

-- Check phone_verifications table
SELECT 
    verification_id,
    phone_number,
    verification_type,
    status,
    created_at
FROM public.phone_verifications 
ORDER BY created_at DESC 
LIMIT 5;
