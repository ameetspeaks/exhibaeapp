-- Fix for brand_statistics constraint issue based on actual table structure
-- Table: brand_statistics (brand_id uuid not null, references auth.users(id))

-- 1. Check current table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'brand_statistics' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Check foreign key constraint
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    rc.delete_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
JOIN information_schema.referential_constraints AS rc
    ON tc.constraint_name = rc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name = 'brand_statistics';

-- 3. Check for orphaned records (brand_id exists in brand_statistics but not in auth.users)
SELECT 
    'Orphaned records in brand_statistics' as check_type,
    COUNT(*) as count
FROM public.brand_statistics bs
LEFT JOIN auth.users au ON au.id = bs.brand_id
WHERE au.id IS NULL;

-- 4. Show sample of orphaned records
SELECT 
    bs.brand_id,
    bs.total_applications,
    bs.approved_applications,
    bs.rejected_applications,
    bs.last_updated,
    CASE WHEN au.id IS NOT NULL THEN 'EXISTS' ELSE 'MISSING' END as user_exists
FROM public.brand_statistics bs
LEFT JOIN auth.users au ON au.id = bs.brand_id
WHERE au.id IS NULL
LIMIT 5;

-- 5. Check if there are any triggers that might be causing the issue
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'brand_statistics';

-- 6. Check for any recent activity that might have caused the issue
SELECT 
    'Recent brand_statistics activity' as check_type,
    COUNT(*) as total_records,
    MIN(last_updated) as earliest_update,
    MAX(last_updated) as latest_update
FROM public.brand_statistics;

-- 7. Check if there are any profiles that exist but their auth.users entry is missing
SELECT 
    'Profiles without auth.users entry' as check_type,
    COUNT(*) as count
FROM public.profiles p
LEFT JOIN auth.users au ON au.id = p.id
WHERE au.id IS NULL;

-- 8. Show sample of profiles without auth.users entries
SELECT 
    p.id,
    p.full_name,
    p.role,
    p.created_at
FROM public.profiles p
LEFT JOIN auth.users au ON au.id = p.id
WHERE au.id IS NULL
LIMIT 5;

-- 9. Check for any brand_statistics records that might be created for non-existent users
SELECT 
    'brand_statistics for non-existent users' as check_type,
    COUNT(*) as count
FROM public.brand_statistics bs
WHERE NOT EXISTS (
    SELECT 1 FROM auth.users au WHERE au.id = bs.brand_id
);

-- 10. Cleanup options (commented out for safety)
/*
-- Option A: Clean up orphaned brand_statistics records
DELETE FROM public.brand_statistics 
WHERE brand_id NOT IN (
    SELECT id FROM auth.users
);

-- Option B: Clean up orphaned profiles (if they exist)
DELETE FROM public.profiles 
WHERE id NOT IN (
    SELECT id FROM auth.users
);

-- Option C: Create missing auth.users entries for profiles (if needed)
-- This would require admin privileges and careful consideration
INSERT INTO auth.users (id, email, encrypted_password, email_confirmed_at, created_at, updated_at)
SELECT 
    p.id,
    p.email,
    'encrypted_password_here', -- You'd need to generate this properly
    p.created_at,
    p.created_at,
    p.updated_at
FROM public.profiles p
WHERE NOT EXISTS (
    SELECT 1 FROM auth.users au WHERE au.id = p.id
)
AND p.email IS NOT NULL;
*/

-- 11. Show the current state summary
SELECT 
    'Summary' as section,
    'brand_statistics records' as item,
    COUNT(*) as count
FROM public.brand_statistics
UNION ALL
SELECT 
    'Summary' as section,
    'auth.users records' as item,
    COUNT(*) as count
FROM auth.users
UNION ALL
SELECT 
    'Summary' as section,
    'profiles records' as item,
    COUNT(*) as count
FROM public.profiles;
