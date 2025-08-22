-- Basic check for brand_statistics table structure
-- This script will help us understand what columns actually exist

-- 1. First, let's see what columns actually exist in the table
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

-- 3. Show all data in the table (this will show us the actual structure)
SELECT * FROM public.brand_statistics LIMIT 10;

-- 4. Check if brand_id column exists and has any null values
-- This query will work regardless of what other columns exist
SELECT 
    'brand_id_column_exists' as check_type,
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM information_schema.columns 
            WHERE table_name = 'brand_statistics' 
            AND column_name = 'brand_id'
        ) THEN 'YES' 
        ELSE 'NO' 
    END as result;

-- 5. If brand_id exists, check for null values
SELECT 
    'null_brand_id_count' as check_type,
    COUNT(*) as count
FROM public.brand_statistics 
WHERE brand_id IS NULL;
