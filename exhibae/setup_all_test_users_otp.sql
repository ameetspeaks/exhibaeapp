-- Setup OTP records for all three test users
-- This script creates OTP verification records for all test users with fixed OTP "123456"

-- 1. Setup OTP for Organizer (Savan) - Phone: 9670006261
-- First, delete any existing OTP records for this user
DELETE FROM public.otp_verifications 
WHERE user_id = 'f753f461-14b9-450e-b389-e8432148f13c'
AND phone_number IN ('9670006261', '+919670006261');

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
VALUES (
    gen_random_uuid(),
    'f753f461-14b9-450e-b389-e8432148f13c',
    '9670006261',
    '123456',
    'whatsapp_login',
    true,
    NOW(),
    NOW() + INTERVAL '1 hour',
    NOW(),
    NOW()
);

-- 2. Setup OTP for Brand (Raje) - Phone: +919670006262
-- First, delete any existing OTP records for this user
DELETE FROM public.otp_verifications 
WHERE user_id = '40b08d09-adf9-43c5-8093-5dedcb204e97'
AND phone_number IN ('+919670006262', '919670006262');

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
VALUES (
    gen_random_uuid(),
    '40b08d09-adf9-43c5-8093-5dedcb204e97',
    '+919670006262',
    '123456',
    'whatsapp_login',
    true,
    NOW(),
    NOW() + INTERVAL '1 hour',
    NOW(),
    NOW()
);

-- 3. Setup OTP for Shopper (meet) - Phone: +919670006263
-- First, delete any existing OTP records for this user
DELETE FROM public.otp_verifications 
WHERE user_id = '47d504a5-2f13-4a81-8e7d-2addb572b434'
AND phone_number IN ('+919670006263', '919670006263');

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
VALUES (
    gen_random_uuid(),
    '47d504a5-2f13-4a81-8e7d-2addb572b434',
    '+919670006263',
    '123456',
    'whatsapp_login',
    true,
    NOW(),
    NOW() + INTERVAL '1 hour',
    NOW(),
    NOW()
);

-- 4. Setup Phone Verification Records for all users
-- Organizer (Savan)
DELETE FROM public.phone_verifications 
WHERE user_id = 'f753f461-14b9-450e-b389-e8432148f13c'
AND phone_number IN ('9670006261', '+919670006261');

INSERT INTO public.phone_verifications (
    verification_id,
    user_id,
    phone_number,
    verification_type,
    status,
    created_at,
    updated_at
)
VALUES (
    gen_random_uuid(),
    'f753f461-14b9-450e-b389-e8432148f13c',
    '9670006261',
    'whatsapp_login',
    'verified',
    NOW(),
    NOW()
);

-- Brand (Raje)
DELETE FROM public.phone_verifications 
WHERE user_id = '40b08d09-adf9-43c5-8093-5dedcb204e97'
AND phone_number IN ('+919670006262', '919670006262');

INSERT INTO public.phone_verifications (
    verification_id,
    user_id,
    phone_number,
    verification_type,
    status,
    created_at,
    updated_at
)
VALUES (
    gen_random_uuid(),
    '40b08d09-adf9-43c5-8093-5dedcb204e97',
    '+919670006262',
    'whatsapp_login',
    'verified',
    NOW(),
    NOW()
);

-- Shopper (meet)
DELETE FROM public.phone_verifications 
WHERE user_id = '47d504a5-2f13-4a81-8e7d-2addb572b434'
AND phone_number IN ('+919670006263', '919670006263');

INSERT INTO public.phone_verifications (
    verification_id,
    user_id,
    phone_number,
    verification_type,
    status,
    created_at,
    updated_at
)
VALUES (
    gen_random_uuid(),
    '47d504a5-2f13-4a81-8e7d-2addb572b434',
    '+919670006263',
    'whatsapp_login',
    'verified',
    NOW(),
    NOW()
);

-- 5. Verify all test users are properly configured
SELECT 
    'Test Users Summary' as status,
    COUNT(*) as total_users
FROM public.profiles 
WHERE phone IN ('9670006261', '+919670006262', '+919670006263');

-- 6. Check OTP verification records
SELECT 
    'OTP Verification Records' as status,
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

-- 7. Check phone verification records
SELECT 
    'Phone Verification Records' as status,
    p.full_name,
    p.role,
    p.phone,
    pv.status,
    pv.created_at
FROM public.phone_verifications pv
JOIN public.profiles p ON pv.user_id = p.id
WHERE p.phone IN ('9670006261', '+919670006262', '+919670006263')
ORDER BY p.role;

-- 8. Test find_user_by_phone function for all users
SELECT 
    'Testing find_user_by_phone function' as test_name,
    'Organizer' as role,
    user_id,
    phone_verified,
    auth_provider
FROM find_user_by_phone('9670006261')
UNION ALL
SELECT 
    'Testing find_user_by_phone function' as test_name,
    'Brand' as role,
    user_id,
    phone_verified,
    auth_provider
FROM find_user_by_phone('+919670006262')
UNION ALL
SELECT 
    'Testing find_user_by_phone function' as test_name,
    'Shopper' as role,
    user_id,
    phone_verified,
    auth_provider
FROM find_user_by_phone('+919670006263');
