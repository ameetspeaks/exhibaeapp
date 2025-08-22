-- Cleanup script for orphaned users
-- This script helps identify and clean up users that exist in auth.users but not in profiles

-- 1. First, let's see what users exist in auth.users but not in profiles
SELECT 
    au.id,
    au.email,
    au.raw_user_meta_data,
    au.created_at
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.id
WHERE p.id IS NULL
AND au.email LIKE '%@whatsapp.exhibae.com';

-- 2. Count of orphaned users
SELECT 
    COUNT(*) as orphaned_users_count
FROM auth.users au
LEFT JOIN public.profiles p ON au.id = p.id
WHERE p.id IS NULL
AND au.email LIKE '%@whatsapp.exhibae.com';

-- 3. To delete orphaned users (UNCOMMENT ONLY IF YOU WANT TO DELETE THEM)
-- DELETE FROM auth.users 
-- WHERE id IN (
--     SELECT au.id
--     FROM auth.users au
--     LEFT JOIN public.profiles p ON au.id = p.id
--     WHERE p.id IS NULL
--     AND au.email LIKE '%@whatsapp.exhibae.com'
-- );

-- 4. Check for users with phone number +918588876261 specifically
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

-- 5. Check profiles table for this phone number
SELECT 
    id,
    phone,
    full_name,
    role,
    created_at
FROM public.profiles 
WHERE phone = '+918588876261';
