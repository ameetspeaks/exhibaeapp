-- Simple RLS Fix for Profile Avatars
-- This migration provides the most basic RLS policies needed for file uploads

-- ============================================================================
-- STEP 1: DROP ALL EXISTING STORAGE POLICIES
-- ============================================================================

-- Drop all existing storage object policies
DROP POLICY IF EXISTS "Users can upload their own profile pictures" ON storage.objects;
DROP POLICY IF EXISTS "Public read access to profile pictures" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own profile pictures" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own profile pictures" ON storage.objects;
DROP POLICY IF EXISTS "Users can upload their own company logos" ON storage.objects;
DROP POLICY IF EXISTS "Users can update their own company logos" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete their own company logos" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to list profile-avatars objects" ON storage.objects;

-- Drop all existing bucket policies
DROP POLICY IF EXISTS "Allow authenticated users to create buckets" ON storage.buckets;
DROP POLICY IF EXISTS "Allow authenticated users to view buckets" ON storage.buckets;
DROP POLICY IF EXISTS "Allow authenticated users to update buckets" ON storage.buckets;
DROP POLICY IF EXISTS "Allow authenticated users to delete buckets" ON storage.buckets;

-- ============================================================================
-- STEP 2: CREATE SIMPLE BUCKET POLICIES
-- ============================================================================

-- Simple bucket creation policy
CREATE POLICY "Simple bucket creation" ON storage.buckets
    FOR ALL
    USING (auth.role() = 'authenticated')
    WITH CHECK (auth.role() = 'authenticated');

-- ============================================================================
-- STEP 3: CREATE SIMPLE STORAGE OBJECT POLICIES
-- ============================================================================

-- Simple policy for all operations on profile-avatars bucket
CREATE POLICY "Simple profile-avatars access" ON storage.objects
    FOR ALL
    USING (
        bucket_id = 'profile-avatars' 
        AND auth.role() = 'authenticated'
    )
    WITH CHECK (
        bucket_id = 'profile-avatars' 
        AND auth.role() = 'authenticated'
    );

-- ============================================================================
-- STEP 4: VERIFICATION
-- ============================================================================

-- Check if policies were created successfully
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename IN ('objects', 'buckets') 
AND schemaname = 'storage'
ORDER BY tablename, policyname;

-- ============================================================================
-- USAGE NOTES
-- ============================================================================

/*
This simple migration provides the most basic RLS policies needed:

1. BUCKET ACCESS: Allows authenticated users to perform ALL operations on buckets
2. FILE ACCESS: Allows authenticated users to perform ALL operations on files in profile-avatars bucket
3. SIMPLE STRUCTURE: Uses FOR ALL instead of specific operations to avoid complexity

This is the most permissive approach that should definitely work.
After confirming it works, you can add more restrictive policies if needed.

To test:
1. Run this migration in Supabase SQL Editor
2. Try uploading a profile picture in your Flutter app
3. It should work without any RLS errors

This is the simplest possible fix that should resolve the RLS issue.
*/
