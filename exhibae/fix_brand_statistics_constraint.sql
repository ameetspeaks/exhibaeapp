-- Fix for brand_statistics constraint issue
-- This script helps diagnose and fix the "null value in column brand_id" error

-- 1. First, let's see the structure of the brand_statistics table
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'brand_statistics' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Check if there are any existing records with null brand_id
SELECT 
    brand_id,
    total_applications,
    approved_applications,
    pending_applications,
    created_at,
    updated_at
FROM public.brand_statistics 
WHERE brand_id IS NULL;

-- 3. Check the foreign key constraints on brand_statistics table
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    rc.delete_rule,
    rc.update_rule
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name = 'brand_statistics';

-- 4. Check if there are any triggers that might be causing this issue
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'brand_statistics';

-- 5. Check for any orphaned records in brand_statistics
SELECT 
    bs.brand_id,
    p.id as profile_id,
    p.full_name,
    p.role
FROM public.brand_statistics bs
LEFT JOIN public.profiles p ON p.id = bs.brand_id
WHERE p.id IS NULL;

-- 6. If you want to clean up orphaned brand_statistics records (BE CAREFUL!)
-- Uncomment the following lines only if you want to delete orphaned records:
/*
DELETE FROM public.brand_statistics 
WHERE brand_id NOT IN (
    SELECT id FROM public.profiles WHERE role = 'brand'
);
*/

-- 7. If you want to add a proper foreign key constraint (if it doesn't exist)
-- This will prevent future orphaned records:
/*
ALTER TABLE public.brand_statistics 
ADD CONSTRAINT brand_statistics_brand_id_fkey 
FOREIGN KEY (brand_id) 
REFERENCES public.profiles(id) 
ON DELETE CASCADE;
*/

-- 8. Check if the brand_statistics table has proper indexes
SELECT 
    indexname,
    indexdef
FROM pg_indexes 
WHERE tablename = 'brand_statistics';

-- 9. Show the current RLS policies on brand_statistics
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'brand_statistics';

-- 10. If you need to temporarily disable the constraint to fix data:
/*
-- Temporarily disable the constraint
ALTER TABLE public.brand_statistics 
ALTER COLUMN brand_id DROP NOT NULL;

-- Fix the data (replace with your logic)
-- Then re-enable the constraint
ALTER TABLE public.brand_statistics 
ALTER COLUMN brand_id SET NOT NULL;
*/
