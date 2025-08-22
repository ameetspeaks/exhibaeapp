-- Check the valid role enum values in the database
-- This will help us understand what roles are allowed

-- Check if there's a role enum type
SELECT 
    t.typname as enum_name,
    e.enumlabel as enum_value
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typname LIKE '%role%'
ORDER BY t.typname, e.enumsortorder;

-- Check the profiles table structure for role column
SELECT 
    column_name,
    data_type,
    udt_name,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND column_name = 'role'
AND table_schema = 'public';

-- Check if there are any existing profiles with roles
SELECT 
    role,
    COUNT(*) as count
FROM public.profiles 
WHERE role IS NOT NULL
GROUP BY role
ORDER BY count DESC;

-- Check for any CHECK constraints on the role column
SELECT 
    tc.constraint_name,
    tc.table_name,
    kcu.column_name,
    cc.check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
    ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.check_constraints cc 
    ON tc.constraint_name = cc.constraint_name
WHERE tc.table_name = 'profiles' 
AND kcu.column_name = 'role'
AND tc.constraint_type = 'CHECK';
