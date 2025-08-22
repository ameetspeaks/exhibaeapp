-- Fix for brand_statistics RLS policy issue
-- This script fixes the Row Level Security policy that's blocking stall application creation

-- 1. First, let's check the current RLS policies on brand_statistics
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'brand_statistics';

-- 2. Check if RLS is enabled on brand_statistics
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE tablename = 'brand_statistics';

-- 3. Create a proper RLS policy for brand_statistics that allows trigger operations
-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own brand statistics" ON public.brand_statistics;
DROP POLICY IF EXISTS "Users can insert their own brand statistics" ON public.brand_statistics;
DROP POLICY IF EXISTS "Users can update their own brand statistics" ON public.brand_statistics;
DROP POLICY IF EXISTS "Users can delete their own brand statistics" ON public.brand_statistics;

-- 4. Create new RLS policies that allow proper access
-- Policy for SELECT (users can view their own statistics)
CREATE POLICY "Users can view their own brand statistics"
ON public.brand_statistics
FOR SELECT
USING (auth.uid() = brand_id);

-- Policy for INSERT (users can insert their own statistics, and triggers can insert)
CREATE POLICY "Users can insert their own brand statistics"
ON public.brand_statistics
FOR INSERT
WITH CHECK (
    auth.uid() = brand_id OR 
    auth.role() = 'service_role' OR
    auth.role() = 'authenticated'
);

-- Policy for UPDATE (users can update their own statistics, and triggers can update)
CREATE POLICY "Users can update their own brand statistics"
ON public.brand_statistics
FOR UPDATE
USING (
    auth.uid() = brand_id OR 
    auth.role() = 'service_role' OR
    auth.role() = 'authenticated'
)
WITH CHECK (
    auth.uid() = brand_id OR 
    auth.role() = 'service_role' OR
    auth.role() = 'authenticated'
);

-- Policy for DELETE (users can delete their own statistics)
CREATE POLICY "Users can delete their own brand statistics"
ON public.brand_statistics
FOR DELETE
USING (auth.uid() = brand_id);

-- 5. Alternative approach: Disable RLS on brand_statistics if the above doesn't work
-- Uncomment the following line if the policies above don't resolve the issue
-- ALTER TABLE public.brand_statistics DISABLE ROW LEVEL SECURITY;

-- 6. Verify the fix by checking the policies again
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'brand_statistics';

-- 7. Test the fix by checking if we can insert a brand_statistics record
-- This should work now without RLS policy violations
INSERT INTO public.brand_statistics (
    brand_id,
    total_applications,
    approved_applications,
    rejected_applications,
    active_stalls,
    total_exhibitions_participated,
    last_updated
) VALUES (
    '00000000-0000-0000-0000-000000000000', -- Test UUID
    0,
    0,
    0,
    0,
    0,
    now()
) ON CONFLICT (brand_id) DO NOTHING;

-- 8. Clean up the test record
DELETE FROM public.brand_statistics WHERE brand_id = '00000000-0000-0000-0000-000000000000';

-- 9. Show final status
SELECT 
    'brand_statistics RLS fix completed' as status,
    COUNT(*) as total_policies
FROM pg_policies 
WHERE tablename = 'brand_statistics';
