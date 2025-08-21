-- Disable RLS Test for Profile Avatars
-- This migration temporarily disables RLS to test if that's the issue

-- ============================================================================
-- STEP 1: DISABLE RLS ON STORAGE TABLES
-- ============================================================================

-- Disable RLS on storage.objects table
ALTER TABLE storage.objects DISABLE ROW LEVEL SECURITY;

-- Disable RLS on storage.buckets table
ALTER TABLE storage.buckets DISABLE ROW LEVEL SECURITY;

-- ============================================================================
-- STEP 2: VERIFICATION
-- ============================================================================

-- Check if RLS is disabled
SELECT 
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables 
WHERE schemaname = 'storage' 
AND tablename IN ('objects', 'buckets');

-- ============================================================================
-- USAGE NOTES
-- ============================================================================

/*
This migration temporarily disables RLS on storage tables to test if RLS is the issue.

IMPORTANT: This is for testing only and should NOT be used in production.
It removes all security restrictions on storage access.

To test:
1. Run this migration in Supabase SQL Editor
2. Try uploading a profile picture in your Flutter app
3. If it works, then RLS policies were the issue
4. If it still doesn't work, there's another problem

To re-enable RLS after testing:
1. Run: ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
2. Run: ALTER TABLE storage.buckets ENABLE ROW LEVEL SECURITY;
3. Then apply proper RLS policies

This is a diagnostic tool to identify if RLS is the root cause.
*/
