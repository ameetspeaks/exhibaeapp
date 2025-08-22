-- Comprehensive fix for brand_statistics constraint issue
-- This script adapts to the actual table structure

-- Step 1: Understand the table structure
DO $$
DECLARE
    brand_id_exists BOOLEAN;
    table_exists BOOLEAN;
BEGIN
    -- Check if table exists
    SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_name = 'brand_statistics' 
        AND table_schema = 'public'
    ) INTO table_exists;
    
    IF NOT table_exists THEN
        RAISE NOTICE 'Table brand_statistics does not exist!';
        RETURN;
    END IF;
    
    -- Check if brand_id column exists
    SELECT EXISTS (
        SELECT FROM information_schema.columns 
        WHERE table_name = 'brand_statistics' 
        AND column_name = 'brand_id'
        AND table_schema = 'public'
    ) INTO brand_id_exists;
    
    IF NOT brand_id_exists THEN
        RAISE NOTICE 'Column brand_id does not exist in brand_statistics table!';
        RETURN;
    END IF;
    
    RAISE NOTICE 'Table and brand_id column exist. Proceeding with diagnostics...';
END $$;

-- Step 2: Show table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'brand_statistics' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- Step 3: Check for null brand_id values
SELECT 
    'Records with null brand_id' as check_type,
    COUNT(*) as count
FROM public.brand_statistics 
WHERE brand_id IS NULL;

-- Step 4: Check for orphaned records (brand_id exists but no corresponding profile)
SELECT 
    'Orphaned records' as check_type,
    COUNT(*) as count
FROM public.brand_statistics bs
LEFT JOIN public.profiles p ON p.id = bs.brand_id
WHERE p.id IS NULL;

-- Step 5: Show sample of problematic records
SELECT 
    bs.brand_id,
    p.id as profile_id,
    p.full_name,
    p.role
FROM public.brand_statistics bs
LEFT JOIN public.profiles p ON p.id = bs.brand_id
WHERE p.id IS NULL
LIMIT 5;

-- Step 6: Check foreign key constraints
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc
JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY' 
AND tc.table_name = 'brand_statistics';

-- Step 7: Check triggers
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'brand_statistics';

-- Step 8: Provide cleanup options (commented out for safety)
/*
-- Option A: Clean up orphaned records
DELETE FROM public.brand_statistics 
WHERE brand_id NOT IN (
    SELECT id FROM public.profiles WHERE role = 'brand'
);

-- Option B: Add foreign key constraint (if it doesn't exist)
ALTER TABLE public.brand_statistics 
ADD CONSTRAINT brand_statistics_brand_id_fkey 
FOREIGN KEY (brand_id) 
REFERENCES public.profiles(id) 
ON DELETE CASCADE;

-- Option C: Temporarily allow null values to fix data
ALTER TABLE public.brand_statistics 
ALTER COLUMN brand_id DROP NOT NULL;

-- After fixing data, re-enable the constraint:
-- ALTER TABLE public.brand_statistics 
-- ALTER COLUMN brand_id SET NOT NULL;
*/
