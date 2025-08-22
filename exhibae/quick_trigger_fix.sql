-- Quick fix for the brand_statistics trigger issue
-- This fixes the null brand_id constraint violation

-- 1. Check the current problem
SELECT 
    'Problem Summary' as section,
    'stall_applications with null brand_id' as issue,
    COUNT(*) as count
FROM public.stall_applications 
WHERE brand_id IS NULL
UNION ALL
SELECT 
    'Problem Summary' as section,
    'orphaned brand_statistics' as issue,
    COUNT(*) as count
FROM public.brand_statistics bs
LEFT JOIN auth.users au ON au.id = bs.brand_id
WHERE au.id IS NULL;

-- 2. Fix the trigger function to handle null values
CREATE OR REPLACE FUNCTION update_brand_statistics()
RETURNS TRIGGER AS $$
BEGIN
    -- Only proceed if brand_id is not null
    IF NEW.brand_id IS NOT NULL THEN
        INSERT INTO public.brand_statistics (brand_id)
        VALUES (NEW.brand_id)
        ON CONFLICT (brand_id) DO UPDATE
        SET
            total_applications = (
                SELECT count(*) FROM public.stall_applications
                WHERE brand_id = NEW.brand_id
            ),
            approved_applications = (
                SELECT count(*) FROM public.stall_applications
                WHERE brand_id = NEW.brand_id AND status = 'approved'
            ),
            rejected_applications = (
                SELECT count(*) FROM public.stall_applications
                WHERE brand_id = NEW.brand_id AND status = 'rejected'
            ),
            active_stalls = (
                SELECT count(*) FROM public.stall_applications sa
                JOIN public.exhibitions e ON e.id = sa.exhibition_id
                WHERE sa.brand_id = NEW.brand_id
                AND sa.status = 'approved'
                AND e.status = 'active'
            ),
            total_exhibitions_participated = (
                SELECT count(DISTINCT exhibition_id)
                FROM public.stall_applications
                WHERE brand_id = NEW.brand_id
                AND status = 'approved'
            ),
            last_updated = now();
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 3. Clean up problematic data
-- Remove stall_applications with null brand_id
DELETE FROM public.stall_applications 
WHERE brand_id IS NULL;

-- Remove orphaned brand_statistics records
DELETE FROM public.brand_statistics 
WHERE brand_id NOT IN (
    SELECT id FROM auth.users
);

-- 4. Verify the fix
SELECT 
    'Fix Verification' as section,
    'stall_applications with null brand_id' as issue,
    COUNT(*) as count
FROM public.stall_applications 
WHERE brand_id IS NULL
UNION ALL
SELECT 
    'Fix Verification' as section,
    'orphaned brand_statistics' as issue,
    COUNT(*) as count
FROM public.brand_statistics bs
LEFT JOIN auth.users au ON au.id = bs.brand_id
WHERE au.id IS NULL;
