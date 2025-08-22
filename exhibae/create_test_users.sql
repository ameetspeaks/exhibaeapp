-- Create Test Users for App Functionality Testing
-- These users bypass OTP verification and Aisensy API calls

-- 1. Create test users in auth.users table
INSERT INTO auth.users (
    id,
    email,
    encrypted_password,
    email_confirmed_at,
    created_at,
    updated_at,
    raw_user_meta_data,
    is_super_admin,
    confirmation_token,
    recovery_token
) VALUES 
-- Organizer user
(
    gen_random_uuid(),
    '9670006261@test.exhibae.com',
    crypt('test_password_123', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"phone": "+919670006261", "role": "organizer", "auth_provider": "test", "phone_verified": true, "whatsapp_enabled": true, "full_name": "Test Organizer", "is_test_user": true}'::jsonb,
    false,
    NULL,
    NULL
),
-- Brand user
(
    gen_random_uuid(),
    '9670006262@test.exhibae.com',
    crypt('test_password_123', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"phone": "+919670006262", "role": "brand", "auth_provider": "test", "phone_verified": true, "whatsapp_enabled": true, "full_name": "Test Brand", "is_test_user": true}'::jsonb,
    false,
    NULL,
    NULL
),
-- Shopper user
(
    gen_random_uuid(),
    '9670006263@test.exhibae.com',
    crypt('test_password_123', gen_salt('bf')),
    NOW(),
    NOW(),
    NOW(),
    '{"phone": "+919670006263", "role": "shopper", "auth_provider": "test", "phone_verified": true, "whatsapp_enabled": true, "full_name": "Test Shopper", "is_test_user": true}'::jsonb,
    false,
    NULL,
    NULL
)
ON CONFLICT (email) DO NOTHING;

-- 2. Create corresponding profiles in profiles table
INSERT INTO public.profiles (
    id,
    phone,
    full_name,
    role,
    auth_provider,
    phone_verified,
    phone_verified_at,
    whatsapp_enabled,
    email,
    is_test_user,
    created_at,
    updated_at
)
SELECT 
    au.id,
    au.raw_user_meta_data->>'phone' as phone,
    au.raw_user_meta_data->>'full_name' as full_name,
    au.raw_user_meta_data->>'role' as role,
    au.raw_user_meta_data->>'auth_provider' as auth_provider,
    (au.raw_user_meta_data->>'phone_verified')::boolean as phone_verified,
    au.created_at as phone_verified_at,
    (au.raw_user_meta_data->>'whatsapp_enabled')::boolean as whatsapp_enabled,
    au.email,
    (au.raw_user_meta_data->>'is_test_user')::boolean as is_test_user,
    au.created_at,
    au.updated_at
FROM auth.users au
WHERE au.email IN (
    '9670006261@test.exhibae.com',
    '9670006262@test.exhibae.com',
    '9670006263@test.exhibae.com'
)
ON CONFLICT (id) DO UPDATE SET
    phone = EXCLUDED.phone,
    full_name = EXCLUDED.full_name,
    role = EXCLUDED.role,
    auth_provider = EXCLUDED.auth_provider,
    phone_verified = EXCLUDED.phone_verified,
    phone_verified_at = EXCLUDED.phone_verified_at,
    whatsapp_enabled = EXCLUDED.whatsapp_enabled,
    email = EXCLUDED.email,
    is_test_user = EXCLUDED.is_test_user,
    updated_at = NOW();

-- 3. Create test OTP records (these will be used instead of real OTP verification)
INSERT INTO public.otp_verifications (
    id,
    user_id,
    phone_number,
    otp_code,
    verification_type,
    status,
    expires_at,
    created_at,
    updated_at
)
SELECT 
    gen_random_uuid(),
    au.id,
    au.raw_user_meta_data->>'phone',
    '123456', -- Fixed OTP for test users
    'test_verification',
    'verified',
    NOW() + INTERVAL '1 hour',
    NOW(),
    NOW()
FROM auth.users au
WHERE au.email IN (
    '9670006261@test.exhibae.com',
    '9670006262@test.exhibae.com',
    '9670006263@test.exhibae.com'
)
ON CONFLICT (user_id, phone_number) DO UPDATE SET
    otp_code = '123456',
    status = 'verified',
    expires_at = NOW() + INTERVAL '1 hour',
    updated_at = NOW();

-- 4. Create phone verification records
INSERT INTO public.phone_verifications (
    id,
    user_id,
    phone_number,
    verification_type,
    status,
    verified_at,
    created_at,
    updated_at
)
SELECT 
    gen_random_uuid(),
    au.id,
    au.raw_user_meta_data->>'phone',
    'test_verification',
    'verified',
    NOW(),
    NOW(),
    NOW()
FROM auth.users au
WHERE au.email IN (
    '9670006261@test.exhibae.com',
    '9670006262@test.exhibae.com',
    '9670006263@test.exhibae.com'
)
ON CONFLICT (user_id, phone_number) DO UPDATE SET
    status = 'verified',
    verified_at = NOW(),
    updated_at = NOW();

-- 5. Verify the test users were created
SELECT 
    'Test Users Created' as status,
    au.id,
    au.email,
    au.raw_user_meta_data->>'phone' as phone,
    au.raw_user_meta_data->>'role' as role,
    au.raw_user_meta_data->>'full_name' as full_name,
    p.phone_verified,
    p.auth_provider,
    p.is_test_user
FROM auth.users au
LEFT JOIN public.profiles p ON p.id = au.id
WHERE au.email IN (
    '9670006261@test.exhibae.com',
    '9670006262@test.exhibae.com',
    '9670006263@test.exhibae.com'
)
ORDER BY au.raw_user_meta_data->>'role';

-- 6. Test the find_user_by_phone function with test users
SELECT 
    'Testing find_user_by_phone function' as test_name,
    'Organizer' as role,
    user_id,
    phone_verified,
    auth_provider
FROM find_user_by_phone('+919670006261')
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
