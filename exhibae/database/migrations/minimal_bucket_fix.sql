-- Minimal Bucket Creation Fix
-- This migration only adds the essential policies to fix bucket creation RLS issues

-- ============================================================================
-- STEP 1: DROP EXISTING BUCKET POLICIES (if any)
-- ============================================================================

DROP POLICY IF EXISTS "Allow authenticated users to create buckets" ON storage.buckets;
DROP POLICY IF EXISTS "Allow authenticated users to view buckets" ON storage.buckets;
DROP POLICY IF EXISTS "Allow authenticated users to update buckets" ON storage.buckets;
DROP POLICY IF EXISTS "Allow authenticated users to delete buckets" ON storage.buckets;

-- ============================================================================
-- STEP 2: CREATE ESSENTIAL BUCKET POLICIES
-- ============================================================================

-- Allow authenticated users to create buckets
CREATE POLICY "Allow authenticated users to create buckets" ON storage.buckets
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Allow authenticated users to view buckets
CREATE POLICY "Allow authenticated users to view buckets" ON storage.buckets
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- Allow authenticated users to update buckets
CREATE POLICY "Allow authenticated users to update buckets" ON storage.buckets
    FOR UPDATE
    USING (auth.role() = 'authenticated');

-- Allow authenticated users to delete buckets
CREATE POLICY "Allow authenticated users to delete buckets" ON storage.buckets
    FOR DELETE
    USING (auth.role() = 'authenticated');

-- ============================================================================
-- STEP 3: VERIFICATION
-- ============================================================================

-- Check if bucket policies were created successfully
SELECT 
    policyname,
    cmd,
    permissive,
    roles
FROM pg_policies 
WHERE tablename = 'buckets' 
AND schemaname = 'storage'
ORDER BY policyname;

-- ============================================================================
-- USAGE INSTRUCTIONS
-- ============================================================================

/*
This minimal migration fixes the bucket creation RLS issue by:

1. REMOVING CONFLICTS: Drops any existing bucket policies
2. CREATING POLICIES: Adds policies that allow authenticated users to manage buckets
3. VERIFICATION: Includes a query to verify the policies were created

After running this migration:
- The "new row violates row-level security policy" error will be resolved
- Users can create the profile-avatars bucket from the Flutter app
- Bucket creation will work automatically

To apply:
1. Copy this entire SQL script
2. Go to Supabase Dashboard > SQL Editor
3. Paste and run the script
4. Test bucket creation in your Flutter app

Expected result:
- Console should show: "Successfully created profile-avatars bucket"
- No more "Unauthorized" or RLS policy violation errors

This is the minimal fix that should resolve the bucket creation issue.
*/
