-- Comprehensive check for user_role enum values
-- Run this in your Supabase SQL editor

-- 1. Check if user_role enum exists
SELECT 
    typname as enum_name,
    typtype as type_type
FROM pg_type 
WHERE typname = 'user_role';

-- 2. Get all enum values for user_role
SELECT 
    t.typname as enum_name,
    e.enumlabel as enum_value,
    e.enumsortorder as sort_order
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typname = 'user_role'
ORDER BY e.enumsortorder;

-- 3. Check current profiles with roles
SELECT 
    role,
    COUNT(*) as count
FROM public.profiles 
WHERE role IS NOT NULL
GROUP BY role
ORDER BY count DESC;

-- 4. Check for any CHECK constraints on role column
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

-- 5. Show the exact column definition
SELECT 
    column_name,
    data_type,
    udt_name,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'profiles' 
AND column_name = 'role'
AND table_schema = 'public';
