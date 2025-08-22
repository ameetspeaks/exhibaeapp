-- Final fix for orphaned user issue
-- This will clean up all orphaned users and fix the "User already registered" error

-- 1. Check current state
SELECT 
    'Current State' as section,
    'auth.users count' as item,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'Current State' as section,
    'profiles count' as item,
    COUNT(*) as count
FROM public.profiles
UNION ALL
SELECT 
    'Current State' as section,
    'orphaned users (in auth.users but not profiles)' as item,
    COUNT(*) as count
FROM auth.users au
LEFT JOIN public.profiles p ON p.id = au.id
WHERE p.id IS NULL
UNION ALL
SELECT 
    'Current State' as section,
    'orphaned profiles (in profiles but not auth.users)' as item,
    COUNT(*) as count
FROM public.profiles p
LEFT JOIN auth.users au ON au.id = p.id
WHERE au.id IS NULL;

-- 2. Show specific orphaned users for phone +919670006261
SELECT 
    'Orphaned users for phone +919670006261' as section,
    au.id,
    au.email,
    au.raw_user_meta_data,
    au.created_at,
    CASE WHEN p.id IS NOT NULL THEN 'Has Profile' ELSE 'No Profile' END as profile_status
FROM auth.users au
LEFT JOIN public.profiles p ON p.id = au.id
WHERE au.email LIKE '%919670006261%'
OR (au.raw_user_meta_data->>'phone')::text = '+919670006261';

-- 3. Show profiles for this phone number
SELECT 
    'Profiles for phone +919670006261' as section,
    p.id,
    p.phone,
    p.full_name,
    p.role,
    p.created_at,
    CASE WHEN au.id IS NOT NULL THEN 'Has Auth User' ELSE 'No Auth User' END as auth_status
FROM public.profiles p
LEFT JOIN auth.users au ON au.id = p.id
WHERE p.phone = '+919670006261';

-- 4. Clean up orphaned users (users in auth.users but not in profiles)
-- These are causing the "User already registered" error
DELETE FROM auth.users 
WHERE id IN (
    SELECT au.id
    FROM auth.users au
    LEFT JOIN public.profiles p ON p.id = au.id
    WHERE p.id IS NULL
    AND au.email LIKE '%@whatsapp.exhibae.com'
);

-- 5. Clean up orphaned profiles (profiles without auth.users)
-- These are also problematic
DELETE FROM public.profiles 
WHERE id IN (
    SELECT p.id
    FROM public.profiles p
    LEFT JOIN auth.users au ON au.id = p.id
    WHERE au.id IS NULL
);

-- 6. Clean up orphaned brand_statistics
DELETE FROM public.brand_statistics 
WHERE brand_id NOT IN (
    SELECT id FROM auth.users
);

-- 7. Clean up orphaned stall_applications
DELETE FROM public.stall_applications 
WHERE brand_id NOT IN (
    SELECT id FROM auth.users
);

-- 8. Verify the cleanup worked
SELECT 
    'After Cleanup' as section,
    'auth.users count' as item,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'After Cleanup' as section,
    'profiles count' as item,
    COUNT(*) as count
FROM public.profiles
UNION ALL
SELECT 
    'After Cleanup' as section,
    'orphaned users' as item,
    COUNT(*) as count
FROM auth.users au
LEFT JOIN public.profiles p ON p.id = au.id
WHERE p.id IS NULL
UNION ALL
SELECT 
    'After Cleanup' as section,
    'orphaned profiles' as item,
    COUNT(*) as count
FROM public.profiles p
LEFT JOIN auth.users au ON au.id = p.id
WHERE au.id IS NULL;

-- 9. Check specifically for the problematic phone number
SELECT 
    'Final check for +919670006261' as section,
    'auth.users' as table_name,
    COUNT(*) as count
FROM auth.users au
WHERE au.email LIKE '%919670006261%'
OR (au.raw_user_meta_data->>'phone')::text = '+919670006261'
UNION ALL
SELECT 
    'Final check for +919670006261' as section,
    'profiles' as table_name,
    COUNT(*) as count
FROM public.profiles p
WHERE p.phone = '+919670006261';
