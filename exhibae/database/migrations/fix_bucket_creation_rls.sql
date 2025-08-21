-- Fix Bucket Creation RLS Issue
-- This migration specifically addresses the "new row violates row-level security policy" error

-- ============================================================================
-- STEP 1: ENABLE RLS ON STORAGE TABLES
-- ============================================================================

-- Enable RLS on storage.buckets table
ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

-- Enable RLS on storage.objects table
ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 2: DROP EXISTING BUCKET POLICIES
-- ============================================================================

-- Drop any existing bucket policies that might be causing conflicts
DROP POLICY IF EXISTS "Allow authenticated users to create buckets" ON storage.buckets;
DROP POLICY IF EXISTS "Allow authenticated users to view buckets" ON storage.buckets;
DROP POLICY IF EXISTS "Allow authenticated users to update buckets" ON storage.buckets;
DROP POLICY IF EXISTS "Allow authenticated users to delete buckets" ON storage.buckets;
DROP POLICY IF EXISTS "Public buckets are viewable by everyone" ON storage.buckets;
DROP POLICY IF EXISTS "Users can insert buckets" ON storage.buckets;
DROP POLICY IF EXISTS "Users can update buckets" ON storage.buckets;
DROP POLICY IF EXISTS "Users can delete buckets" ON storage.buckets;

-- ============================================================================
-- STEP 3: CREATE BUCKET POLICIES (FIXES THE RLS ISSUE)
-- ============================================================================

-- Policy: Allow authenticated users to create buckets
CREATE POLICY "Allow authenticated users to create buckets" ON storage.buckets
    FOR INSERT
    WITH CHECK (auth.role() = 'authenticated');

-- Policy: Allow authenticated users to view buckets
CREATE POLICY "Allow authenticated users to view buckets" ON storage.buckets
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- Policy: Allow authenticated users to update buckets
CREATE POLICY "Allow authenticated users to update buckets" ON storage.buckets
    FOR UPDATE
    USING (auth.role() = 'authenticated');

-- Policy: Allow authenticated users to delete buckets
CREATE POLICY "Allow authenticated users to delete buckets" ON storage.buckets
    FOR DELETE
    USING (auth.role() = 'authenticated');

-- ============================================================================
-- STEP 4: VERIFICATION
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
This migration fixes the RLS bucket creation issue by:

1. ENABLING RLS: Ensures RLS is enabled on storage.buckets table
2. CLEANING UP: Removes any conflicting policies
3. CREATING POLICIES: Adds policies that allow authenticated users to create buckets
4. VERIFICATION: Includes queries to verify the policies were created

After running this migration:
- The "new row violates row-level security policy" error will be resolved
- Users can create the profile-avatars bucket from the Flutter app
- Bucket creation will work automatically without manual intervention

To apply:
1. Copy this entire SQL script
2. Go to Supabase Dashboard > SQL Editor
3. Paste and run the script
4. Test bucket creation in your Flutter app

Expected result:
- Console should show: "Successfully created profile-avatars bucket"
- No more "Unauthorized" or RLS policy violation errors
*/
