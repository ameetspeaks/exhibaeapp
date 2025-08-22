-- Simple diagnostic script for brand_statistics table
-- This script checks the actual structure and data without assuming column names

-- 1. Check the actual table structure
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'brand_statistics' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Check if the table exists and has any data
SELECT 
    COUNT(*) as total_records
FROM public.brand_statistics;

-- 3. Check for any records with null brand_id (if brand_id column exists)
-- This will show an error if brand_id column doesn't exist, which is useful info
SELECT 
    brand_id,
    COUNT(*) as record_count
FROM public.brand_statistics 
WHERE brand_id IS NULL
GROUP BY brand_id;

-- 4. Check for orphaned records (brand_id exists but no corresponding profile)
SELECT 
    bs.brand_id,
    COUNT(*) as orphaned_records
FROM public.brand_statistics bs
LEFT JOIN public.profiles p ON p.id = bs.brand_id
WHERE p.id IS NULL
GROUP BY bs.brand_id;

-- 5. Show sample data from brand_statistics
SELECT * FROM public.brand_statistics LIMIT 5;

-- 6. Check if there are any foreign key constraints
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

-- 7. Check if there are any triggers on the table
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'brand_statistics';
