-- Update existing user with phone number 9670006261 for test functionality
-- This user already exists in the database, we just need to set up test OTP and bypass Aisensy API

-- 1. Update the existing user's profile to mark as test user and enable WhatsApp
UPDATE public.profiles 
SET 
    phone_verified = true,
    phone_verified_at = NOW(),
    whatsapp_enabled = true,
    auth_provider = 'whatsapp',
    updated_at = NOW()
WHERE phone = '9670006261';

-- 2. Update the auth.users table metadata for this user
UPDATE auth.users 
SET 
    raw_user_meta_data = raw_user_meta_data || 
    '{"phone_verified": true, "whatsapp_enabled": true, "auth_provider": "whatsapp", "is_test_user": true}'::jsonb,
    updated_at = NOW()
WHERE email = '919670006261@whatsapp.exhibae.com';

-- 3. Create or update OTP verification record for this user
-- First, delete any existing OTP records for this user
DELETE FROM public.otp_verifications 
WHERE user_id = (SELECT id FROM public.profiles WHERE phone = '9670006261')
AND phone_number = '9670006261';

-- Then insert new OTP record
INSERT INTO public.otp_verifications (
    otp_id,
    user_id,
    phone_number,
    otp_code,
    otp_type,
    verified,
    verified_at,
    expires_at,
    created_at,
    updated_at
)
SELECT 
    gen_random_uuid(),
    p.id,
    p.phone,
    '123456', -- Fixed OTP for test user
    'whatsapp_login',
    true,
    NOW(),
    NOW() + INTERVAL '1 hour',
    NOW(),
    NOW()
FROM public.profiles p
WHERE p.phone = '9670006261';

-- 4. Create or update phone verification record
-- First, delete any existing phone verification records for this user
DELETE FROM public.phone_verifications 
WHERE user_id = (SELECT id FROM public.profiles WHERE phone = '9670006261')
AND phone_number = '9670006261';

-- Then insert new phone verification record
INSERT INTO public.phone_verifications (
    verification_id,
    user_id,
    phone_number,
    verification_type,
    status,
    created_at,
    updated_at
)
SELECT 
    gen_random_uuid(),
    p.id,
    p.phone,
    'whatsapp_login',
    'verified',
    NOW(),
    NOW()
FROM public.profiles p
WHERE p.phone = '9670006261';

-- 5. Verify the updates were successful
SELECT 
    'Updated User Details' as status,
    p.id,
    p.phone,
    p.full_name,
    p.role,
    p.auth_provider,
    p.phone_verified,
    p.whatsapp_enabled,
    p.updated_at
FROM public.profiles p
WHERE p.phone = '9670006261';

-- 6. Test the find_user_by_phone function with the updated user
SELECT 
    'Testing find_user_by_phone function' as test_name,
    'Existing User' as role,
    user_id,
    phone_verified,
    auth_provider
FROM find_user_by_phone('+919670006261');

-- 7. Check OTP verification record
SELECT 
    'OTP Verification Record' as status,
    otp_id,
    user_id,
    phone_number,
    otp_code,
    otp_type,
    verified as otp_verified,
    verified_at,
    expires_at,
    created_at
FROM public.otp_verifications 
WHERE phone_number = '+919670006261' OR phone_number = '9670006261';

-- 8. Check phone verification record
SELECT 
    'Phone Verification Record' as status,
    verification_id,
    user_id,
    phone_number,
    verification_type,
    status as verification_status,
    created_at
FROM public.phone_verifications 
WHERE phone_number = '+919670006261' OR phone_number = '9670006261';
