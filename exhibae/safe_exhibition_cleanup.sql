-- Safe exhibition cleanup script (run step by step)
-- This script fixes the brand_statistics issue and then cleans up exhibitions

-- STEP 1: Check current state
SELECT 
    'Current State' as section,
    'exhibitions' as table_name,
    COUNT(*) as count
FROM public.exhibitions;

-- STEP 2: Check for orphaned brand_statistics records (the root cause)
SELECT 
    'Orphaned brand_statistics' as issue,
    COUNT(*) as count
FROM public.brand_statistics bs
LEFT JOIN auth.users au ON au.id = bs.brand_id
WHERE au.id IS NULL;

-- STEP 3: Show the problematic records
SELECT 
    bs.brand_id,
    bs.total_applications,
    bs.approved_applications,
    bs.rejected_applications,
    bs.last_updated
FROM public.brand_statistics bs
LEFT JOIN auth.users au ON au.id = bs.brand_id
WHERE au.id IS NULL;

-- STEP 4: Fix the brand_statistics issue (uncomment to run)
/*
DELETE FROM public.brand_statistics 
WHERE brand_id NOT IN (
    SELECT id FROM auth.users
);
*/

-- STEP 5: Verify the fix worked (run after step 4)
SELECT 
    'After fix verification' as section,
    'orphaned brand_statistics' as table_name,
    COUNT(*) as count
FROM public.brand_statistics bs
LEFT JOIN auth.users au ON au.id = bs.brand_id
WHERE au.id IS NULL;

-- STEP 6: Now delete exhibitions safely (uncomment to run)
/*
-- Delete stall applications first
DELETE FROM public.stall_applications 
WHERE exhibition_id IN (SELECT id FROM public.exhibitions);

-- Delete stall instances
DELETE FROM public.stall_instances 
WHERE exhibition_id IN (SELECT id FROM public.exhibitions);

-- Finally delete exhibitions
DELETE FROM public.exhibitions;
*/

-- STEP 7: Verify cleanup (run after step 6)
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
FROM public.stall_instances;
