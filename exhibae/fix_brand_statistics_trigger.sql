-- Fix for brand_statistics trigger causing null brand_id constraint violation
-- The trigger is trying to insert records with null brand_id values

-- 1. First, let's see the current trigger function
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'update_brand_statistics'
AND routine_schema = 'public';

-- 2. Check what triggers are using this function
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE action_statement LIKE '%update_brand_statistics%';

-- 3. Check for any stall_applications with null brand_id
SELECT 
    'stall_applications with null brand_id' as issue,
    COUNT(*) as count
FROM public.stall_applications 
WHERE brand_id IS NULL;

-- 4. Show sample of problematic stall_applications
SELECT 
    id,
    brand_id,
    exhibition_id,
    stall_id,
    status,
    created_at
FROM public.stall_applications 
WHERE brand_id IS NULL
LIMIT 5;

-- 5. Fix the trigger function to handle null brand_id values
-- Create a new version of the function that checks for null values
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

-- 6. Clean up any existing stall_applications with null brand_id
-- These are causing the trigger to fail
DELETE FROM public.stall_applications 
WHERE brand_id IS NULL;

-- 7. Clean up any orphaned brand_statistics records
DELETE FROM public.brand_statistics 
WHERE brand_id NOT IN (
    SELECT id FROM auth.users
);

-- 8. Verify the fix worked
SELECT 
    'After fix verification' as section,
    'stall_applications with null brand_id' as issue,
    COUNT(*) as count
FROM public.stall_applications 
WHERE brand_id IS NULL
UNION ALL
SELECT 
    'After fix verification' as section,
    'orphaned brand_statistics' as issue,
    COUNT(*) as count
FROM public.brand_statistics bs
LEFT JOIN auth.users au ON au.id = bs.brand_id
WHERE au.id IS NULL;

-- 9. Test the trigger by checking if it works now
-- You can test this by inserting a valid stall_application record
-- The trigger should now work without the null brand_id error
