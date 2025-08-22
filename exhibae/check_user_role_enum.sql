-- Check the valid enum values for user_role
SELECT 
    t.typname as enum_name,
    e.enumlabel as enum_value
FROM pg_type t 
JOIN pg_enum e ON t.oid = e.enumtypid  
WHERE t.typname = 'user_role'
ORDER BY e.enumsortorder;

-- Also check what roles are currently in use
SELECT 
    role,
    COUNT(*) as count
FROM public.profiles 
WHERE role IS NOT NULL
GROUP BY role
ORDER BY count DESC;
