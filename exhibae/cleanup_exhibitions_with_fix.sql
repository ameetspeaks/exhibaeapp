-- Comprehensive cleanup script for exhibitions with brand_statistics fix
-- This script handles the constraint violation before deleting exhibitions

-- Step 1: First, let's see what we're dealing with
SELECT 
    'Current State' as section,
    'exhibitions' as table_name,
    COUNT(*) as count
FROM public.exhibitions
UNION ALL
SELECT 
    'Current State' as section,
    'orphaned brand_statistics' as table_name,
    COUNT(*) as count
FROM public.brand_statistics bs
LEFT JOIN auth.users au ON au.id = bs.brand_id
WHERE au.id IS NULL
UNION ALL
SELECT 
    'Current State' as section,
    'stall_applications' as table_name,
    COUNT(*) as count
FROM public.stall_applications
UNION ALL
SELECT 
    'Current State' as section,
    'stall_instances' as table_name,
    COUNT(*) as count
FROM public.stall_instances;

-- Step 2: Show orphaned brand_statistics records (these are causing the issue)
SELECT 
    'Orphaned brand_statistics records' as issue,
    bs.brand_id,
    bs.total_applications,
    bs.approved_applications,
    bs.rejected_applications,
    bs.last_updated
FROM public.brand_statistics bs
LEFT JOIN auth.users au ON au.id = bs.brand_id
WHERE au.id IS NULL;

-- Step 3: Fix the brand_statistics constraint issue first
-- This is the root cause of the error
DELETE FROM public.brand_statistics 
WHERE brand_id NOT IN (
    SELECT id FROM auth.users
);

-- Step 4: Verify the fix worked
SELECT 
    'After brand_statistics fix' as section,
    'orphaned brand_statistics' as table_name,
    COUNT(*) as count
FROM public.brand_statistics bs
LEFT JOIN auth.users au ON au.id = bs.brand_id
WHERE au.id IS NULL;

-- Step 5: Now safely delete exhibitions and related data
-- Delete in the correct order to avoid constraint violations

-- 5a. Delete stall applications first (they reference exhibitions and stalls)
DELETE FROM public.stall_applications 
WHERE exhibition_id IN (SELECT id FROM public.exhibitions);

-- 5b. Delete stall instances (they reference exhibitions)
DELETE FROM public.stall_instances 
WHERE exhibition_id IN (SELECT id FROM public.exhibitions);

-- 5c. Delete stalls (they might be referenced by applications)
-- Note: This will also delete any remaining stall_applications that reference these stalls
DELETE FROM public.stalls 
WHERE id IN (
    SELECT DISTINCT s.id 
    FROM public.stalls s
    LEFT JOIN public.stall_applications sa ON sa.stall_id = s.id
    LEFT JOIN public.stall_instances si ON si.stall_id = s.id
    WHERE sa.id IS NULL AND si.id IS NULL
);

-- 5d. Finally, delete the exhibitions
DELETE FROM public.exhibitions;

-- Step 6: Verify all exhibitions are deleted
SELECT 
    'After cleanup' as section,
    'exhibitions' as table_name,
    COUNT(*) as count
FROM public.exhibitions
UNION ALL
SELECT 
    'After cleanup' as section,
    'stall_applications' as table_name,
    COUNT(*) as count
FROM public.stall_applications
UNION ALL
SELECT 
    'After cleanup' as section,
    'stall_instances' as table_name,
    COUNT(*) as count
FROM public.stall_instances
UNION ALL
SELECT 
    'After cleanup' as section,
    'stalls' as table_name,
    COUNT(*) as count
FROM public.stalls;

-- Step 7: Show any remaining orphaned records
SELECT 
    'Remaining orphaned records' as section,
    'brand_statistics' as table_name,
    COUNT(*) as count
FROM public.brand_statistics bs
LEFT JOIN auth.users au ON au.id = bs.brand_id
WHERE au.id IS NULL
UNION ALL
SELECT 
    'Remaining orphaned records' as section,
    'profiles without auth.users' as table_name,
    COUNT(*) as count
FROM public.profiles p
LEFT JOIN auth.users au ON au.id = p.id
WHERE au.id IS NULL;
