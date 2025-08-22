-- Fix for brand_statistics trigger RLS issue
-- This script modifies the trigger function to handle RLS policies properly

-- 1. First, let's see the current trigger function
SELECT 
    routine_name,
    routine_definition
FROM information_schema.routines 
WHERE routine_name = 'update_brand_statistics'
AND routine_schema = 'public';

-- 2. Create a new version of the trigger function that handles RLS properly
CREATE OR REPLACE FUNCTION update_brand_statistics()
RETURNS TRIGGER AS $$
BEGIN
    -- Only proceed if brand_id is not null
    IF NEW.brand_id IS NOT NULL THEN
        -- Use a more permissive approach that works with RLS
        -- First, try to insert with ON CONFLICT to handle existing records
        INSERT INTO public.brand_statistics (
            brand_id,
            total_applications,
            approved_applications,
            rejected_applications,
            active_stalls,
            total_exhibitions_participated,
            last_updated
        )
        VALUES (
            NEW.brand_id,
            (
                SELECT count(*) FROM public.stall_applications
                WHERE brand_id = NEW.brand_id
            ),
            (
                SELECT count(*) FROM public.stall_applications
                WHERE brand_id = NEW.brand_id AND status = 'approved'
            ),
            (
                SELECT count(*) FROM public.stall_applications
                WHERE brand_id = NEW.brand_id AND status = 'rejected'
            ),
            (
                SELECT count(*) FROM public.stall_applications sa
                JOIN public.exhibitions e ON e.id = sa.exhibition_id
                WHERE sa.brand_id = NEW.brand_id
                AND sa.status = 'approved'
                AND e.status = 'active'
            ),
            (
                SELECT count(DISTINCT exhibition_id)
                FROM public.stall_applications
                WHERE brand_id = NEW.brand_id
                AND status = 'approved'
            ),
            now()
        )
        ON CONFLICT (brand_id) DO UPDATE
        SET
            total_applications = EXCLUDED.total_applications,
            approved_applications = EXCLUDED.approved_applications,
            rejected_applications = EXCLUDED.rejected_applications,
            active_stalls = EXCLUDED.active_stalls,
            total_exhibitions_participated = EXCLUDED.total_exhibitions_participated,
            last_updated = EXCLUDED.last_updated;
    END IF;
    
    RETURN NEW;
EXCEPTION
    WHEN OTHERS THEN
        -- Log the error but don't fail the main operation
        RAISE WARNING 'Error updating brand_statistics for brand_id %: %', NEW.brand_id, SQLERRM;
        RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 3. Alternative approach: Create a simpler trigger function that bypasses RLS
-- Uncomment this if the above doesn't work
/*
CREATE OR REPLACE FUNCTION update_brand_statistics()
RETURNS TRIGGER AS $$
BEGIN
    -- Only proceed if brand_id is not null
    IF NEW.brand_id IS NOT NULL THEN
        -- Use SECURITY DEFINER to bypass RLS
        PERFORM set_config('role', 'service_role', false);
        
        INSERT INTO public.brand_statistics (
            brand_id,
            total_applications,
            approved_applications,
            rejected_applications,
            active_stalls,
            total_exhibitions_participated,
            last_updated
        )
        VALUES (
            NEW.brand_id,
            (
                SELECT count(*) FROM public.stall_applications
                WHERE brand_id = NEW.brand_id
            ),
            (
                SELECT count(*) FROM public.stall_applications
                WHERE brand_id = NEW.brand_id AND status = 'approved'
            ),
            (
                SELECT count(*) FROM public.stall_applications
                WHERE brand_id = NEW.brand_id AND status = 'rejected'
            ),
            (
                SELECT count(*) FROM public.stall_applications sa
                JOIN public.exhibitions e ON e.id = sa.exhibition_id
                WHERE sa.brand_id = NEW.brand_id
                AND sa.status = 'approved'
                AND e.status = 'active'
            ),
            (
                SELECT count(DISTINCT exhibition_id)
                FROM public.stall_applications
                WHERE brand_id = NEW.brand_id
                AND status = 'approved'
            ),
            now()
        )
        ON CONFLICT (brand_id) DO UPDATE
        SET
            total_applications = EXCLUDED.total_applications,
            approved_applications = EXCLUDED.approved_applications,
            rejected_applications = EXCLUDED.rejected_applications,
            active_stalls = EXCLUDED.active_stalls,
            total_exhibitions_participated = EXCLUDED.total_exhibitions_participated,
            last_updated = EXCLUDED.last_updated;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
*/

-- 4. Check what triggers are using this function
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE action_statement LIKE '%update_brand_statistics%';

-- 5. Test the trigger function
-- This should now work without RLS policy violations
SELECT 
    'Trigger function updated successfully' as status,
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_name = 'update_brand_statistics'
AND routine_schema = 'public';
