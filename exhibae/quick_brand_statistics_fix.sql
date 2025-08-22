-- Quick fix for brand_statistics constraint issue
-- This script addresses the most common causes of the "null value in column brand_id" error

-- 1. First, let's see what we're dealing with
SELECT 
    'Diagnostic Summary' as section,
    'brand_statistics records' as item,
    COUNT(*) as count
FROM public.brand_statistics
UNION ALL
SELECT 
    'Diagnostic Summary' as section,
    'orphaned brand_statistics records' as item,
    COUNT(*) as count
FROM public.brand_statistics bs
LEFT JOIN auth.users au ON au.id = bs.brand_id
WHERE au.id IS NULL;

-- 2. Show any orphaned records (these are causing the issue)
SELECT 
    bs.brand_id,
    bs.total_applications,
    bs.approved_applications,
    bs.rejected_applications,
    bs.last_updated
FROM public.brand_statistics bs
LEFT JOIN auth.users au ON au.id = bs.brand_id
WHERE au.id IS NULL;

-- 3. Check if there are any profiles that exist but no auth.users entry
SELECT 
    'Profiles without auth.users' as check_type,
    COUNT(*) as count
FROM public.profiles p
LEFT JOIN auth.users au ON au.id = p.id
WHERE au.id IS NULL;

-- 4. Most likely fix: Clean up orphaned brand_statistics records
-- These records are pointing to non-existent users and causing the constraint violation
-- Uncomment the following line to fix the issue:
/*
DELETE FROM public.brand_statistics 
WHERE brand_id NOT IN (
    SELECT id FROM auth.users
);
*/

-- 5. Alternative fix: If you want to keep the data, you could temporarily disable the constraint
-- Uncomment these lines if you want to temporarily allow null values:
/*
-- Temporarily disable the NOT NULL constraint
ALTER TABLE public.brand_statistics 
ALTER COLUMN brand_id DROP NOT NULL;

-- After fixing the data, re-enable the constraint:
-- ALTER TABLE public.brand_statistics 
-- ALTER COLUMN brand_id SET NOT NULL;
*/

-- 6. Verify the fix worked
SELECT 
    'After fix verification' as section,
    'brand_statistics records' as item,
    COUNT(*) as count
FROM public.brand_statistics
UNION ALL
SELECT 
    'After fix verification' as section,
    'orphaned brand_statistics records' as item,
    COUNT(*) as count
FROM public.brand_statistics bs
LEFT JOIN auth.users au ON au.id = bs.brand_id
WHERE au.id IS NULL;
